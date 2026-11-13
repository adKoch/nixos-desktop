{ pkgs, lib, ... }: let
  # Z.ai's ZCode coding-agent desktop app, from the official Linux build.
  # GitHub releases (zai-org/ZCode) carry only macOS/Windows assets; Linux
  # packages live on Z.ai's CDN under a per-version path, each with a
  # `latest.yml` listing SHA-512s. There is no unversioned "latest" pointer,
  # so the GitHub release tag is the place to check for new versions.
  #
  # Updating: take the newest tag from
  #   https://github.com/zai-org/ZCode/releases
  # then bump version + hash here and in versions.txt.
  zcode = pkgs.stdenv.mkDerivation rec {
    pname = "zcode";
    version = "3.17.2";

    src = pkgs.fetchurl {
      url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.deb";
      # Matches the SHA-512 in that release's latest.yml.
      hash = "sha256-hux7KnlcRq5W5zE1BDAKM3wzxoJnwo+WoDcmpPWv9XU=";
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
      libdrm
      libGL
      libnotify
      libsecret
      libuuid
      libxkbcommon
      mesa # libgbm
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      systemd
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxscrnsaver
      libxtst
    ];

    unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp -r opt/ZCode $out/lib/zcode

      # The SUID sandbox helper can't be setuid in the nix store, so it would
      # abort at startup; drop it and disable the sandbox in the wrapper.
      rm -f $out/lib/zcode/chrome-sandbox

      # Bundled libffmpeg.so must be findable at runtime, and Chromium/ANGLE
      # dlopen()s libGL.so.1 by bare soname, which ignores rpath.
      # --password-store=basic: see claude-desktop.nix.
      makeWrapper $out/lib/zcode/zcode $out/bin/zcode \
        --add-flags "--no-sandbox" \
        --add-flags "--password-store=basic" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}" \
        --prefix LD_LIBRARY_PATH : "$out/lib/zcode:${lib.makeLibraryPath [ pkgs.libGL pkgs.mesa ]}"

      install -Dm644 usr/share/applications/zcode.desktop \
        $out/share/applications/zcode.desktop
      substituteInPlace $out/share/applications/zcode.desktop \
        --replace-fail "Exec=/opt/ZCode/zcode" "Exec=zcode"

      for icon in usr/share/icons/hicolor/*/apps/zcode.png; do
        size=$(basename $(dirname $(dirname "$icon")))
        install -Dm644 "$icon" $out/share/icons/hicolor/$size/apps/zcode.png
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "ZCode, Z.ai's coding agent desktop app (official Linux build)";
      homepage = "https://zcode.z.ai";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
      mainProgram = "zcode";
    };
  };
in {
  home.packages = [ zcode ];
}
