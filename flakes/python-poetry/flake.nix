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
    {
      lib = python-flake.lib // {
        readme = ''
          ${python-flake.lib.readme}
        '';

        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (pkgs.poetry.override { python3 = python-flake.lib.mkPython pkgs; })
        ];
      };
    };
}
