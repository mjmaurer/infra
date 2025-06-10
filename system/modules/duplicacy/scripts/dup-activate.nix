{ pkgs }:
pkgs.writeShellScriptBin "dup-activate" ''
  #!/bin/sh
  set -e
  # Start the duplicacy timer to run backups
  echo "Activating Duplicacy timer (system-wide)..."
  systemctl start duplicacy.timer
  echo "Timer duplicacy.timer started."
  echo "Run 'dup-status' to check its status."
''
