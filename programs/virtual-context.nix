{ pkgs, ... }: {
  home.packages = with pkgs; [
    pipx
  ];

  # Ensure pipx bin dir is on PATH
  home.sessionVariables = {
    PIPX_HOME = "$HOME/.local/pipx";
  };
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Systemd user service to run virtual-context proxy as a daemon
  systemd.user.services.virtual-context = {
    Unit = {
      Description = "Virtual Context proxy for AI context management";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "%h/.local/bin/virtual-context proxy --upstream https://api.anthropic.com --port 5757";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [
        "PATH=%h/.local/bin:/run/current-system/sw/bin"
        # numpy/sentence-transformers (pipx) need libstdc++ which NixOS doesn't expose globally
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
