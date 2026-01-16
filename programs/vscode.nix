{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  # VSCode configuration for Remote-WSL
  # Note: Install VSCode on Windows and use Remote-WSL extension
  # This config will be used when VSCode connects to WSL
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Language support
        ms-vscode.cpptools
        ms-python.python
        bradlc.vscode-tailwindcss
        rust-lang.rust-analyzer
        ms-vscode.cmake-tools
        golang.go
        redhat.java
        mathiasfrohlich.kotlin

        # Git
        eamodio.gitlens

        # Utilities
        ms-vscode-remote.remote-ssh
        ms-vscode.live-server
        esbenp.prettier-vscode

        # Themes & Icons
        dracula-theme.theme-dracula
        pkief.material-icon-theme
        vscode-icons-team.vscode-icons

        # Productivity
        streetsidesoftware.code-spell-checker
      ];

      userSettings = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "JetBrains Mono";
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "editor.wordWrap" = "on";
        "editor.minimap.enabled" = false;
        "editor.formatOnSave" = true;
        "editor.cursorBlinking" = "smooth";
        "editor.lineNumbers" = "on";

        "workbench.colorTheme" = "Dracula";
        "workbench.iconTheme" = "vscode-icons";
        "workbench.startupEditor" = "newUntitledFile";

        "terminal.integrated.fontFamily" = "JetBrains Mono";
        "terminal.integrated.fontSize" = 14;

        "git.enableSmartCommit" = true;
        "git.confirmSync" = false;

        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        "explorer.confirmDelete" = false;
        "explorer.confirmDragAndDrop" = false;

        # Language specific settings
        "go.formatTool" = "goimports";
        "go.useLanguageServer" = true;
        "java.configuration.updateBuildConfiguration" = "automatic";
      };
    };
  };
}
