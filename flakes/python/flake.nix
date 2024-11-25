{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          python = pkgs.python312;

          commands = pkgs.writeText "commands" ''
            Debugging:
            ```zsh
            bugpyw / bugpy
            ```
          '';
        in
        {
          info.commands = commands;
          packages.lang = python;
          packages.default = with pkgs; [
            python
            python312Packages.debugpy
            (writeShellScriptBin "bugpyw" ''
              local cmd=$(escape_args "$@")
              exec debugpy --listen 5678 --wait-for-client "$cmd"
            '')
            (writeShellScriptBin "bugpy" ''
              local cmd=$(escape_args "$@")
              exec debugpy --listen 5678 "$cmd"
            '')
          ];
        }
      );
}
