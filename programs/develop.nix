{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    settings = {
      git_branch = {
        format = "[$symbol$branch]($style) ";
        style = "bright-green";
      };
    };
  };
  environment.interactiveShellInit = ''
    eval "$(${pkgs.starship}/bin/starship init bash)"
  '';

  # Or for a custom Git branch prompt without Starship:
  programs.bash.promptInit = ''
    parse_git_branch() {
      ${pkgs.git}/bin/git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
    }

    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
  '';
}
