{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
    # See: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    # for recommendations on how to manage nixpkgs versions.

    # Default to the nixos-unstable branch:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Latest nixpkgs, to get latest versions of some packages
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";

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
      # https://github.com/nix-community/nix-vscode-extensions/issues/99
      url = "github:nix-community/nix-vscode-extensions/780a1d35ccd6158ed2c7d10d87c02825e97b4c89";
      # Need to update nixpkgs-latest at the same time anyway
      inputs.nixpkgs.follows = "nixpkgs-latest";
      inputs.flake-utils.follows = "flake-utils";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Build our own wsl
    # https://github.com/dmadisetti/.dots/blob/template/flake.nix
    # nixos-wsl.url = github:nix-community/NixOS-WSL;
    # nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    # nixos-wsl.inputs.flake-utils.follows = "flake-utils";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-latest,
      home-manager,
      nixos-hardware,
      sops-nix,
      nix-colors,
      nix-std,
      nix-homebrew,
      impermanence,
      flake-utils,
      darwin,
      disko,
      nix-vscode-extensions,
      ...
    }@inputs:
    let
      defaultUsername = "mjmaurer";
      forEachSystem =
        f:
        flake-utils.lib.eachDefaultSystem (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            sops-nix-pkgs = sops-nix.packages.${system};
            lib = nixpkgs.lib;
          in
          f {
            inherit
              system
              pkgs
              sops-nix-pkgs
              lib
              ;
          }
        );
      withConfig =
        {
          system,
          derivationName,
          username ? defaultUsername,
          extraSpecialArgs ? { },
        }:
        rec {
          mkSpecialArgs = {
            # The `specialArgs` parameter passes the
            # non-default arguments to nix modules.
            # Default arguments are things like `pkgs`, `lib`, etc.

            inherit (inputs)
              nix-std
              nix-colors
              nix-vscode-extensions
              nix-homebrew
              ;
            inherit username derivationName system;

            pkgs-latest = import nixpkgs-latest {
              inherit system;
              config = {
                allowUnfree = true;
                allowUnfreePredicate = (pkg: true);
              };
            };
            colors = import ./lib/colors.nix { lib = nixpkgs.lib; };
            pubkeys = import ./lib/pubkeys.nix;
            isDarwin = system == "aarch64-darwin";
          } // extraSpecialArgs;
          mkHomeManagerStandalone =
            {
              modules ? [ ],
            }:
            home-manager.lib.homeManagerConfiguration {
              extraSpecialArgs = mkSpecialArgs;
              # See here on legacyPackages vs import:
              # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
              pkgs = nixpkgs.legacyPackages.${system};
              modules = modules;
            };
          mkHomeManagerModuleConfig =
            {
              defaultHomeModules,
              extraHomeModules,
              homeStateVersion,
            }:
            {
              # Keep these false so home-manager and nixos derivations don't diverge.
              # By default, Home Manager uses a private pkgs instance via `home-manager.users.<name>.nixpkgs`.
              # To instead use the global (system-level) pkgs, set to true.
              home-manager.useGlobalPkgs = true;
              # Packages installed to `$HOME/.nix-profile` if true, otherwise `/etc/profiles/`.
              home-manager.useUserPackages = false;
              home-manager.extraSpecialArgs = mkSpecialArgs;
              home-manager.backupFileExtension = "home-manager-existing-backup";
              # home-manager.verbose = true;
              home-manager.users.${username} = {
                imports = defaultHomeModules ++ extraHomeModules;
              };
              home-manager.sharedModules = [
                { home.stateVersion = homeStateVersion; }
                sops-nix.homeManagerModules.sops
              ];
            };
          mkDarwinSystem =
            {
              systemStateVersion,
              homeStateVersion,
              defaultSystemModules ? [
                ./system/common/darwin.nix
                sops-nix.darwinModules.sops
                # impermanence.nixosModules.impermanence
              ],
              extraSystemModules ? [ ],
              defaultHomeModules ? [
                ./home-manager/common/darwin.nix
                ./home-manager/common/headed.nix
              ],
              extraHomeModules ? [ ],
            }:
            darwin.lib.darwinSystem {
              system = if system == "aarch64-darwin" then system else throw "System must be aarch64-darwin";
              specialArgs = mkSpecialArgs;
              modules =
                [
                  home-manager.darwinModules.home-manager
                  (mkHomeManagerModuleConfig {
                    inherit defaultHomeModules extraHomeModules homeStateVersion;
                  })
                  {
                    system.stateVersion = systemStateVersion;
                  }
                ]
                ++ defaultSystemModules
                ++ extraSystemModules;
            };
          mkNixosSystem =
            {
              systemStateVersion,
              homeStateVersion ? null,
              defaultSystemModules ? [
                ./system/common/nixos.nix
                ./system/common/headed-minimal.nix
                sops-nix.nixosModules.sops
                disko.nixosModules.disko
                # impermanence.nixosModules.impermanence
              ],
              extraSystemModules ? [ ],
              defaultHomeModules ? [
                ./home-manager/common/nixos.nix
                ./home-manager/common/headed-minimal.nix
              ],
              extraHomeModules ? [ ],
            }:
            nixpkgs.lib.nixosSystem {
              system = system;
              specialArgs = mkSpecialArgs;
              modules =
                (nixpkgs.lib.optionals (homeStateVersion != null) [
                  home-manager.nixosModules.home-manager
                  (mkHomeManagerModuleConfig {
                    inherit defaultHomeModules extraHomeModules homeStateVersion;
                  })
                ])
                ++ [
                  {
                    system.stateVersion = systemStateVersion;
                  }
                ]
                ++ defaultSystemModules
                ++ extraSystemModules;
            };
        };
    in
    {
      nixosConfigurations = {

        maple =
          (withConfig {
            system = "x86_64-linux";
            derivationName = "maple";
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [ ./system/machines/maple ];
            };

        live-iso =
          (withConfig {
            system = "x86_64-linux";
            derivationName = "live-iso";
            extraSpecialArgs = { inherit (inputs) nixpkgs; };
          }).mkNixosSystem
            {
              homeStateVersion = null;
              systemStateVersion = "24.05";
              # live-iso doesn't inherit _base.nix or nixos.nix modules,
              # so override default to keep from accidently including them in the ISO
              defaultSystemModules = [ ./system/machines/live-iso/live-iso.nix ];
            };
      };

      darwinConfigurations = {

        smac =
          (withConfig {
            system = "aarch64-darwin";
            derivationName = "smac";
            username = "mmaurer7";
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "22.05";
              extraHomeModules = [
                {
                  modules = {
                    commonShell = {
                      dirHashes = {
                        box = "$HOME/Library/CloudStorage/Box-Box/";
                      };
                    };
                  };
                }
              ];
            };

        aspen =
          (withConfig {
            system = "aarch64-darwin";
            derivationName = "aspen";
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "25.05";
            };
      };

      # For non-Nix machines: Manage home configurations as a separate flake.
      homeConfigurations = {
        "mac" =
          (withConfig {
            system = "aarch64-darwin";
            derivationName = "mac";
            username = "mjmaurer";
          }).mkHomeManagerStandalone
            {
              modules = [
                ./home-manager/common/darwin.nix
                ./home-manager/common/headed.nix
              ];
            };
        "linux" =
          (withConfig {
            system = "x86_64-linux";
            derivationName = "linux";
            username = "mjmaurer";
          }).mkHomeManagerStandalone
            {
              modules = [
                ./home-manager/common/linux.nix
                ./home-manager/common/headed.nix
              ];
            };
      };

    }
    // forEachSystem (
      {
        system,
        pkgs,
        sops-nix-pkgs,
        lib,
      }:
      {
        packages = import ./ad-hoc/pkgs { inherit self pkgs; };
        devShells = import ./ad-hoc/shells { inherit pkgs sops-nix-pkgs lib; };
      }
    );
}
