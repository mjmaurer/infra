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
      # Clean up stale sockets automatically:
      StreamLocalBindUnlink = "yes";
    };
  };
}
