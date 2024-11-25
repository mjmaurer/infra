{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    base-flake = {
      url = "github:mjmaurer/infra/flakes/<BASE_FLAKE>";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, base-flake }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          base-flake = base-flake.packages.${system};
        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = with pkgs; base-flake.default ++ [
            ];
          };
        }
      );
}
