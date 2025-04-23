{
  inputs = {
    # nixpkgs.url = "github:NixOS/nixpkgs/24.11";
    # Arbitrary mainline / unstable April 23, 2025:
    # nixpkgs.url = "github:NixOS/nixpkgs/835524c6ef2d5e91fa7820f6e81b3751f1154fc3";
    # Arbitrary mainline April 23, 2025:
    # Run `cachix use nixpkgs-python` to avoid re-build
    nixpkgs-python.url = "github:cachix/nixpkgs-python/40d2237867f219de1c1362e3d067a1673afa5f82";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-python,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pythonPkg = nixpkgs-python.packages.${system}."3.12";
        java = {
          packages = with pkgs; [
            jdk17
            maven
          ];
          readme = ''
            For WSL external display server.
            ```bash
            export DISPLAY=$(netstat -rn | grep default | grep -v utun | head -n1 | awk '{print $2}'):0
            ```
          '';
        };
        pythonPip = {
          packages = with pkgs; [
            pythonPkg
            pythonPkg.pkgs.debugpy
            pythonPkg.pkgs.pip
          ];
          readme = ''
            Create a new virtual environment:
            ```zsh
            python -m venv .venv
            source ./.venv/bin/activate
            ```

            Install requirements:
            ```zsh
            pip install -r requirements.txt
            ```

            Debugging:
            ```zsh
            pydb / pydbw
            ```
          '';
        };
        pythonPoetry = {
          packages = with pkgs; [
            python312
            python312.pkgs.debugpy
            poetry.override
            { python3 = python312; }
          ];
          readme = ''
            Add the following to `poetry.toml`:
            ```toml
            [virtualenvs]
            in-project = true
            prefer-active-python = true
            ```

            Debugging:
            ```zsh
            pydb / pydbw
            ```
          '';
        };
        node = {
          packages = with pkgs; [
            nodejs_22
            yarn
          ];
          readme = "";
        };
        package = pythonPip;
        readme = pkgs.writeText "readme" ''
          # Commands

          Some command description:
          ```zsh
          command
          ```

          ${package.readme}
        '';
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs =
            with pkgs;
            [
              (writeShellScriptBin "inline_script" ''
                echo "Inline script"
              '')
              # (writeScriptBin "local_script" (builtins.readFile ./scripts/local.sh))
            ]
            ++ package.packages;
          shellHook = ''
            if [ -t 0 ]; then
              ${pkgs.glow}/bin/glow ${readme}
            fi
          '';
        };
      }
    );
}
