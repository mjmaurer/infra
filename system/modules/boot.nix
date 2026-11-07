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
      # Grub should come up before initrd / passphrase prompt
      grub = {
        enable = true;
        efiSupport = true;
        device = "nodev"; # EFI w/ GPT
        # Keep up to 60 previous generations in GRUB boot menu
        # They will get garbage collected after
        configurationLimit = lib.mkDefault 60;
        enableCryptodisk = false; # Default

        # For BIOS w/ GPT (EF02) disko would add EF02 devices automatically
        # I use EFI here so not needed
        # devices = [ ];
      };
    };
    # Connect via dhcp in initrd with hostname ${derivationName}-init
    kernelParams = [ "ip=::::${derivationName}-init::dhcp" ];
    kernelModules = [ "drivetemp" ]; # For disk temperature monitoring
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
        # postCommands = ''
        #   cat > $out/etc/ssh/issue.net <<'EOF'
        #   ************************************************************
        #   ❶  NixOS early-boot environment
        #   ❷  Type ‘cryptsetup-askpass’ to unlock the root filesystem.
        #   ❸  All activity is logged.
        #   ************************************************************
        #   EOF
        # '';
        # SSH server for remote boot with encrypted drives. See:
        # https://discourse.nixos.org/t/disk-encryption-on-nixos-servers-how-when-to-unlock/5030/13
        # https://wiki.archlinux.org/title/Dm-crypt/Specialties#Remote_unlocking_of_the_root_(or_other)_partition
        ssh = {
          enable = true;
          port = 2222;
          # NixOS 26.05 switched initrd to systemd stage 1, where `cryptsetup-askpass`
          # no longer exists (it can no longer be set as the login shell). To preserve
          # the old behavior of prompting for the LUKS passphrase on SSH login without
          # granting an interactive shell, force `systemctl default` as the SSH command
          # via authorized_keys; it prompts for passphrases as needed and advances boot.
          # See the NixOS 26.05 release notes.
          #
          # This path is chosen because it's the lowest-risk change for a headless box:
          # it reuses the same initrd sshd + authorizedKeys flow that already worked, and
          # does not depend on an interactive shell being present in the initrd.
          #
          # TODO(debug-shell): if we ever want a full debug shell over SSH in early boot
          # (to debug a failed boot without a live-iso / console), do NOT just unset the
          # shell — bashInteractive is only bundled into the systemd initrd when a shell
          # is explicitly enabled. Instead bundle a shell and point root at it, e.g.:
          #   boot.initrd.systemd.storePaths = [ "${pkgs.bashInteractive}/bin/bash" ];
          #   boot.initrd.systemd.users.root.shell = "${pkgs.bashInteractive}/bin/bash";
          # then run `systemctl default` manually after logging in. Verify with console
          # access before relying on it headless.
          # add the Banner line to sshd_config
          # extraConfig = ''
          #   Banner /etc/ssh/issue.net
          # '';
          hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = map (
            key: ''command="systemctl default" ${key}''
          ) config.users.users.${username}.openssh.authorizedKeys.keys;
        };
      };
    };
  };
}
