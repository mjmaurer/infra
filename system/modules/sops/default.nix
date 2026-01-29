# https://nixos.org/manual/nixos/stable/#module-services-garage
{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.sops;
in
{

  imports = [
    ./common-secrets/ai-secrets.nix
    ./common-secrets/gpg-secrets.nix
    ./common-secrets/nixos-host-secrets.nix
    ./common-secrets/smb-secrets.nix
    ./common-secrets/cloudflare-secrets.nix
    ./common-secrets/garage-secrets.nix
    ./common-secrets/postgresql-secrets.nix

    ./module-secrets/llm-cli-sops.nix
    ./module-secrets/shell-sops.nix
    ./module-secrets/yt-upload-sops.nix
  ];

  config = {
    sops = {
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Generate age key based on above SSH key to this path
      age.keyFile = "/var/lib/sops-nix/key.txt";
      age.generateKey = true;

      # Not using host GPG keys, so unset default
      gnupg.sshKeyPaths = [ ];

      defaultSopsFile = ./secrets/common.yaml;
    };
  };
}
