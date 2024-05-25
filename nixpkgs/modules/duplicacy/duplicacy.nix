{ config, pkgs, ... }:
let
in
{
  systemd.user.services.duplicacy = {
    Unit.Description = "Duplicacy backup service";
    Install.WantedBy = [ "default.target" ];
    Service = {
      Restart = "on-failure";
      ExecStart = "${pkgs.writeShellScript "run-duplicacy" ''
        #!/bin/bash
        #ENV=var
        ${pkgs.duplicacy}/bin/duplicacy
      ''}";
    };
  };
};
