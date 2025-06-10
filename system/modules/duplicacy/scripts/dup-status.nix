{ pkgs }:
pkgs.writeShellScriptBin "dup-status" ''
  #!/bin/sh
  # Show the status of the duplicacy timer
  echo "Status of Duplicacy timer (system-wide):"
  systemctl list-timers duplicacy.timer
''
