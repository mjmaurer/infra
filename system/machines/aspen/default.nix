{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
{

  imports = [
    ../../modules/sops/sops-yt-upload.nix
  ];

  config = {
    # Extra home modules to load.
    home-manager.users.${username} = {
      imports = [ ];
    };
  };
}
