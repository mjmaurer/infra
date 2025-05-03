{
  lib,
  config,
  pkgs,
  ...
}:
let
  # aerospace = pkgs.aerospace;
  aerospace = import ./deriv.nix {
    inherit pkgs lib;
  };
in
{
  environment.systemPackages = [ aerospace ];

  # home.file = {
  #   ".config/aerospace/aerospace.toml" = { source = ./aerospace.toml; };
  #   ".local/bin/tmux-match-focus-vscode.sh" = {
  #     source = ./match-focus.sh;
  #     executable = true;
  #   };
  # };

  launchd.user.agents.aerospace = {
    command = "${aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path ${./aerospace.toml}";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
    };
  };
}
