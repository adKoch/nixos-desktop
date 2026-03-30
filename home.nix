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
    ./programs/claude-code.nix
    ./programs/virtual-context.nix
  ];

  # Enable bash in home-manager to auto-source session variables
  programs.bash.enable = true;

  home.shellAliases = {
    nd = "nix develop";
  };

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
        "browser.startup.homepage" = "https://adkoch.github.io/browser-startup-page/?config=office";
        "privacy.resistFingerprinting" = true;
        "extensions.autoDisableScopes" = 0;
        "extensions.enabledScopes" = 15;
      };
    };
  };

  home.packages = (with pkgs; [
    # Text Editor
    xed-editor

    # Browser
    google-chrome

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

    # Work
    hubstaff

    # Utilities
    appimage-run
    obsidian
    anki
    bitwarden
    bitwarden-cli
    sox
  ]) ++ (with pkgs-unstable; [
    claude-code
  ]);

  programs.git = {
    enable = true;
    ignores = [ ".virtualcontext/" ];
  };

  services.ssh-agent.enable = true;
  services.gpg-agent.enableSshSupport = false;

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
  };

  systemd.user.services.ssh-add-keys = {
    Unit = {
      Description = "Add SSH keys to agent";
      After = [ "ssh-agent.service" ];
      Requires = [ "ssh-agent.service" ];
    };
    Service = {
      Type = "oneshot";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent";
      ExecStart = "${pkgs.openssh}/bin/ssh-add";
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Disable XFCE panel
  xfconf.settings = {
    xfce4-panel = {
      panels = [ ];
    };
  };
}
