{ config, pkgs, lib, ... }:

{
  imports = [ ./linux.nix ];

  modules.commonShell = { };
}
