{ pkgs, ... }: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "jules";
      version = "0.1.42";

      src = pkgs.fetchurl {
        url = "https://storage.googleapis.com/jules-cli/v${version}/jules_external_v${version}_linux_amd64.tar.gz";
        hash = "sha256-c869LI+Jubsk703MuM15Q8y2npmzfeJnwvV5Mjen0QM=";
      };

      sourceRoot = ".";

      installPhase = ''
        install -m755 -D jules $out/bin/jules
      '';

      meta = with pkgs.lib; {
        description = "CLI for Jules, the asynchronous coding agent from Google";
        homepage = "https://jules.google";
        license = licenses.unfree;
        platforms = platforms.linux;
      };
    })
  ];
}
