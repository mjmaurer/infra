{
  pkgs,
  sops-nix-pkgs,
  lib,
  ...
}:
let
  nix4vscode = pkgs.rustPlatform.buildRustPackage rec {
    pname = "nix4vscode";
    version = "0.0.12"; # Use the latest version from the repo

    src = pkgs.fetchFromGitHub {
      owner = "nix-community";
      repo = "nix4vscode";
      rev = "21eb5896042345acd161f46416f4e826755f766f";
      # You can get the hash by running: nix-prefetch
      sha256 = "sha256-wRrC4fQcyeTwLK4SoZvIyG2kqp7NRkmh+i1QsVikULA=";
    };

    # You can get this by first trying to build with a fake hash and then copying the correct one from the error message
    cargoHash = "sha256-Jwqwifu9TL21wDcY7E/8GcX5wZOLqBcfABbw9Ilb2fQ=";
    useFetchCargoVendor = true;

    RUSTC_BOOTSTRAP = 1; # Enable nightly features on stable compiler

    # You might also need to patch the Cargo.toml to use a stable edition
    postPatch = ''
      substituteInPlace Cargo.toml --replace 'edition = "2024"' 'edition = "2021"'
    '';

    meta = with lib; {
      description = "A tool to generate nix expressions for VSCode extensions";
      homepage = "https://github.com/nix-community/nix4vscode";
      license = licenses.asl20;
      maintainers = with maintainers; [
        # your name here
      ];
    };
  };
in
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

      # nix4vscode
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
      (pkgs.writeShellScriptBin "disko-run" ''
        echo "This takes a path to a disko.nix patch file."
        echo "WARNING: This will destroy, format, and mount disks. Are you sure? [y/N]"
        read -r confirm
        if [ "$confirm" != "y" ]; then
          echo "Aborted."
          exit 1
        fi
        sudo nix run github:nix-community/disko/latest -- --mode destroy,format,mount "$@"
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
