{
  config,
  lib,
  pkgs,
  derivationName,
  username,
  ...
}:
{

  imports = [];

  config = {
    modules.users.uid = 501;
    # Extra home modules to load.
    home-manager.users.${username} = {
      imports = [ ];
    };
  };
}
