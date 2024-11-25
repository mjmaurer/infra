{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    python-flake = {
      url = "path:../python";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, python-flake }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          python = python-flake.packages.${system}.lang;
          readme = ''
            ${toString python-flake.readme}
          '';
        in
        with pkgs;
        {
          readme = readme;
          packages.lang = python;
          packages.default = with pkgs; python-flake.packages.${system}.default ++ [
            (poetry.override { python3 = python; })
          ];
        }
      );
}
