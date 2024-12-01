{
  outputs = { self }:
    {
      lib = {
        readme = ''
          Debugging:
          ```zsh
          bugpyw / bugpy
          ```
        '';

        overlays = [ ];

        mkPython = pkgs: pkgs.python312;
        mkLang = self.lib.mkPython;
        mkPackages = pkgs: with pkgs; [
          (self.lib.mkPython pkgs)
          (self.lib.mkPython pkgs).pkgs.debugpy

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
