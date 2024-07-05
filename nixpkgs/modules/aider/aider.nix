{ pkgs, ... }:
let
in
{
  home.file = {
    ".config/aider/.aiderignore" = {
      source = ./.aiderignore;
    };
    ".aider.conf.yaml" = {
      source = ./aider.conf.yaml;
    };
  };
}
