# Note: Also used by live-iso
{ pubkeys, pkgs }: {
  # Enable SSH in the boot process.
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.root.openssh.authorizedKeys.keys = [
    pubkeys.sshPubYkcWal
    pubkeys.sshPubYkaStub
    pubkeys.sshPubYkcKey
    pubkeys.sshPubBw
  ];

  # This setups a SSH server for a headless system.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
}
