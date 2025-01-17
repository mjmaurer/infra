On Darwin, using the sops-nix home-manager module would require the host key pair to be root-readable. You could verify this is an issue by trying it and running `cat ~/Library/Logs/SopsNix/stderr`.

Instead, we make mark user readable secrets here, and symlink them as needed (`/run/` and `/User` can't be directly read on nix rebuild without `--impure`)

Alternatively, we could create a separate key pair for the user / home-manager on each host.
