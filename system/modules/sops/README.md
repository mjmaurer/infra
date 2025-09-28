# Layout

- `module-secrets` - Secrets that may be used in multiple `module-secrets` files
- `common-secrets` - (mostly) Secrets needed by home-manager programs. If creating a system module, prefer storing sops config in the module (like duplicacy)
- `vault` - Sops encrypted files

# Adding Secrets

Secrets are enabled based on tags defined in `flake.nix`. Check in the module you want to add to see which tags are enabled (Darwin is always enabled by default)

# Home Manager Integration

On Darwin, using the sops-nix home-manager module would require the host key pair to be root-readable. You could verify this is an issue by trying it and running `cat ~/Library/Logs/SopsNix/stderr`.

Instead, we make mark user readable secrets here, and symlink them as needed (`/run/` and `/User` can't be directly read on nix rebuild without `--impure`)

Alternatively, we could create a separate key pair for the user / home-manager on each host.
