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
    # remoteForwards = [
    #   # bind = path on *remote* ;  host = path on *local*
    #   {
    #     bind.address = gpgForwardedSocket;
    #     host.address = "${gpgHomedir}/S.gpg-agent";
    #   }
    # ];
    extraOptions = {
      PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
      ExitOnForwardFailure = "no";
      # Clean up stale sockets automatically:
      StreamLocalBindUnlink = "yes";
      # RemoteCommand = "tmux new-session -A -s main";
      # RequestTTY = "yes";
    };
  };
  "nixos-init-yubikey-match" = {
    match = "host ${hostListInitString}";
    user = "root";
    port = 22;
    extraOptions = {
      PKCS11Provider = "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib";
    };
  };
}
