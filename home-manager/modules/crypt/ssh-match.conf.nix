{
  pkgs,
  nixosHostnames,
  gpgHomedir,
  gpgForwardedSocket,
}:
let
  hostListString = builtins.concatStringsSep "," nixosHostnames;
  hostListInitString = builtins.concatStringsSep "," (
    map (h: "${h}-init,${h}-init.localdomain") nixosHostnames
  );
in
{
  "*" = {
    ForwardAgent = false;
    AddKeysToAgent = "no";
    Compression = false;
    ServerAliveInterval = 0;
    ServerAliveCountMax = 3;
    HashKnownHosts = false;
    UserKnownHostsFile = "~/.ssh/known_hosts";
    ControlMaster = "no";
    ControlPath = "~/.ssh/master-%r@%n:%p";
    ControlPersist = "no";
  };
  "nixos-yubikey-match" = {
    header = "Match host ${hostListString}";
    User = "mjmaurer";
    Port = 2222;
    # remoteForwards = [
    #   # bind = path on *remote* ;  host = path on *local*
    #   {
    #     bind.address = gpgForwardedSocket;
    #     host.address = "${gpgHomedir}/S.gpg-agent";
    #   }
    # ];
    PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
    ExitOnForwardFailure = "no";
    # Clean up stale sockets automatically:
    StreamLocalBindUnlink = "yes";
    # RemoteCommand = "tmux new-session -A -s main";
    # RequestTTY = "yes";
  };
  "nixos-init-yubikey-match" = {
    header = "Match host ${hostListInitString}";
    User = "root";
    Port = 2222;
    PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
  };
}
