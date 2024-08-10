{ pkgs, ... }:
let
in
{
  home.file = {
    ".config/aider/.aiderignore" = {
      source = ./.aiderignore;
    };
    ".aider.conf.yml" = {
      source = ./aider.conf.yml;
    };
  };

  programs.bash = {
    shellAliases = {
      aid = "aider --4";
      aider = "aider --4";
      aids = "aider --sonnet";
      aidf = "aider --4";
      aidfo = "aider --4o";
    };
  };
}
