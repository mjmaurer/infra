{ config, username, ... }:
{
  users.groups.nas = { };

  users.users.${username}.extraGroups = [
    config.users.groups.nas.name
  ];
}
