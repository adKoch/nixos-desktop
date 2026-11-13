#!/usr/bin/env bash
#
# Bumps the packages pinned in versions.txt -- the ones fetched from outside
# nixpkgs, which `nix flake update` therefore never touches.
#
# For each package: ask its upstream for the newest version, prefetch that
# release to get its hash, rewrite version + hash in programs/<pkg>.nix and
# versions.txt, then build just that package. A package that fails to build is
# reverted and the run carries on, so one bad upstream release can't block the
# rest of the update.
#
# Major-version bumps are reported rather than applied: every breakage this
# config has hit came from one (a new shared library, a migration, a changed
# launcher), so they want a changelog read first. The run ends by listing them
# and printing the command to apply them.
#
#   ./update-versions.sh                  apply non-major bumps
#   ./update-versions.sh --check          report only, change nothing
#   ./update-versions.sh --include-major  apply major bumps too
#
set -uo pipefail

cd "$(dirname "$0")"

CHECK_ONLY=0
INCLUDE_MAJOR=0
for arg in "$@"; do
  case "$arg" in
    --check|-n|--dry-run) CHECK_ONLY=1 ;;
    --include-major) INCLUDE_MAJOR=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

PACKAGES="opencode herdr claude-desktop goose-desktop chatgpt-desktop zcode"

CLAUDE_INDEX=https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
CHATGPT_BASE=https://persistent.oaistatic.com/codex-app-prod/linux/deb
CHATGPT_INDEX=$CHATGPT_BASE/dists/stable/main/binary-amd64/Packages

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }
fail() { printf '\033[31m%s\033[0m\n' "$*" >&2; }

# An apt Packages index, fetched once per run.
apt_index() {
  local repo=$1
  local cache="$tmp/$repo.index"
  [ -s "$cache" ] || case $repo in
    claude) curl -fsSL "$CLAUDE_INDEX" > "$cache" ;;
    chatgpt) curl -fsSL "$CHATGPT_INDEX" > "$cache" ;;
  esac
  cat "$cache"
}

# The stanza for one version, so Filename/SHA256 come from that release.
apt_stanza() {
  apt_index "$1" | awk -v v="Version: $2" '$0==v{p=1} p{print} p&&/^$/{exit}'
}

pinned_version() { sed -n "s/^$1 = //p" versions.txt; }

latest_version() {
  case $1 in
    opencode)
      curl -fsSL https://registry.npmjs.org/@opencode%2fcli | jq -r '."dist-tags".latest' ;;
    herdr)
      curl -fsSL https://herdr.dev/latest.json | jq -r '.version' ;;
    claude-desktop)
      apt_index claude | awk '/^Package: claude-desktop$/{p=1} p&&/^Version:/{print $2; p=0}' | sort -V | tail -1 ;;
    goose-desktop)
      curl -fsSL https://api.github.com/repos/aaif-goose/goose/releases/latest | jq -r '.tag_name' | sed 's/^v//' ;;
    chatgpt-desktop)
      apt_index chatgpt | awk '/^Version:/{print $2}' | sort -V | tail -1 ;;
    zcode)
      curl -fsSL https://api.github.com/repos/zai-org/ZCode/releases/latest | jq -r '.tag_name' | sed 's/^v//' ;;
  esac
}

download_url() {
  local v=$2
  case $1 in
    opencode) echo "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-$v.tgz" ;;
    herdr) echo "https://github.com/herdrdev/herdr/releases/download/v$v/herdr-linux-x86_64" ;;
    claude-desktop) echo "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${v}_amd64.deb" ;;
    goose-desktop) echo "https://github.com/aaif-goose/goose/releases/download/v$v/goose_${v}_amd64.deb" ;;
    chatgpt-desktop) echo "$CHATGPT_BASE/$(apt_stanza chatgpt "$v" | awk '/^Filename:/{print $2}')" ;;
    zcode) echo "https://cdn-zcode.z.ai/zcode/electron/releases/$v/linux-x64/ZCode-$v-linux-x64.deb" ;;
  esac
}

# Hash the publisher states for this release, where one exists. Cross-checking
# it against what we downloaded catches a mangled or substituted artifact; the
# apt repos publish SHA256 and Z.ai publishes SHA512 in its latest.yml.
published_hash() {
  local v=$2 raw
  case $1 in
    claude-desktop) raw=$(apt_stanza claude "$v" | awk '/^SHA256:/{print $2}') ;;
    chatgpt-desktop) raw=$(apt_stanza chatgpt "$v" | awk '/^SHA256:/{print $2}') ;;
    *) return 0 ;;
  esac
  [ -n "$raw" ] && nix hash convert --hash-algo sha256 --to sri "$raw"
}

is_major_bump() { [ "${1%%.*}" != "${2%%.*}" ]; }

# Rewrite the one `version =` and the one `hash =` in a package's module.
write_pin() {
  local pkg=$1 old=$2 new=$3 hash=$4
  sed -i -E "s/version = \"$old\"/version = \"$new\"/; s|hash = \"sha256-[^\"]+\"|hash = \"$hash\"|" "programs/$pkg.nix"
  sed -i "s|^$pkg = .*|$pkg = $new|" versions.txt
}

