{ config, pkgs, ... }:
let
  conf = "/etc/duplicacy/duplicacy.conf";
  backup = "backup -limit-rate 25000 -max-in-memory-entries 1024 -threads 4 -stats";
in
{
  # https://forum.duplicacy.com/t/duplicacy-quick-start-cli/1101
  # https://forum.duplicacy.com/t/encryption-of-the-storage/1085
  systemd.user.services.duplicacy = {
    Unit.Description = "Duplicacy backup service";
    Service = {
      Restart = "no";
      WorkingDirectory = config.home.homeDirectory;
      ExecStart = pkgs.writeShellScript "run-duplicacy" ''
        #!/bin/bash
        ${pkgs.duplicacy}/bin/duplicacy ${backup}
      '';
      EnvironmentFile = conf;
    };
  };

  systemd.user.timers.duplicacy= {
    Unit.Description = "Timer for Duplicacy backup service";
    Timer = {
      Unit = "duplicacy.service";
      OnCalendar = "Mon *-*-* 05:00:00 America/New_York";
      Persistent = true; # Catch up on missed runs
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.bash = {
    # Must call duplicacy-activate to start the timer (or reboot)
    shellAliases = {
      duplicacy-activate = "systemctl --user start duplicacy.timer";
      duplicacy-log = "journalctl --user -fu duplicacy.service";
      duplicacy-backup = "systemctl --user start duplicacy.service";
      duplicacy-status = "systemctl --user list-timers";
      duplicacy-backup-init = ''
        cd && ${pkgs.duplicacy}/bin/duplicacy backup -limit-rate 20000 -max-in-memory-entries 1024 -threads 4 -stats -t initial
      '';
      # nas is the 'snapshot id' (repository id?) for the backup
      # the b2 bucket will be the 'storage', which can contain multiple repos
      duplicacy-init = ''
        source ${conf}
        cd && ${pkgs.duplicacy}/bin/duplicacy init -encrypt -zstd nas b2://$BUCKET_NAME
      '';
    };
  };
}
