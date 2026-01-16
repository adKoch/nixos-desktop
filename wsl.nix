{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable WSL
  wsl.enable = true;
  wsl.defaultUser = "adam";

  # WSL-specific settings
  wsl.wslConf = {
    automount.root = "/mnt";
    interop.appendWindowsPath = true;
    network.generateHosts = true;
    network.generateResolvConf = true;
  };

  # Optional: Enable Docker Desktop integration
  # wsl.docker-desktop.enable = true;

  # Optional: Enable USB/IP support
  # wsl.usbip.enable = true;
}
