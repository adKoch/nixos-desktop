{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./programs/editor.nix
  ];

  home.packages = with pkgs; [
    # KDE tools
    kdePackages.kate
    
    # Communication & Media
    discord
    spotify
    protonvpn-gui
    
    # Development
    git
    github-cli
    go-task
    code-cursor
    alejandra
    claude-code
    
    # Containers
    podman
    podman-compose
    buildah
    
    # Utilities
    appimage-run
  ];
}
