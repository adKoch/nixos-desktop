{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  pkgs-unstable,
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

  home.packages = (with pkgs; [
    # Text Editor
    xed-editor

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
    forgejo
    podman-desktop
    podman-compose

    # 3D Printing
    bambu-studio

    # Office Suite
    libreoffice
    gimp

    # Utilities
    appimage-run
    obsidian
    anki
  ]) ++ (with pkgs-unstable; [
    claude-code
    opencode
  ]);
}
