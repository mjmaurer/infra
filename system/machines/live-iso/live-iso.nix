{
  nixpkgs,
  pkgs,
  pubkeys,
  ...
}:
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  environment.systemPackages = with pkgs; [
    (writeScriptBin "partition" (builtins.readFile ./partition))

    pciutils
    which
    wget
    tree
    ripgrep
    unzip
    tcpdump
    neovim
    findutils
    bind
    parted
  ];

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = [
    pubkeys.sshPubYkcWal
    pubkeys.sshPubYkaStub
    pubkeys.sshPubYkcKey
    pubkeys.sshPubBw
  ];

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };
  };

  networking = {
    hostName = "isoboot";
    firewall.enable = true;
    usePredictableInterfaceNames = false;
    # Whether to use DHCP to obtain an IP address and other configuration
    # for all network interfaces that do not have any manually configured IPv4 addresses.
    useDHCP = true;
    dhcpcd.enable = true; # True by default
    nameservers = [
      "8.8.8.8"
      "8.8.4.4"
    ];
  };

  isoImage = {
    squashfsCompression = "gzip -Xcompression-level 1";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  nix.settings = {
    allowed-users = [ "root" ];
    trusted-users = [ "root" ];
  };
}
