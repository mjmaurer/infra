{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
    # You can also use a specific git commit hash to lock the version:
    # nixpkgs-fd40cef8d.url = "github:nixos/nixpkgs/fd40cef8d797670e203a27a91e4b8e6decf0b90c";
    # See: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/downgrade-or-upgrade-packages
    # for recommendations on how to manage nixpkgs versions.
    # Default to the nixos-unstable branch:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Latest stable branch of nixpkgs, used for version rollback:
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

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

  };
  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , home-manager
    , nixos-hardware
    , sops-nix
    , nix-colors
    , nix-std
    , nix-homebrew
    , impermanence
    , flake-utils
    , darwin
    , ...
    } @ inputs:
    let
      defaultUsername = "mjmaurer";
      withConfig =
        { system
        , derivationName
        , username ? defaultUsername
        }: rec {
          mkSpecialArgs = {
            # The `specialArgs` parameter passes the
            # non-default arguments to nix modules.
            # Default arguments are things like `pkgs`, `lib`, etc.

            inherit inputs username derivationName;
            pkgs-stable = nixpkgs-stable.legacyPackages.${system};
            colors = import ./lib/colors.nix {
              lib = nixpkgs.lib;
            };
            isDarwin = system == "aarch64-darwin";
          };
          mkHomeManagerStandalone =
            { modules ? [ ] }: home-manager.lib.homeManagerConfiguration {
              extraSpecialArgs = mkSpecialArgs;
              # See here on legacyPackages vs import: 
              # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
              pkgs = nixpkgs.legacyPackages.${system};
              modules = modules;
            };
          mkDarwinSystem =
            { systemStateVersion
            , homeStateVersion
            , systemModules ? [ ]
            , homeModule ? import ./home-manager/common/mac.nix
            }: darwin.lib.darwinSystem {

              system = "aarch64-darwin";
              specialArgs = mkSpecialArgs;
              modules = [
                ./system/common/darwin.nix
                home-manager.darwinModules.home-manager
                {
                  # Keep these false so home-manager and nixos derivations don't diverge.
                  # By default, Home Manager uses a private pkgs instance via `home-manager.users.<name>.nixpkgs`.
                  # To instead use the global (system-level) pkgs, set to true.
                  home-manager.useGlobalPkgs = false;
                  # Packages installed to `$HOME/.nix-profile` if true, otherwise `/etc/profiles/`.
                  home-manager.useUserPackages = false;
                  home-manager.extraSpecialArgs = mkSpecialArgs;
                  home-manager.users.${username} = homeModule;
                  home-manager.sharedModules = [
                    {
                      home.stateVersion = homeStateVersion;
                    }
                  ];
                }
                {
                  system.stateVersion = systemStateVersion;
                }
                # impermanence.nixosModules.impermanence
              ] ++ systemModules;
            };
        };
    in
    {
      # nixosConfigurations = {
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
      # };

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
              git.signingKey = "33EBB38F3D20DBB8";
              commonShell = {
                machineName = "smac";
                dirHashes = {
                  box = "$HOME/Library/CloudStorage/Box-Box/";
                };
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


      inherit (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # nix home-manager git
            # sops ssh-to-age gnupg age
          ];
          shellHook = ''
            export NIX_CONFIG="extra-experimental-features = nix-command flakes ca-derivations";
          '';
        };
      })) devShells;
    };
}
