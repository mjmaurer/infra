# Nixpkgs / Home-Manager

This largely assumes a single user, default `mjmaurer7`, per machine.

## Overview

- `machines` - Host-specific configuration
- `common` - Provides common imports for a given host
  - `base.nix` - Common for every host
  - `{linux,mac,wsl}.nix` - Common for given OS
  - `shell/` - Common shell configuration. Provided as a module that other modules can configure / import.
- `modules` - Modules that can optionally be enabled for a given host. Some modules install the actual package, and others just provide configuration for software that is installed separate from Nix.