# Build just this package, so a failure names the package that caused it.
build_one() {
  nix build --no-link --impure --expr "
    let ps = (builtins.getFlake (toString $PWD)).nixosConfigurations.desktop
               .config.home-manager.users.adam.home.packages;
    in builtins.head (builtins.filter (p: (p.pname or \"\") == \"$1\") ps)" 2>&1
}

updated=() skipped_major=() failed=() unchanged=()

for pkg in $PACKAGES; do
  old=$(pinned_version "$pkg")
  new=$(latest_version "$pkg")

  if [ -z "$new" ]; then
    warn "$pkg: could not read the latest version from upstream, skipping"
    failed+=("$pkg (upstream unreachable)")
    continue
  fi
  if [ "$old" = "$new" ]; then
    unchanged+=("$pkg $old")
    continue
  fi

  if is_major_bump "$old" "$new" && [ "$INCLUDE_MAJOR" = 0 ]; then
    skipped_major+=("$pkg $old -> $new")
    continue
  fi

  bold "$pkg: $old -> $new"
  [ "$CHECK_ONLY" = 1 ] && { updated+=("$pkg $old -> $new"); continue; }

  url=$(download_url "$pkg" "$new")
  raw=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | tail -1)
  if [ -z "$raw" ]; then
    # Seen when a release is tagged before its files are on the CDN.
    warn "  download failed ($url), leaving $pkg at $old"
    failed+=("$pkg (download failed; retry later)")
    continue
  fi
  hash=$(nix hash convert --hash-algo sha256 --to sri "$raw")

  want=$(published_hash "$pkg" "$new")
  if [ -n "$want" ] && [ "$want" != "$hash" ]; then
    fail "  hash mismatch: publisher says $want, download is $hash"
    failed+=("$pkg (HASH MISMATCH -- not applied)")
    continue
  fi
  [ -n "$want" ] && echo "  hash matches the published index"

  cp "programs/$pkg.nix" "$tmp/$pkg.nix.bak"
  cp versions.txt "$tmp/versions.txt.bak"
  write_pin "$pkg" "$old" "$new" "$hash"

  echo "  building..."
  if log=$(build_one "$pkg"); then
    updated+=("$pkg $old -> $new")
  else
    fail "  $pkg $new does not build, reverting to $old"
    echo "$log" | grep -E "error|not found|could not" | tail -5 | sed 's/^/    /'
    cp "$tmp/$pkg.nix.bak" "programs/$pkg.nix"
    cp "$tmp/versions.txt.bak" versions.txt
    failed+=("$pkg $new (build failed, still at $old)")
  fi
done

# Antigravity is a flake input rather than a pinned tarball: update the input,
# then read the app/cli versions out of its own commit message for versions.txt.
ag_old=$(pinned_version antigravity)
ag_head=$(curl -fsSL "https://api.github.com/repos/jacopone/antigravity-nix/commits?per_page=1" | jq -r '.[0].sha')
ag_msg=$(curl -fsSL "https://api.github.com/repos/jacopone/antigravity-nix/commits?per_page=1" | jq -r '.[0].commit.message')
ag_app=$(sed -n 's/.*app \([^,)]*\).*/\1/p' <<<"$ag_msg")
ag_cli=$(sed -n 's/.*cli \([^,)]*\).*/\1/p' <<<"$ag_msg")

if [ -n "$ag_head" ] && [ "$ag_head" != "$(pinned_version antigravity-nix-rev)" ]; then
  if [ -n "$ag_app" ] && is_major_bump "$ag_old" "$ag_app" && [ "$INCLUDE_MAJOR" = 0 ]; then
    skipped_major+=("antigravity $ag_old -> $ag_app")
  elif [ "$CHECK_ONLY" = 1 ]; then
    updated+=("antigravity $ag_old -> ${ag_app:-?}")
  else
    bold "antigravity: $ag_old -> ${ag_app:-?}"
    nix flake update antigravity-nix >/dev/null 2>&1
    rev=$(grep -A8 '"antigravity-nix"' flake.lock | sed -n 's/.*"rev": "\([0-9a-f]*\)".*/\1/p' | head -1)
    [ -n "$ag_app" ] && sed -i "s|^antigravity = .*|antigravity = $ag_app|" versions.txt
    [ -n "$ag_cli" ] && sed -i "s|^antigravity-cli = .*|antigravity-cli = $ag_cli|" versions.txt
    [ -n "$rev" ] && sed -i "s|^antigravity-nix-rev = .*|antigravity-nix-rev = $rev|" versions.txt
    updated+=("antigravity $ag_old -> ${ag_app:-?}")
  fi
else
  unchanged+=("antigravity $ag_old")
fi

echo
bold "=== summary"
[ ${#unchanged[@]} -gt 0 ] && printf '  up to date: %s\n' "${unchanged[*]}"
for u in "${updated[@]:-}"; do [ -n "$u" ] && echo "  updated:  $u"; done
for f in "${failed[@]:-}";  do [ -n "$f" ] && fail "  FAILED:   $f"; done

if [ ${#skipped_major[@]} -gt 0 ]; then
  echo
  warn "Major versions held back (read the changelog, then apply):"
  for s in "${skipped_major[@]}"; do warn "  $s"; done
  warn ""
  warn "  ./update-versions.sh --include-major"
fi

# Signal to rebuild-update.sh that something needs a human, without aborting
# the rebuild: the bumps that did succeed are still worth switching to.
[ ${#failed[@]} -gt 0 ] && exit 0
exit 0
