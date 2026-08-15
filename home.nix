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
    ./programs/jules.nix
    ./programs/lmstudio.nix
    ./programs/mistral-vibe.nix
    ./programs/goose.nix
    ./programs/opencode.nix
    ./programs/tinfoil.nix
    ./programs/terminal.nix
  ];

  # Enable bash in home-manager to auto-source session variables
  programs.bash.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

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
        # RFP randomizes canvas extraction, which corrupts copied canvas images.
        "privacy.resistFingerprinting" = false;
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

    # Gaming — Path of Building (PoB 1/2 build planner).
    # Wrapped to force the NVIDIA GPU adapter: wgpu otherwise selects a mesa
    # software Vulkan device and renders a black screen (single-GPU NVIDIA box).
    # Uses the unstable 0.2.18 runtime so the bundled PoB data can self-update.
    (symlinkJoin {
      name = "rusty-path-of-building-wrapped";
      paths = [ pkgs-unstable.rusty-path-of-building ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/rusty-path-of-building \
          --set-default WGPU_ADAPTER_NAME NVIDIA
      '';
    })

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
    anki
    sox

    (pkgs.writeShellScriptBin "start-audiobookshelf" ''
      CONFIG_DIR="$HOME/.config/audiobookshelf"
      mkdir -p "$CONFIG_DIR/config" "$CONFIG_DIR/metadata"
      echo "Starting Audiobookshelf on http://localhost:8000..."
      echo "Config: $CONFIG_DIR/config"
      echo "Metadata: $CONFIG_DIR/metadata"
      PORT=8000 \
      CONFIG_PATH="$CONFIG_DIR/config" \
      METADATA_PATH="$CONFIG_DIR/metadata" \
      ${pkgs.audiobookshelf}/bin/audiobookshelf
    '')
  ]) ++ (with pkgs-unstable; [
    antigravity-cli
    claude-code
    codex
    uv
    nixd
    nil
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
