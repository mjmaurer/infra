{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
    # See: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    # for recommendations on how to manage nixpkgs versions.

    # Default to the nixos-unstable branch:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Latest nixpkgs, to get latest versions of some packages 
    # nixpkgs-latest.url = "github:nixos/nixpkgs/master";

    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-std.url = "github:chessai/nix-std";
    impermanence.url = "github:nix-community/impermanence";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-darwin.follows = "darwin";
      inputs.flake-utils.follows = "flake-utils";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      # Don't follow nixpkgs so we can update the extensions more frequently.
      # inputs.nixpkgs.follows = "nixpkgs";
      # inputs.flake-utils.follows = "flake-utils";
    };

    # Build our own wsl
    # https://github.com/dmadisetti/.dots/blob/template/flake.nix
    # nixos-wsl.url = github:nix-community/NixOS-WSL;
    # nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    # nixos-wsl.inputs.flake-utils.follows = "flake-utils";
  };
  outputs = { self, nixpkgs, home-manager, nixos-hardware, sops-nix, nix-colors
    , nix-std, nix-homebrew, impermanence, flake-utils, darwin
    , nix-vscode-extensions, ... }@inputs:
    let
      defaultUsername = "mjmaurer";
      forEachSystem = f:
        flake-utils.lib.eachDefaultSystem (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            sops-nix-pkgs = sops-nix.packages.${system};
          in f { inherit system pkgs sops-nix-pkgs; });
      withConfig = { system, derivationName, username ? defaultUsername
        , extraSpecialArgs ? { } }: rec {
          mkSpecialArgs = {
            # The `specialArgs` parameter passes the
            # non-default arguments to nix modules.
            # Default arguments are things like `pkgs`, `lib`, etc.

            inherit (inputs)
              nix-std nix-colors nix-vscode-extensions nix-homebrew;
            inherit username derivationName system;
            # pkgs-latest = nixpkgs-latest.legacyPackages.${system};
            colors = import ./lib/colors.nix { lib = nixpkgs.lib; };
            isDarwin = system == "aarch64-darwin";
          } // extraSpecialArgs;
          mkHomeManagerStandalone = { modules ? [ ] }:
            home-manager.lib.homeManagerConfiguration {
              extraSpecialArgs = mkSpecialArgs;
              # See here on legacyPackages vs import: 
              # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
              pkgs = nixpkgs.legacyPackages.${system};
              modules = modules;
            };
          mkHomeManagerModuleConfig = { homeModule, homeStateVersion }: {
            # Keep these false so home-manager and nixos derivations don't diverge.
            # By default, Home Manager uses a private pkgs instance via `home-manager.users.<name>.nixpkgs`.
            # To instead use the global (system-level) pkgs, set to true.
            home-manager.useGlobalPkgs = true;
            # Packages installed to `$HOME/.nix-profile` if true, otherwise `/etc/profiles/`.
            home-manager.useUserPackages = false;
            home-manager.extraSpecialArgs = mkSpecialArgs;
            home-manager.backupFileExtension = "home-manager-existing-backup";
            # home-manager.verbose = true;
            home-manager.users.${username} = homeModule;
            home-manager.sharedModules = [
              { home.stateVersion = homeStateVersion; }
              sops-nix.homeManagerModules.sops
            ];
          };
          mkDarwinSystem = { systemStateVersion, homeStateVersion
            , systemModules ? [ ./system/common/darwin.nix ]
            , homeModule ? import ./home-manager/common/mac.nix }:
            darwin.lib.darwinSystem {
              system = if system == "aarch64-darwin" then
                system
              else
                throw "System must be aarch64-darwin";
              specialArgs = mkSpecialArgs;
              modules = [
                sops-nix.darwinModules.sops
                home-manager.darwinModules.home-manager
                (mkHomeManagerModuleConfig {
                  inherit homeModule homeStateVersion;
                })
                {
                  system.stateVersion = systemStateVersion;
                }
                # impermanence.nixosModules.impermanence
              ] ++ systemModules;
            };
          mkNixosSystem = { systemStateVersion, homeStateVersion ? null
            , systemModules ? [ ./system/common/nixos.nix ]
            , homeModule ? import ./home-manager/common/nixos.nix }:
            nixpkgs.lib.nixosSystem {
              system = system;
              specialArgs = mkSpecialArgs;
              modules = [
                sops-nix.nixosModules.sops
                (nixpkgs.lib.optionalAttrs (homeStateVersion != null)
                  (home-manager.nixosModules.home-manager
                    (mkHomeManagerModuleConfig {
                      inherit homeModule homeStateVersion;
                    })))
                { system.stateVersion = systemStateVersion; }
                impermanence.nixosModules.impermanence
              ] ++ systemModules;
            };
        };
    in {
      nixosConfigurations = {

        live-iso = (withConfig {
          system = "x86_64-linux";
          derivationName = "live-iso";
          extraSpecialArgs = { inherit (inputs) nixpkgs; };
        }).mkNixosSystem {
          systemStateVersion = "24.05";
          systemModules = [ ./system/machines/live-iso/live-iso.nix ];
        };
        #   core = nixpkgs.lib.nixosSystem {
        #     system = "x86_64-linux";
        #     specialArgs = mkSpecialArgs;

        #     modules = [
        #       # Base
        #       ./system
        #       # ./system/steam.nix
        #       ./system/ssh.nix # For headless

        #       # Hardware
        #       ./machines/core
        #       nixpkgs.nixosModules.notDetected

        #       # Secrets
        #       sops-nix.nixosModules.sops
        #       ./sops
        #     ];

        #     # We'd use the following if we wanted to use home-manager as a nixos module,
        #     # as opposed to managing home-manager configurations as a separate flake.
        #     # home-manager.nixosModules.home-manager = {}
        #   };
      };

      darwinConfigurations = {

        smac = (withConfig {
          system = "aarch64-darwin";
          derivationName = "smac";
          username = "mmaurer7";
        }).mkDarwinSystem {
          systemStateVersion = 5;
          homeStateVersion = "22.05";
          homeModule = {
            imports = [ ./home-manager/common/mac.nix ];
            modules = {
              commonShell = {
                dirHashes = { box = "$HOME/Library/CloudStorage/Box-Box/"; };
              };
            };
          };
        };

        aspen = (withConfig {
          system = "aarch64-darwin";
          derivationName = "aspen";
        }).mkDarwinSystem {
          systemStateVersion = 5;
          homeStateVersion = "25.05";
        };
      };

      # For non-Nix machines: Manage home configurations as a separate flake.
      homeConfigurations = {
        "mac" = (withConfig {
          system = "aarch64-darwin";
          derivationName = "mac";
          username = "mjmaurer";
        }).mkHomeManagerStandalone {
          modules = [ ./home-manager/common/mac.nix ];
        };
        "linux" = (withConfig {
          system = "x86_64-linux";
          derivationName = "linux";
          username = "mjmaurer";
        }).mkHomeManagerStandalone {
          modules = [ ./home-manager/common/linux.nix ];
        };
      };

    } // forEachSystem ({ system, pkgs, sops-nix-pkgs }: {
      packages = import ./pkgs/pkgs.nix { inherit self pkgs; };
      devShells = import ./shell.nix { inherit pkgs sops-nix-pkgs; };
    });
}
