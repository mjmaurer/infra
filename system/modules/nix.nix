{ lib, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = false;
  };
  nix = {
    settings = {
      trusted-users = [
        "mjmaurer"
        "root"
        # "@wheel"
      ];
      experimental-features = "nix-command flakes";
    };

    # Opinionated: disable channels
    # channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    # registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
