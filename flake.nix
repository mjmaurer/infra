{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
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
    { self, ... }@inputs:
    let
      sys = import ./lib/system.nix { inherit inputs; };
    in
    {
      nixosConfigurations = {

        maple =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "maple";
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [ ./system/machines/maple ];
            };

        live-iso =
          (sys.withConfig {
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
          (sys.withConfig {
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
          (sys.withConfig {
            system = "aarch64-darwin";
            derivationName = "aspen";
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "25.05";
            };

        default =
          (sys.withConfig {
            system = "aarch64-darwin";
            derivationName = "default";
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "25.05";
              extraSystemModules = [
                {
                  modules.smbClient.enable = false;
                  modules.homebrew.enable = false;
                  modules.darwin.enable = false;
                }
              ];
            };
      };

      # For non-Nix machines: Manage home configurations as a separate flake.
      homeConfigurations = {
        "mac" =
          (sys.withConfig {
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
          (sys.withConfig {
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
    // sys.forEachSystem (
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
