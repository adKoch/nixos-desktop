{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  firefox-addons-allowUnfree,
  ...
}: {
  imports = [
    ./programs/editor.nix
  ];

  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = {
        packages = with firefox-addons-allowUnfree; [
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

  programs.bash.shellAliases = {
    agi = "antigravity . > /dev/null 2>&1 &";
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
    code-cursor
    alejandra
    claude-code
    forgejo

    # Containers
    podman
    podman-compose
    buildah

    # Utilities
    appimage-run
    obsidian
  ];
}
