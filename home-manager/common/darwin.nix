{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ../modules/karabiner/karabiner.nix ];

  # This might be set by the home-manager module for Darwin
  # This is kept for HM-only systems
  home.homeDirectory = lib.mkDefault "/Users/${config.home.username}";

  modules = {
    # TODO Could enable after: https://github.com/NixOS/nixpkgs/issues/366581
    firefox.enable = false;
    wayland.enable = false;
    intellibar.enable = lib.mkDefault true;
    commonShell = {
      enableShellTmuxTimeout = true;
      sessionVariables = {
        TERM = "xterm-256color";
      };
      shellAliases = {
        "la" = "ls -A -G --color=auto";
        "ls" = "ls -G --color=auto";
        # "code" = "open -a 'Visual Studio Code'";
        "nrbnoreload" = "darwin-rebuild switch --show-trace --flake ~/infra";
        # cd to top Finder window
        "cdf" = ''cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"'';
        "al" = "aerospace list-apps";
        "tssh" = "tailscale up && tailscale ssh";
      };
    };
  };

}
