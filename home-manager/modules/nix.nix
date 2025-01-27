{ lib, config, ... }:
let cfg = config.modules.nix;
in {
  options.modules.nix = {
    unfreePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = {
    nixpkgs = {
      config = {
        allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) cfg.unfreePackages;
      };
    };
    nix = {
      # This is also set for system in system/modules/nix.nix
      # We should probably move to top-level config
      gc = {
        # Friday at 7pm
        automatic = true;
        frequency = "weekly";
        options = lib.mkDefault "--delete-older-than 90d";
      };
    };
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
