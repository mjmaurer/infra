{ lib, ... }:
{
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
}
