{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    {
      lib = {
        readme = ''
          Debugging:
          ```zsh
          bugpyw / bugpy
          ```
        '';

        lang = pkgs: pkgs.python312;
        python = self.lang;
        packages = pkgs: with pkgs; [
          (self.python pkgs)
          (self.python pkgs).pkgs.debugpy

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
      };
    };
}
