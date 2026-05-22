{
  config,
  pkgs-unstable,
  lib,
  ...
}: {
  home.packages = [
    pkgs-unstable.lmstudio
  ];

  home.file.".config/LM Studio/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/lmstudio/settings.json";

  home.file.".lmstudio/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/lmstudio/settings.json";

  # Ensure the model directory exists
  home.activation.createLmStudioModelDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "/home/adam/lm-studio/models"
  '';
}
