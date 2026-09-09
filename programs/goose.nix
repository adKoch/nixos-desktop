{ pkgs, lib, ... }: let
  # Seed the goose config once, then let the app own it. Managing it as a
  # read-only nix-store symlink (home.file) stopped the desktop app from
  # persisting any changes — provider picks, extensions, the telemetry answer.
  gooseConfigTemplate = pkgs.writeText "goose-config.yaml" ''
    GOOSE_PROVIDER: tinfoil
    GOOSE_MODEL: gemma4-31b
    GOOSE_TELEMETRY_ENABLED: false
  '';

  seedGooseConfig = pkgs.writeShellScript "seed-goose-config" ''
    set -euo pipefail
    config_dir="$HOME/.config/goose"
    config_file="$config_dir/config.yaml"
    mkdir -p "$config_dir"
    # Drop a leftover read-only symlink from a previous generation so we can
    # own a real, writable file in its place.
    if [ -L "$config_file" ]; then
      rm -f "$config_file"
    fi
    # Seed defaults only when absent; afterwards the app's edits persist.
    if [ ! -e "$config_file" ]; then
      cp ${gooseConfigTemplate} "$config_file"
      chmod 644 "$config_file"
    fi
  '';

  goose-desktop = pkgs.stdenv.mkDerivation rec {
    pname = "goose-desktop";
    version = "1.50.0";

    src = pkgs.fetchurl {
      url = "https://github.com/aaif-goose/goose/releases/download/v${version}/goose_${version}_amd64.deb";
      hash = "sha256-U6BCmHOMeOMYNSTt1ikXmDOatQRKSCW4LIh/5uT1sdk=";
    };

    nativeBuildInputs = [
      pkgs.dpkg
      pkgs.autoPatchelfHook
      pkgs.makeWrapper
    ];

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
      libGL
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
    ];

    unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

    installPhase = ''
      mkdir -p $out/bin $out/lib $out/share/applications $out/share/pixmaps

      cp -r usr/lib/goose $out/lib/goose

      # Bundled libffmpeg.so must be findable at runtime, and Chromium/ANGLE
      # dlopen()s libGL.so.1 by bare soname — that ignores rpath, so the GL
      # libraries must be on LD_LIBRARY_PATH explicitly.
      # The desktop app is launched from the menu, so it never sees the shell
      # alias's env. Bake in the same vars the CLI alias sets, or chat breaks on
      # the provider at the first prompt.
      makeWrapper $out/lib/goose/Goose $out/bin/goose-desktop \
        --add-flags "--no-sandbox" \
        --set GOOSE_TINFOIL_API_KEY local \
        --set GOOSE_DISABLE_KEYRING true \
        --prefix LD_LIBRARY_PATH : "$out/lib/goose:${lib.makeLibraryPath [ pkgs.libGL pkgs.mesa ]}"

      install -Dm644 usr/share/applications/goose.desktop $out/share/applications/goose.desktop
      install -Dm644 usr/share/pixmaps/goose.png $out/share/pixmaps/goose.png

      substituteInPlace $out/share/applications/goose.desktop \
        --replace "Exec=/usr/lib/goose/Goose %U" "Exec=$out/bin/goose-desktop %U"
    '';

    meta = with pkgs.lib; {
      description = "Goose AI agent desktop application";
      homepage = "https://github.com/block/goose";
      license = licenses.asl20;
      platforms = [ "x86_64-linux" ];
      mainProgram = "goose-desktop";
    };
  };
in {
  home.packages = [ pkgs.goose-cli goose-desktop ];

  home.shellAliases.goose = "GOOSE_TINFOIL_API_KEY=local GOOSE_DISABLE_KEYRING=true goose";

  # Seed the writable config.yaml (defaults + telemetry off) on first run.
  home.activation.goose-config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${seedGooseConfig}
  '';

  # Tinfoil as a declarative custom provider.
  home.file.".config/goose/custom_providers/tinfoil.json".text = builtins.toJSON {
    name = "tinfoil";
    engine = "openai";
    display_name = "Tinfoil";
    description = "Privacy-preserving inference via Tinfoil secure enclaves";
    api_key_env = "GOOSE_TINFOIL_API_KEY";
    base_url = "http://127.0.0.1:3301";
    models = [
      {
        name = "gemma4-31b";
        context_limit = 256000;
      }
    ];
  };
}
