{
  pkgs,
  nixosHostnames,
  gpgHomedir,
  gpgForwardedSocket,
}:
let
  hostListString = builtins.concatStringsSep "," nixosHostnames;
  hostListInitString = builtins.concatStringsSep "," (map (h: "${h}-init") nixosHostnames);
in
{
  "nixos-yubikey-match" = {
    match = "host ${hostListString}";
    user = "mjmaurer";
    port = 2222;
    sendEnv = [ "GPG_TTY" ];
    remoteForwards = [
      # bind = path on *remote* ;  host = path on *local*
      {
        bind.address = gpgForwardedSocket;
        host.address = "${gpgHomedir}/S.gpg-agent";
      }
    ];
    extraOptions = {
      PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
      # Clean up stale sockets automatically:
      StreamLocalBindUnlink = "yes";
    };
  };
}
