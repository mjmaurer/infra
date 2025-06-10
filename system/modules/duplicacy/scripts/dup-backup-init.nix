{ pkgs }:
pkgs.writeShellScriptBin "dup-backup-init" ''
  #!/bin/sh
  set -e
  # This script assumes dup-backup is in PATH.
  dup-backup "$@" -t initial
''
