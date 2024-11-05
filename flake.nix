{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
    # See: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    # for recommendations on how to manage nixpkgs versions.
    # Default to the nixos-unstable branch:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Latest stable branch of nixpkgs, used for version rollback:
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    # You can also use a specific git commit hash to lock the version:
    # nixpkgs-fd40cef8d.url = "github:nixos/nixpkgs/fd40cef8d797670e203a27a91e4b8e6decf0b90c";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-colors.url = "github:misterio77/nix-colors";
  };
  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , nixos-hardware
    , sops-nix
    , nix-colors
    , ...
    } @ inputs:
    let
      mkSpecialArgs = system: {
        # The `specialArgs` parameter passes the
        # non-default nixpkgs instances to other nix modules
        pkgs-stable = import nixpkgs-stable {
          inherit system;
          # config.allowUnfree = true;
        };
      };
    in
    {
      # TODO: expose homemanagermodules and nixosmodules in flake:
      # https://discourse.nixos.org/t/nix-flake-wrapping-a-nix-module-using-home-manager/39162/4
      nixosConfigurations = {
        core = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = mkSpecialArgs system;

          modules = [
            # Base
            ./system
            # ./system/steam.nix
            ./system/ssh.nix # For headless

            # Hardware
            ./machines/core
            nixpkgs.nixosModules.notDetected

            # Secrets
            sops-nix.nixosModules.sops
            ./sops
          ];
        };
      };
      # Manage home configurations as a separate flake.
      # This allows for (1) keeping NixOS / non-NixOS the same and
      # (2) allowing for quicker home manager updates.
      # Found this user with same motivation: https://discourse.nixos.org/t/linking-a-nixosconfiguration-to-a-given-homeconfiguration/19737
      # Their implementation: https://github.com/diego-vicente/dotfiles/blob/6c47284868f9e99483da34257144bd03ae5edbbe/README.md
      # Better implementation: https://github.com/Misterio77/nix-config/blob/main/flake.nix
      # TODO Could in the future:
      # - bring all home-manager/machines into this flake
      # - setup common 'hostless' home-manager modules for each OS to avoid needing to create a machine-specific entry (would need a flake to be able to accept user / hostname inputs)
      # - also add it as a nixos module for nixos machines (so the initial builds work fine). Unclear if this is well supported
      homeConfigurations = {
        "mjmaurer@core" = nixpkgs.lib.dvm.buildCustomHomeConfig {
          modules = [
            ./home-manager/users/mjmaurer
          ];
        };
      };
    };
}
