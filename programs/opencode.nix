{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "opencode";
      version = "1.18.31";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${version}.tgz";
        hash = "sha256-bYnaJSqLAw2SPnKDltw0Rlz2CVEBt4IisO4ze2gUDeo=";
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

}
