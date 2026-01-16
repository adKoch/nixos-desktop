{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./programs/terminal.nix
    ./programs/vscode.nix
  ];

  home.packages = (with pkgs; [
    git
    alejandra
  ]) ++ (with pkgs-unstable; [
    podman
    podman-compose
    buildah
  ]);
}
