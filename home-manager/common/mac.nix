{ config, pkgs, lib, ... }:

{
  imports = [ ./_base.nix ./headed.nix ../modules/karabiner/karabiner.nix ];

  # This might be set by the home-manager module for Darwin
  # This is kept for HM-only systems
  home.homeDirectory = lib.mkDefault "/Users/${config.home.username}";

  modules = {
    obsidian = {
      enable = true;
      justConfig = true;
    };

    commonShell = {
      sessionVariables = { TERM = "xterm-256color"; };
      shellAliases = {
        "la" = "ls -A -G --color=auto";
        "ls" = "ls -G --color=auto";
        "code" = "open -a 'Visual Studio Code'";
        "nrbnoreload" = "darwin-rebuild switch --show-trace --flake ~/infra";
        # cd to top Finder window
        "cdf" = ''
          cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')"'';
        "al" = "aerospace list-apps";
      };
    };
  };

}
