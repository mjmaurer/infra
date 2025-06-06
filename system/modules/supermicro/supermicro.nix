{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Supermicro Fan Control
  smfc = pkgs.python3.pkgs.buildPythonApplication {
    pname = "smfc";
    version = "4.0.0b11";
    format = "pyproject";

    src = pkgs.fetchPypi {
      pname = "smfc";
      version = "4.0.0b11";
      hash = "sha256-RUGb2ETk+FLWfBL6e7FkdU525H+8al1jszZJoIh6WzA=";
    };
    propagatedBuildInputs = with pkgs.python3.pkgs; [
      pyudev
    ];
    nativeBuildInputs = with pkgs.python3.pkgs; [
      setuptools
      wheel
    ];
    meta = with lib; {
      description = "Supermicro Fan Control utility";
      homepage = "https://github.com/petersulyok/smfc";
      license = licenses.gpl3Only;
    };
  };
in
{

  config = {
    environment = {
      systemPackages = [
        pkgs.ipmitool
        smfc
      ];
      etc."smfc.conf".source = ./smfc.conf;
    };

    boot.kernelModules = [
      "ipmi_si"
      "ipmi_devintf"
    ];

    users = {
      groups.ipmiusers = { };
      users.smfc = {
        isSystemUser = true;
        group = "ipmiusers";
        description = "SMFC User";
      };
    };

    services.udev.extraRules = ''
      # Allow the ipmiusers group to talk to /dev/ipmi*
      SUBSYSTEM=="ipmi", KERNEL=="ipmi*", GROUP="ipmiusers", MODE="0660"
    '';

    # May need to reset BMC if there are issues with fan control: `ipmitool bmc reset cold`
    # I also set the fan control to "Standard" in impi webui, but not sure if that did anything

    # Unfortunately, Supermicro limited the ability to set fan thresholds in the latest BMC
    # See: https://github.com/petersulyok/smfc/issues/33
    systemd.services.smfc = {
      description = "Supermicro Fan Control daemon";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${smfc}/bin/smfc -c /etc/smfc.conf";
        Type = "simple";
        User = "smfc";
        Group = "ipmiusers";
        Restart = "always";
        PrivateTmp = true;
        ProtectSystem = "full";
        ProtectHome = "yes";
        NoNewPrivileges = true;
      };
    };
  };
}
