{ pkgs }:
pkgs.writeShellScriptBin "dup-log" ''
  #!/bin/sh
  # Lists logs for the main duplicacy backup service.
  # For init/restore logs, use: journalctl -fu duplicacy-init-REPO_KEY.service or duplicacy-restore-REPO_KEY.service
  journalctl -fu duplicacy.service
''
