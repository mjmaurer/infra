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
      nixosConfigurations = {
        core = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          specialArgs = mkSpecialArgs system;

          modules = [
            # Base
            ./system
            # ./system/steam.nix

            # Hardware
            ./machines/neptune
            nixpkgs.nixosModules.notDetected

            # Secrets
            sops-nix.nixosModules.sops
            ./sops

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              # Packages will be installed to /etc/profiles:
              home-manager.useUserPackages = true;
              home-manager.users.mjmaurer = import ./users/mjmaurer {
                inherit nix-colors;
              };
            }
          ];
        };
        neptune = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Base
            ./system
            ./system/steam.nix

            # Hardware
            ./machines/neptune
            nixpkgs.nixosModules.notDetected

            # Secrets
            sops-nix.nixosModules.sops
            ./sops

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mjmaurer = import ./users/mjmaurer {
                inherit nix-colors;
              };
            }
          ];
        };
        jupiter = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Base
            ./system
            ./system/sway.nix

            # Hardware
            machines/jupiter

            # Secrets
            sops-nix.nixosModules.sops
            ./sops

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.mjmaurer = import ./users/mjmaurer {
                inherit nix-colors;
              };
            }
          ];
        };

      };
    };
}
