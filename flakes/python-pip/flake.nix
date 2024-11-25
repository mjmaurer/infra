{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    python-flake = {
      url = "path:../python";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, python-flake }: {
    readme = ''
      ${python-flake.readme}}

      Activate / Deactivate:
      ```zsh
      pyva / pyda
      ```

      Create a new virtual environment:
      ```zsh
      python -m venv .venv
      ```

      Install requirements:
      ```zsh
      pip install -r requirements.txt
      ```
    '';
  } //
  flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        python = python-flake.packages.${system}.lang;
      in
      with pkgs;
      {
        packages.lang = python;
        packages.default = with pkgs; python-flake.packages.${system}.default ++ [
          python312Packages.pip

          (writeShellScriptBin "pyva" ''
            source .venv/bin/activate
          '')
          (writeShellScriptBin "pyda" ''
            exec deactivate
          '')
        ];
      }
    );
}
