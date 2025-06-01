{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
{

  imports = [
    ../../modules/graphics/intel-skylake.nix

    ./hardware-configuration.nix
    ./disko.nix
  ];

  config = {

    modules.sops.enableMinimalSecrets = true;

    sops.secrets.oneTimeTailscaleAuthKey = {
      sopsFile = ./secrets.yaml;
    };

    # Intel NIC (retrieve via lspci -k)
    boot.initrd.availableKernelModules = [ "e1000e" ];

    networking = {
      # Unique host ID for ZFS.
      # Can generate with:
      #   echo $(hostname) | sha256sum | awk '{print substr($1,1,8)}'
      hostId = "02eb912a";
    };
  };
}
