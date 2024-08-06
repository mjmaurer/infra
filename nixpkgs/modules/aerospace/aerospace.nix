{ pkgs, ... }:
let
in
{
  home.file = {
    ".config/aerospace/aerospace.toml" = {
      source = ./aerospace.toml;
    };
  };
}
