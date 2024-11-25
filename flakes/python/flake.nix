{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: {
    readme = ''
      Debugging:
      ```zsh
      bugpyw / bugpy
      ```
    '';
  } //
  flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        python = pkgs.python312;
      in
      {
        packages.lang = python;
        packages.default = with pkgs; [
          python
          # python312Packages.debugpy
          (writeShellScriptBin "bugpyw" ''
            exec python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client "$@"
          '')
          (writeShellScriptBin "bugpy" ''
            exec python -Xfrozen_modules=off -m debugpy --listen 5678 "$@"
          '')
        ];
      }
    );
}
