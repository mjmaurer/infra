{ pkgs, ... }:
let
  nodePackages = import ./node-import.nix {
    inherit pkgs;
    nodejs = pkgs.nodejs_22;
  };
in
{
  config = {
    home.packages = [];
  };
}
