{
  description = "Michael Maurer's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    # Latest nixpkgs, to get latest versions of some packages
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-colors.url = "github:misterio77/nix-colors";
    nix-std.url = "github:chessai/nix-std";
    # impermanence.url = "github:nix-community/impermanence";

    darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    nix-vscode-extensions = {
      # https://github.com/nix-community/nix-vscode-extensions/issues/99
      url = "github:nix-community/nix-vscode-extensions";
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
      nixosHostnames = builtins.attrNames self.nixosConfigurations;
      sys = import ./lib/system.nix { inherit inputs nixosHostnames; };
    in
    {
      nixosConfigurations = {

        maple =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "maple";
            tags = [
              "linux"
            ];
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [
                ./system/machines/maple
                ./system/common/headed-minimal.nix
              ];
            };
        ash =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "ash";
            tags = [
              "linux"
              "nas-access"
              "dev-client"
            ];
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [
                ./system/machines/ash
                ./system/common/headed-minimal.nix
              ];
            };
        willow =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "willow";
            tags = [
              "linux"
              "dev-client"
            ];
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [
                ./system/machines/willow
                ./system/common/headed-minimal.nix
              ];
            };
        dove =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "dove";
            tags = [
              "linux"
            ];
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [
                ./system/machines/dove
                ./system/common/cloud.nix
              ];
            };
        bluejay =
          (sys.withConfig {
            system = "x86_64-linux";
            derivationName = "bluejay";
            tags = [
              "linux"
            ];
          }).mkNixosSystem
            {
              homeStateVersion = "25.05";
              systemStateVersion = "24.05";
              extraSystemModules = [
                ./system/machines/bluejay
                # ./system/common/cloud.nix
              ];
              defaultSystemModules = [
                ./system/common/nixos.nix
                ./system/modules/nix.nix
                ./system/modules/basic.nix
                ./system/modules/ssh.nix
                inputs.disko.nixosModules.disko
              ];
              defaultHomeModules = [ ];
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
            tags = [
              "darwin"
              "dev-client"
              "full-client"
            ];
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
            tags = [
              "darwin"
              "dev-client"
              "full-client"
            ];
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "25.05";
              extraSystemModules = [
                ./system/machines/aspen
              ];
            };

        default =
          (sys.withConfig {
            system = "aarch64-darwin";
            derivationName = builtins.getEnv "HOST";
            username = builtins.getEnv "USERNAME";
          }).mkDarwinSystem
            {
              systemStateVersion = 5;
              homeStateVersion = "25.05";
              extraSystemModules = [
                {
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
