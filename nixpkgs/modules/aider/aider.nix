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
}
