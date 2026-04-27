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
    ./programs/codex.nix
    ./programs/gemini-cli.nix
    ./programs/jules.nix
    ./programs/terminal.nix
  ];

  # Enable bash in home-manager to auto-source session variables
  programs.bash.enable = true;

  home.shellAliases = {
    nd = "nix develop";
    sops-encrypt = "sops -e -i";
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
    gcc
    gnumake

    # 3D Printing
    bambu-studio

    # Office Suite
    libreoffice
    gimp

    # Work
    hubstaff

    # Utilities
    blueman
    appimage-run
    obsidian
    anki
    sox
  ]) ++ (with pkgs-unstable; [
    claude-code
    codex
    gemini-cli
    uv
  ]);

  programs.git = {
    enable = true;
  };

  services.gpg-agent.enableSshSupport = false;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      addKeysToAgent = "yes";
    };
  };

  # Disable XFCE panel
  xfconf.settings = {
    xfce4-panel = {
      panels = [ ];
    };
  };

  home.activation.setupSopsAgeKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "$HOME/.config/sops/age/keys.txt" ]; then
      if [ -f "$HOME/.ssh/id_ed25519" ]; then
        $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.config/sops/age"
        # We use a subshell to capture output and avoid redirection issues with $DRY_RUN_CMD if we were using it for everything
        # but here we just run the command directly if not dry run.
        if [ -z "$DRY_RUN_CMD" ]; then
          ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "$HOME/.ssh/id_ed25519" > "$HOME/.config/sops/age/keys.txt"
          chmod 600 "$HOME/.config/sops/age/keys.txt"
        else
          echo "$DRY_RUN_CMD ssh-to-age -private-key -i $HOME/.ssh/id_ed25519 > $HOME/.config/sops/age/keys.txt"
        fi
      fi
    fi
  '';
}
