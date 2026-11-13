{ pkgs, lib, ... }: let
  # Anthropic's official Linux build (beta), from their apt repository. This
  # replaces k3d3/claude-desktop-linux-flake, which repackaged the Windows
  # installer: that source is frozen at 0.14.10 and too old for Cowork and the
  # Claude Code session switch.
  #
  # Updating: look up the newest version in the repository index at
  #   https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
  # then bump version + hash here and in versions.txt. The app cannot update
  # itself on Linux, and we deliberately don't register the apt repo.
  claude-desktop = pkgs.stdenv.mkDerivation rec {
    pname = "claude-desktop";
    version = "5.11492.2";

    src = pkgs.fetchurl {
      url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
      # Matches the SHA256 published in the repository's Packages index.
      hash = "sha256-0QlE+lZjuZdADPZsXHc4/WrPZU+KrqyluZTrFHqms18=";
    };

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

    # Mirrors the .deb's Depends, plus the usual Electron/Chromium set.
    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libcap_ng # virtiofsd, the Cowork VM helper's filesystem daemon
      libdrm
      libGL
      libnotify
      libseccomp # virtiofsd
      libsecret
      libuuid
      libxkbcommon
      mesa
      nspr
      nss
      pango
      pipewire # claude-native-binding.node (since 2.37337)
      systemd
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxtst
      libxcb
    ];

    unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp -r usr/lib/claude-desktop $out/lib/claude-desktop

      # The SUID sandbox helper can't be setuid in the nix store, so it would
      # abort at startup; drop it and disable the sandbox in the wrapper.
      rm -f $out/lib/claude-desktop/chrome-sandbox

      # Bundled libffmpeg.so must be findable at runtime, and Chromium/ANGLE
      # dlopen()s libGL.so.1 by bare soname -- that ignores rpath, so the GL
      # libraries have to be on LD_LIBRARY_PATH explicitly.
      #
      # --password-store=basic: nothing here provides a secret service (XFCE
      # starts none, and autologin would leave a gnome-keyring locked because
      # PAM never sees a password), so Chromium's default libsecret backend
      # has nothing to talk to. Tokens land obfuscated in the app's config dir.
      makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
        --add-flags "--no-sandbox" \
        --add-flags "--password-store=basic" \
        --prefix LD_LIBRARY_PATH : "$out/lib/claude-desktop:${lib.makeLibraryPath [ pkgs.libGL pkgs.mesa ]}"

      install -Dm644 usr/share/applications/com.anthropic.Claude.desktop \
        $out/share/applications/com.anthropic.Claude.desktop

      for icon in usr/share/icons/hicolor/*/apps/claude-desktop.png; do
        size=$(basename $(dirname $(dirname "$icon")))
        install -Dm644 "$icon" \
          $out/share/icons/hicolor/$size/apps/claude-desktop.png
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "Claude desktop application (official Linux beta)";
      homepage = "https://claude.com/download";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "claude-desktop";
    };
  };
  # Since the app can't update itself here, poll the apt index and raise a
  # desktop notification when a release newer than the pinned one appears.
  # The last announced version is remembered so each release notifies once.
  checkUpdate = pkgs.writeShellApplication {
    name = "claude-desktop-check-update";
    runtimeInputs = with pkgs; [ curl gawk coreutils libnotify ];
    text = ''
      index="https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages"
      pinned="${claude-desktop.version}"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/claude-desktop-last-notified"

      latest=$(curl -fsSL "$index" \
        | awk '/^Package: claude-desktop$/{p=1} p&&/^Version:/{print $2} /^$/{p=0}' \
        | sort -V | tail -1)
      [ -n "$latest" ] || { echo "could not read $index" >&2; exit 1; }

      echo "pinned $pinned, latest $latest"
      [ "$latest" != "$pinned" ] || exit 0
      [ "$(printf '%s\n%s\n' "$pinned" "$latest" | sort -V | tail -1)" = "$latest" ] || exit 0
      [ "$(cat "$state" 2>/dev/null)" != "$latest" ] || exit 0

      notify-send -a "Claude Desktop" -i claude-desktop -u normal \
        "Claude Desktop $latest available" \
        "Pinned: $pinned. Bump programs/claude-desktop.nix and versions.txt."
      mkdir -p "$(dirname "$state")"
      echo "$latest" > "$state"
    '';
  };
in {
  home.packages = [ claude-desktop checkUpdate ];

  systemd.user.services.claude-desktop-check-update = {
    Unit.Description = "Check for a newer Claude Desktop release";
    Service = {
      Type = "oneshot";
      ExecStart = lib.getExe checkUpdate;
    };
  };

  systemd.user.timers.claude-desktop-check-update = {
    Unit.Description = "Periodically check for a newer Claude Desktop release";
    Timer = {
      OnStartupSec = "5min";
      OnUnitActiveSec = "3h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
