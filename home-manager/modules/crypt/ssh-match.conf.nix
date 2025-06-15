{
  pkgs,
  nixosHostnames,
  gnupgDir,
  gpgForwardedSocket,
}:
let
  hostListString = builtins.concatStringsSep "," nixosHostnames;
in
{
  "nixos-yubikey-match" = {
    match = "host ${hostListString}";
    user = "mjmaurer";
    port = 2222;
    remoteForwards = [
      # bind = path on *remote* ;  host = path on *local*
      {
        bind.address = gpgForwardedSocket;
        host.address = "${gnupgDir}/S.gpg-agent.extra";
      }
    ];
    extraOptions = {
      PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
      # For running `ykman list` first.
      ProxyCommand = "${pkgs.zsh}/bin/zsh -c '${pkgs.yubikey-manager}/bin/ykman list >&2 || { echo \"ykman list failed or no YubiKey detected, aborting SSH.\" >&2; exit 1; }; exec ${pkgs.netcat}/bin/nc %h %p'";
      # Clean up stale sockets automatically:
      StreamLocalBindUnlink = "yes";
    };
  };
}
