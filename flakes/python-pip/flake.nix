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

        mkPackages = pkgs: (python-flake.lib.mkPackages pkgs) ++ [
          (python-flake.lib.mkPython pkgs).pkgs.pip

          (pkgs.writeShellScriptBin "pyva" ''
            source .venv/bin/activate
          '')
          (pkgs.writeShellScriptBin "pyda" ''
            exec deactivate
          '')
        ];
      };
    };
}
