{ pkgs, sops-nix-pkgs, ... }: {
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


      (pkgs.writeShellScriptBin "json-to-nix" ''
        nix-instantiate --eval -E "builtins.fromJSON (builtins.readFile \"$1\")"
      '')

      (pkgs.writeShellScriptBin "sopsa" ''
        # Uses sops with ssh key via ssh-to-age

        # Create temp file with restricted permissions
        key_file=$(mktemp -t sops_age_key.XXXXXX)
        chmod 600 "$key_file"
        # Get key and store in temp file
        sudo ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key > "$key_file" 2>/dev/null
        SOPS_AGE_KEY=$(cat "$key_file")
        rm "$key_file"
        SOPS_AGE_KEY=$SOPS_AGE_KEY sops "$@"
      '')
    ];
    nativeBuildInputs = [ sops-nix-pkgs.sops-import-keys-hook ];
    shellHook = ''
      export NIX_CONFIG="extra-experimental-features = nix-command flakes ca-derivations";
    '';
  };
}
