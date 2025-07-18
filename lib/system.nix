{ inputs, nixosHostnames, ... }:
rec {
  defaultUsername = "mjmaurer";
  forEachSystem =
    f:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        sops-nix-pkgs = inputs.sops-nix.packages.${system};
        lib = inputs.nixpkgs.lib;
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
      mkSpecialArgs = rec {
        # The `specialArgs` parameter passes the
        # non-default arguments to nix modules.
        # Default arguments are things like `pkgs`, `lib`, etc.

        inherit (inputs)
          nix-std
          nix-colors
          nix-vscode-extensions
          nix-homebrew
          ;
        inherit
          username
          derivationName
          system
          nixosHostnames
          ;

        pkgs-latest = import inputs.nixpkgs-latest {
          inherit system;
          config = {
            allowUnfree = true;
            allowUnfreePredicate = (pkg: true);
          };
          overlays = [
            inputs.nix-vscode-extensions.overlays.default

            # (self: super: {
            #   python3Packages = super.python3Packages // {
            #     aider-chat = super.python3Packages.aider-chat.overridePythonAttrs (old: {
            #       dependencies = old.dependencies ++ [
            #         super.python3Packages.google-generativeai
            #       ];
            #     });
            #   };
            # })
          ];
        };
        colors = import ./colors.nix { lib = inputs.nixpkgs.lib; };
        pubkeys = import ./pubkeys.nix;
        isDarwin = system == "aarch64-darwin";
      } // extraSpecialArgs;
      mkHomeManagerStandalone =
        {
          modules ? [ ],
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          extraSpecialArgs = mkSpecialArgs;
          # See here on legacyPackages vs import:
          # https://discourse.nixos.org/t/using-nixpkgs-legacypackages-system-vs-import/17462/8
          pkgs = inputs.nixpkgs.legacyPackages.${system};
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
          # Effectively if true: you want to use the same overlays and settings for both home-manager and NixOS,
          # and don’t want to have to repeat the configuration.
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
            inputs.sops-nix.homeManagerModules.sops
          ];
        };
      mkDarwinSystem =
        {
          systemStateVersion,
          homeStateVersion,
          defaultSystemModules ? [
            ../system/common/darwin.nix
            inputs.sops-nix.darwinModules.sops
            # impermanence.nixosModules.impermanence

            ./common.nix
          ],
          extraSystemModules ? [ ],
          defaultHomeModules ? [
            ../home-manager/common/darwin.nix
            ../home-manager/common/headed.nix
          ],
          extraHomeModules ? [ ],
        }:
        inputs.darwin.lib.darwinSystem {
          system = if system == "aarch64-darwin" then system else throw "System must be aarch64-darwin";
          specialArgs = mkSpecialArgs;
          modules =
            [
              inputs.home-manager.darwinModules.home-manager
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
            ../system/common/nixos.nix
            inputs.sops-nix.nixosModules.sops
            inputs.disko.nixosModules.disko

            # The ordering of impermanence, sops (for user password) and ssh was making it very
            # hard to get this working. Especially considering I need to support
            # initial install and future rebuilds.
            # See: https://github.com/Mic92/sops-nix/issues/149
            # ../system/modules/impermanence.nix
            # inputs.impermanence.nixosModules.impermanence

            ./common.nix
          ],
          extraSystemModules ? [ ],
          defaultHomeModules ? [
            ../home-manager/common/nixos.nix
            ../home-manager/common/headed-minimal.nix
          ],
          extraHomeModules ? [ ],
        }:
        inputs.nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = mkSpecialArgs;
          modules =
            (inputs.nixpkgs.lib.optionals (homeStateVersion != null) [
              inputs.home-manager.nixosModules.home-manager
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
}
