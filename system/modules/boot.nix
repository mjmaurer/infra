{
  lib,
  config,
  username,
  derivationName,
  ...
}:
{
  # fileSystems."/etc/ssh".neededForBoot = true;
  # fileSystems."/var/lib/sops-nix".neededForBoot = true; # Needed for sops key

  # This assumes boot parition is unencrypted, and root parititon is encrypted with luks.
  # https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
  # Could use secureboot / tpm / ima integrity
  boot = {
    # There are other examples for different machines
    # in the original repo for EFI, Windows, Nvidia, etc.
    loader = {
      efi = {
        canTouchEfiVariables = true;
        # efiSysMountPoint = "/boot"; This was set in original repo
      };
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev"; # EFI w/ GPT
        # Keep up to 10 previous generations in GRUB boot menu
        # They will get garbage collected after
        configurationLimit = lib.mkDefault 10;

        # For BIOS w/ GPT (EF02) disko would add EF02 devices automatically
        # I use EFI here so not needed
        # devices = [ ];
      };
    };
    # Connect via dhcp in initrd with hostname ${derivationName}-init
    kernelParams = [ "ip=::::${derivationName}-init::dhcp" ];
    initrd = {
      # Run: lspci -k | grep -EA3 'VGA|3D|Display'
      # Early loading so the passphrase prompt appears on external displays
      # kernelModules = [ "i915" ];

      # Intel NIC (retrieve via lspci -k)
      availableKernelModules = [ "e1000e" ];

      # systemd.network.wait-online = {
      #   enable = false;
      # };
      network = {
        enable = true;
        # SSH server for remote boot with encrypted drives. See:
        # https://discourse.nixos.org/t/disk-encryption-on-nixos-servers-how-when-to-unlock/5030/13
        # https://wiki.archlinux.org/title/Dm-crypt/Specialties#Remote_unlocking_of_the_root_(or_other)_partition
        ssh = {
          enable = true;
          port = 2222;
          # Prompt for the LUKS encryption password during early boot
          shell = "/bin/cryptsetup-askpass";
          hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = config.users.users.${username}.openssh.authorizedKeys.keys;
        };
      };
    };
  };
}
