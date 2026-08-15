{ inputs, pkgs, ... }: let
  upstream = inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system};

  # Claude Desktop 0.14.10 wants a native AuthRequest API for the in-app
  # ASWebAuth login. patchy-cnb (upstream's Rust stand-in for the proprietary
  # claude-native bindings) only exports KeyboardKey, so the guard
  #
  #     if (a && a.AuthRequest.isAvailable() && t && fae(i)) { native } else { browser }
  #
  # throws on the undefined AuthRequest -- the module loads, so `a` is truthy,
  # and neither branch ever runs. Login hangs. Upstream is pinned at its HEAD
  # (b2b040c) and has no fix.
  #
  # Force the guard false so the else branch runs and auth happens in the
  # system browser, which comes back via the registered claude:// handler.
  # The replacement is padded to the exact byte length of the original: the
  # asar header stores file offsets, so changing the size would corrupt it.
  claude-desktop = upstream.claude-desktop.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.perl ];

    postInstall = (old.postInstall or "") + ''
      asar="$out/lib/claude-desktop/app.asar"
      before=$(stat -c%s "$asar")

      hits=$(grep -aoc 'a\.AuthRequest\.isAvailable()' "$asar" || true)
      if [ "$hits" != "1" ]; then
        echo "expected exactly 1 AuthRequest guard, found $hits -- upstream app changed" >&2
        exit 1
      fi

      perl -0777 -pi -e \
        's/\Qa.AuthRequest.isAvailable()\E/"!1" . " " x 25/e' "$asar"

      after=$(stat -c%s "$asar")
      if [ "$before" != "$after" ]; then
        echo "asar size changed ($before -> $after); offsets would be corrupt" >&2
        exit 1
      fi
    '';
  });

  # Mirrors upstream's claude-desktop-with-fhs, rebuilt here so it wraps the
  # patched package. FHS so MCP servers that shell out to node/npx work.
  #
  # --password-store=basic: nothing on this box provides a secret service
  # (XFCE starts none, and autologin would leave a gnome-keyring locked since
  # PAM never sees a password), so Chromium's default libsecret backend has
  # nothing to talk to. Tokens land obfuscated in the app's config dir.
  claude-desktop-with-fhs = pkgs.buildFHSEnv {
    name = "claude-desktop";
    # Upstream lists docker here, but it's dropped: this host runs podman with
    # dockerCompat, so `docker` is already a podman shim, and nixpkgs'
    # docker-28.5.2 is marked insecure in our pinned nixpkgs. Add it back (with
    # permittedInsecurePackages) only if a docker-based MCP server needs it.
    targetPkgs = pkgs:
      with pkgs; [
        glibc
        openssl
        nodejs
        uv
      ];
    runScript = "${claude-desktop}/bin/claude-desktop --password-store=basic";
    extraInstallCommands = ''
      mkdir -p $out/share/applications
      cp ${claude-desktop}/share/applications/claude.desktop $out/share/applications/

      mkdir -p $out/share/icons
      cp -r ${claude-desktop}/share/icons/* $out/share/icons/
    '';
  };
in {
  home.packages = [ claude-desktop-with-fhs ];
}
