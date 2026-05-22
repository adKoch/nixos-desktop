{
  pkgs,
  config,
  ...
}: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "opencode";
      version = "1.14.48";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${version}.tgz";
        hash = "sha256-t+6pdWjV9i/3PuD6SHpMx3MDk6W4c+/og4+fsplTJ84=";
      };

      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = with pkgs; [
        stdenv.cc.cc
        zlib
      ];

      sourceRoot = ".";

      installPhase = ''
        install -m755 -D package/bin/opencode $out/bin/opencode
      '';

      meta = with pkgs.lib; {
        description = "Open-source, model-agnostic AI coding assistant";
        homepage = "https://opencode.ai";
        license = licenses.unfree;
        platforms = platforms.linux;
      };
    })
  ];

  home.file.".config/opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink
    "/home/adam/nixos-desktop/opencode/opencode.json";
}
