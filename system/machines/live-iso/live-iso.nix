{ nixpkgs ? <nixpkgs>, system ? "x86_64-linux" }:
# TODO: https://github.com/dmadisetti/.dots/blob/template/nix/machines/momento.nix
let
  configuration =
    { pkgs, ... }:
    {
      imports = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        # Provide an initial copy of the NixOS channel so that the user
        # doesn't need to run "nix-channel --update" first.
        "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
        ../../modules/_base.nix
      ];
      environment.systemPackages = with pkgs; [
        (writeScriptBin "partition" (builtins.readFile ./partition))
        git
      ];
    };
  iso-image = import "${nixpkgs}/nixos" { inherit system configuration; };
in
iso-image.config.system.build.isoImage
