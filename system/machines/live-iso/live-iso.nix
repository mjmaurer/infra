{ nixpkgs, pkgs, ... }: {
  imports = [
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  environment.systemPackages = with pkgs;
    [ (writeScriptBin "partition" (builtins.readFile ./partition)) ];

  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AaAeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee username@host"
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
    firewall.enable = true;
    usePredictableInterfaceNames = false;
    useDHCP = true;
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
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
