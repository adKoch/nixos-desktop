{ pkgs, lib, ... }: let
  # OpenAI's official ChatGPT desktop app for Linux (preview), which is also
  # the Codex desktop app. It bundles its own codex binary, so it doesn't use
  # the nixpkgs `codex` CLI from home.nix.
  #
  # Updating: look up the newest version in the repository index at
  #   https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages
  # then bump version + hash here and in versions.txt. The docs only link a
  # moving `latest/` .deb; this pool URL is what the package's own postinst
  # registers as its apt source, and it keeps every release addressable.
  chatgpt-desktop = pkgs.stdenv.mkDerivation rec {
    pname = "chatgpt-desktop";
    version = "26.1111.21308";

    src = pkgs.fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
      # Matches the SHA256 published in the repository's Packages index.
      hash = "sha256-S0Q7xVc1ChsZO8LxuuIHyeo8n7XZT3yUpdPbqotVI1I=";
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
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libGL
      libnotify
      libusb1
      libxkbcommon
      mesa # libgbm
      nspr
      nss
      openssl
      pango
      stdenv.cc.cc.lib
      systemd # libudev
      tpm2-tss
      vulkan-loader
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
    ];

    # Chromium's optional Qt file-dialog shims; it falls back to GTK without them.
    autoPatchelfIgnoreMissingDeps = [ "libQt5*" "libQt6*" ];

    unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp -r usr/lib/chatgpt $out/lib/chatgpt

      # Native node modules ship musl prebuilds beside the glibc ones; only
      # the glibc builds load here, and the musl ones can't be patched.
      find $out/lib/chatgpt/resources -path '*musl*' -name '*.node' -delete

      # Chromium/ANGLE dlopen()s libGL.so.1 and libvulkan by bare soname,
      # which ignores rpath, so the GL libraries go on LD_LIBRARY_PATH.
      # --password-store=basic: no secret service runs under XFCE here (see
      # claude-desktop.nix), so Chromium's libsecret backend has nothing to use.
      makeWrapper $out/lib/chatgpt/ChatGPT $out/bin/chatgpt \
        --add-flags "--password-store=basic" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils pkgs.git ]}" \
        --prefix LD_LIBRARY_PATH : "$out/lib/chatgpt:${lib.makeLibraryPath [ pkgs.libGL pkgs.mesa pkgs.vulkan-loader ]}"

      # The upstream entry also claims http/https, which would let it take
      # over as the default browser; keep only codex:// and document types.
      install -Dm644 usr/share/applications/chatgpt.desktop \
        $out/share/applications/chatgpt.desktop
      substituteInPlace $out/share/applications/chatgpt.desktop \
        --replace-fail "x-scheme-handler/http;x-scheme-handler/https;" ""
      install -Dm644 usr/share/pixmaps/chatgpt.png $out/share/pixmaps/chatgpt.png

      runHook postInstall
    '';

    meta = with lib; {
      description = "ChatGPT and Codex desktop application (official Linux preview)";
      homepage = "https://developers.openai.com/codex/app";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "chatgpt";
    };
  };
in {
  home.packages = [ chatgpt-desktop ];
}
