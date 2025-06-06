{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
let
  # Supermicro Fan Control
  smfc = pkgs.python3.pkgs.buildPythonApplication {
    pname = "smfc";
    version = "4.0.0b11";

    src = pkgs.fetchPypi {
      pname = "smfc";
      version = "4.0.0b11";
      hash = "sha256-RUGb2ETk+FLWfBL6e7FkdU525H+8al1jszZJoIh6WzA=";
    };
    propagatedBuildInputs = with pkgs.python3.pkgs; [
      pyudev
    ];
    # nativeBuildInputs = with pkgs.python3.pkgs; [
    #   setuptools
    #   wheel
    # ];
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
    };

    boot.kernelModules = [
      "ipmi_si"
      "ipmi_devintf"
    ];

    # May need to reset BMC if there are issues with fan control: `ipmitool bmc reset cold`
    # I also set the fan control to "Standard" in impi webui, but not sure if that did anything
    # environment.etc."smfc.yaml".text = ''
    #   ipmi:
    #     interface: kcs        # or lanplus + host/user/pass
    #   zones:
    #     CPU:
    #       sensors:  [ "CPU Temp" ]
    #       fans:     [ "FAN1", "FAN2", "FAN3" ]
    #       curve:    { 30: 20, 45: 40, 55: 70, 65: 100 }
    #     SYS:
    #       sensors:  [ "System Temp" ]
    #       fans:     [ "FAN4", "FAN5", "FAN6" ]
    #       curve:    { 25: 20, 40: 50, 55: 80, 65: 100 }
    # '';

    # systemd.services.smfc = {
    #   description = "Supermicro Fan Control daemon";
    #   wantedBy = [ "multi-user.target" ];
    #   after = [ "network-online.target" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.nur.repos.xddxdd.smfc}/bin/smfc --config /etc/smfc.yaml";
    #     Restart = "always";
    #   };
    # };
  };
}
