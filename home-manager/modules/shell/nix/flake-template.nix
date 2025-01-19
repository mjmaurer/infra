{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, base-flake }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
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
              python312
              python312.pkgs.debugpy
              python312.pkgs.pip
            ];
            readme = ''
              Create a new virtual environment:
              ```zsh
              python -m venv .venv
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
            readme = ''
            '';
          };
          package = pythonPoetry;
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
            buildInputs = with pkgs; [
              (writeShellScriptBin "inline_script" ''
                echo "Inline script"
              '')
              (writeScriptBin "local_script" (builtins.readFile ./scripts/local.sh))
            ] ++ package.packages;
            shellHook = ''
              if [ -t 0 ]; then
                ${pkgs.glow}/bin/glow ${readme}
              fi
            '';
          };
        }
      );
}
