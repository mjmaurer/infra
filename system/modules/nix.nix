{
  lib,
  username,
  isDarwin,
  ...
}:
{
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = false;
  };
  nix = {
    settings = {
      trusted-users = [
        username
        "root"
        # "@wheel" Darwin doesn't like this maybe?
      ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';

    # This is also set for HM in home-manager/common/_base.nix
    # We should probably move to top-level config
    gc =
      {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 90d";
      }
      // (
        # Friday at 7pm
        if isDarwin then
          {
            interval = {
              Weekday = 5;
              Hour = 19;
              Minute = 0;
            };
          }
        else
          {
            dates = [ "Fri 19:00" ];
          }
      );

    optimise =
      {
        automatic = lib.mkDefault true;
      }
      // (
        # Saturday at 7pm
        if isDarwin then
          {
            interval = {
              Weekday = 6;
              Hour = 19;
              Minute = 0;
            };
          }
        else
          {
            dates = [ "Sat 19:00" ];
          }
      );

    # Opinionated: disable channels
    # channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    # registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
