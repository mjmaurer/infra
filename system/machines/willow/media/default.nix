{
  imports = [
    ./options.nix
    ./filesystem.nix
    ./containers.nix
  ];

  config.modules.mediaStack.enableContainers = false;
}
