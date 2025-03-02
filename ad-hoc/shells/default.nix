{
  pkgs,
  sops-nix-pkgs,
  lib,
  ...
}:
{
  new-host = import ./new-host.nix { inherit pkgs lib; };
  default = pkgs.mkShell {
    packages = with pkgs; [
      sops
      age
      ssh-to-age

      # Guide I used to set up Yubikey (also on GitHub)
      # drduh-yubikey-guide

      # Store keys on paper
      paperkey

      yubikey-manager
      yubikey-personalization
      # yubikey-touch-detector

      fixjson

      node2nix

      (pkgs.writeShellScriptBin "json-to-nix" ''
        nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile \"$1\")"
      '')

      (pkgs.writeShellScriptBin "updatenode" ''
        (cd ./home-manager/modules/node && node2nix - -i ./node-packages.json -c node-import.nix)
      '')

      (pkgs.writeShellScriptBin "sopsnew" ''
        # Just a reminder. Use this for new hosts.
        sops "$@"
      '')
      (pkgs.writeShellScriptBin "sopsa" ''
        # Uses sops with ssh key via ssh-to-age

        host_key_path="/etc/ssh/ssh_host_ed25519_key"

        # Parse command line arguments
        while [[ $# -gt 0 ]]; do
          case $1 in
            -k|--key-file)
              host_key_path="$2"
              shift 2
              ;;
            *)
              break
              ;;
          esac
        done

        # Create temp file with restricted permissions
        key_file=$(mktemp -t sops_age_key.XXXXXX)
        chmod 600 "$key_file"
        # Get key and store in temp file
        sudo ssh-to-age -private-key -i "$host_key_path" > "$key_file" 2>/dev/null
        SOPS_AGE_KEY=$(cat "$key_file")
        rm "$key_file"
        SOPS_AGE_KEY=$SOPS_AGE_KEY sops "$@"
      '')
    ];
    nativeBuildInputs = [ sops-nix-pkgs.sops-import-keys-hook ];
  };
}
