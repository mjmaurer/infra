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
          python312Packages.debugpy
          # (python.withPackages (python-pkgs: [
          #   python-pkgs.debugpy
          # ]))
          (writeShellScriptBin "bugpyw" ''
            echo "python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client $@"
            echo "May need to activate venv\n"
            echo "Waiting for debugger to attach..."
            exec python -Xfrozen_modules=off -m debugpy --listen 5678 --wait-for-client "$@"
          '')
          (writeShellScriptBin "bugpy" ''
            echo "python -Xfrozen_modules=off -m debugpy --listen 5678 $@"
            echo "May need to activate venv"
            exec python -Xfrozen_modules=off -m debugpy --listen 5678 "$@"
          '')
        ];
      }
    );
}
