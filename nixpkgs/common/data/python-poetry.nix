let
  pkgs = import <unstable> { };
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python312
    (poetry.override { python3 = python312; })
    sqlite-analyzer
  ];
  shellHook =
    ''
      export SOME_VAR=some_value;
    '';
}
