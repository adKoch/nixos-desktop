{ config, ... }: {
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/claude/settings.json";

  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink
      "/home/adam/nixos-desktop/claude/skills";

  home.shellAliases = {
    plan = "claude --model opus --permission-mode plan";
  };
}
