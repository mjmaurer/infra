{ config, pkgs, lib, ... }:

{
  imports = [ ./base.nix ];

  home.homeDirectory = "/Users/${config.home.username}";

  modules = {
    obsidian = {
      enable = true;
      justConfig = true;
    };
    aerospace = {
      enable = true;
      justConfig = true;
    };
    karabiner = {
      enable = true;
      justConfig = true;
    };

    commonShell = {
      sessionVariables = { MACHINE_NAME = "smac"; TERM = "xterm-256color"; };
      shellAliases = {
        "la" = "ls -A -G --color=auto";
        "ls" = "ls -G --color=auto";
        "code" = "open -a 'Visual Studio Code'";
      };
    };
  };

  home.activation.postSwitchAddApplications =
    let
      scriptName = "post-switch-add-applications.sh";
      postSwitchAddScript = pkgs.writeShellScript scriptName ''
        #!/usr/bin/env bash

        # From https://github.com/NixOS/nix/issues/956#issuecomment-1367457122
        # Install all nix top level graphical apps
        if [[ -d ~/.nix-profile/Applications ]]; then
        	(cd ~/.nix-profile/Applications;
        	for f in *.app ; do
            f_without_extension="''${f%%.app}"
        		mkdir -p ~/Applications/
            echo "Adding $f to ~/Applications/"
        		# Remove existing symlink if it exists
        		rm -f "$HOME/Applications/$f_without_extension"
            sleep 0.2
        		# Mac aliases don’t work on symlinks
        		f="$(readlink -f "$f")"
        		# Use Mac aliases because Spotlight doesn’t like symlinks
        		osascript -e "tell app \"Finder\" to make new alias file at POSIX file \"$HOME/Applications\" to POSIX file \"$f\""
        	done
        	)
        fi
      '';
    in
    # `run` is used to obey Nix dry run 
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${postSwitchAddScript} 
    '';
}
