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

  home.activation.postSwitchAddApplications = let
    scriptName = "post-switch-add-applications.sh";
    postSwitchAddScript = pkgs.writeShellScript scriptName ''
      #!/usr/bin/env bash

      # From https://github.com/NixOS/nix/issues/956#issuecomment-1367457122
      # Could instead try: https://github.com/LnL7/nix-darwin/blob/master/modules/system/applications.nix
      # Install all nix top level graphical apps
      # if [[ -d ~/.nix-profile/Applications ]]; then
      # 	(cd ~/.nix-profile/Applications;
      # 	for f in *.app ; do
      #     f_without_extension="''${f%%.app}"
      # 		mkdir -p ~/Applications/
      #     echo "Adding $f to ~/Applications/"
      # 		# Remove existing symlink if it exists
      # 		rm -f "$HOME/Applications/$f_without_extension"
      #     sleep 0.2
      # 		# Mac aliases don’t work on symlinks
      # 		f="$(readlink -f "$f")"
      # 		# Use Mac aliases because Spotlight / Alfred doesn’t like symlinks
      # 		/usr/bin/osascript -e "tell app \"Finder\" to make new alias file at POSIX file \"$HOME/Applications\" to POSIX file \"$f\""
      # 	done
      # 	)
      # fi
    '';
    postSwitchAddScriptRsync = pkgs.writeShellScript scriptName ''
    '';
    # `run` is used to obey Nix dry run 
  in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # run ${postSwitchAddScriptRsync} 
    #!/usr/bin/env bash
    # From https://github.com/LnL7/nix-darwin/issues/214

    # apps_source="$HOME/Applications/Home Manager Apps"
    apps_source="$genProfilePath/home-path/Applications"
    # Darwin: apps_source="{config.system.build.applications}/Applications"
    moniker="Nix Trampolines"
    app_target_base="$HOME/Applications"
    app_target="$app_target_base/$moniker"
    mkdir -p "$app_target"
    echo "Copying apps from $apps_source to $app_target"
    ${pkgs.rsync}/bin/rsync --archive --checksum --chmod=-w --copy-unsafe-links --delete "$apps_source/" "$app_target"
  '';
}
