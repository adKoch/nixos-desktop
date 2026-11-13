{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "herdr";
      version = "0.9.5";

      # Statically linked release binary, so no patchelf is needed.
      src = pkgs.fetchurl {
        url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
        hash = "sha256-FNnovItKngEY13wyJm921GHwm0A0LrI3UpYL2J9Zkp0=";
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

  # herdr is a TUI and ships no desktop file; this launcher opens it in the
  # default terminal and files it under Development with the other agents.
  xdg.desktopEntries.herdr = {
    name = "Herdr";
    genericName = "Agent Runtime";
    comment = "Launch Herdr in a terminal";
    exec = "herdr";
    icon = "utilities-terminal";
    terminal = true;
    type = "Application";
    categories = [ "Development" ];
  };
}
