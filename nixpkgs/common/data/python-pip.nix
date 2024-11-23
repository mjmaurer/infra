let
  pkgs = import <unstable> { };
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  info = pkgs.writeText "info" ''
    # Commands
    
    Create a new virtual environment:
    ```zsh
    python -m venv .venv
    ```

    Activate / Deactivate:
    ```zsh
    pyva / pyda
    ```
    
    Install requirements:
    ```zsh
    pip install -r requirements.txt
    ```
  '';
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
  ];
  shellHook =
    ''
      glow ${info}
    '';
}
