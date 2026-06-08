{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Place the Goku EDN source file
  xdg.configFile."karabiner.edn".source = ./karabiner.edn;

  # Compile karabiner.edn -> karabiner.json via goku on activation
  home.activation.compileKarabiner = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    KARABINER_DIR="${config.xdg.configHome}/karabiner"
    KARABINER_JSON="$KARABINER_DIR/karabiner.json"

    mkdir -p "$KARABINER_DIR"

    # Seed karabiner.json if it doesn't exist (goku requires it)
    if [ ! -f "$KARABINER_JSON" ]; then
      echo '{"profiles":[{"name":"Default","selected":true,"complex_modifications":{"rules":[]}}]}' > "$KARABINER_JSON"
    fi

    export PATH="/opt/homebrew/bin:$PATH"
    if command -v goku &>/dev/null; then
      run goku
    else
      echo "WARNING: goku not found in PATH — skipping karabiner.edn compilation"
      echo "Install goku: brew install yqrashawn/goku/goku"
    fi
  '';
}
