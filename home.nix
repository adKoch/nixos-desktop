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

  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = {
        packages = with inputs.firefox-addons.packages.${pkgs.system}; [
          bitwarden
          ublock-origin
          return-youtube-dislikes
          youtube-shorts-block
          betterttv
          instapaper-official
        ];
      };

      settings = {
        "browser.startup.homepage" = "https://claude.ai";
        "privacy.resistFingerprinting" = true;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
      };
    };
  };


  home.packages = with pkgs; [
    # KDE tools
    kdePackages.kate
    
    # Communication & Media
    discord
    spotify
    stremio
    spicetify-cli
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
    obsidian
  ];
}
