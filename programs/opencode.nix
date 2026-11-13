{
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "opencode";
      version = "2.3.0";

      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
        hash = "sha256-QI+FS1+seFejtN9OeD06i3D1zIx8MYeqwJxb4FdsFK4=";
      };

      # A Bun single-file executable: the app is a payload appended to the
      # ELF, and autoPatchelf's RPATH rewrite corrupts it, leaving a bare
      # `bun` that ignores opencode's CLI. It needs only glibc, so set the
      # interpreter and keep fixup from touching the file.
      nativeBuildInputs = [pkgs.patchelf];
      dontStrip = true;
      dontPatchELF = true;

      sourceRoot = ".";

      installPhase = ''
        install -m755 -D package/bin/opencode $out/bin/opencode
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/opencode
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
