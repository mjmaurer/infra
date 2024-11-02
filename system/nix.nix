{
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = false;
    allowUnsupportedSystem = false;
  };
  nix = {
    settings.trusted-users = [
      "mjmaurer"
      "root"
      # "@wheel"
    ];
    extraOptions = ''
      experimental-features = flakes nix-command
    '';
  };
}
