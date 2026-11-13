{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "herdr";
      version = "0.9.1";

      # Statically linked release binary, so no patchelf is needed.
      src = pkgs.fetchurl {
        url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
        hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
      };

      dontUnpack = true;

      installPhase = ''
        install -m755 -D $src $out/bin/herdr
      '';

      meta = with pkgs.lib; {
        description = "Persistent terminal runtime for coding agents";
        homepage = "https://herdr.dev";
        license = licenses.asl20;
        platforms = ["x86_64-linux"];
        mainProgram = "herdr";
      };
    })
  ];
}
