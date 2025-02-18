{ lib, username, config, isDarwin, stdenv, pkgs, ... }:
let
  isNixOS = !isDarwin;
  cfg = config.modules.kanata;
  macAppDir = "/Applications/.Nix-Karabiner";
  deamonLaunchdName = "kanata_daemons";
  karabiner-package = import ./karabiner-driver.nix { inherit pkgs lib; };
  kanataPath = "${config.modules.homebrew.brewPrefix}/kanata";
  kanataPerm = "NOPASSWD";
in {
  options.modules.kanata = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable kanata";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [

    (lib.optionalAttrs isNixOS {
      # Might need https://dev.to/shanu-kumawat/how-to-set-up-kanata-on-nixos-a-step-by-step-guide-1jkc
      services.kanata = {
        enable = true;
        configFile = ./kanata.kdb;
      };
    })

    (lib.optionalAttrs isDarwin {
      environment.systemPackages = [
        # These aren't loaded in path for some reason https://github.com/LnL7/nix-darwin/issues/521
        (pkgs.writeShellScriptBin "kanload" ''
          sudo launchctl load -w /Library/LaunchDaemons/org.nixos.kanata_daemons.plist
        '')
        (pkgs.writeShellScriptBin "kanunload" ''
          sudo launchctl unload /Library/LaunchDaemons/org.nixos.kanata_daemons.plist
        '')
        (pkgs.writeShellScriptBin "kanrun" ''
          sudo kanata --debug -c ~/infra/system/modules/kanata/kanata.kdb
        '')
        (pkgs.writeShellScriptBin "kankill" ''
          sudo kill -9 $(sudo pgrep -f "^sudo kanata") 
        '')
      ];

      security.sudo.extraConfig = ''
        ${username} ALL=(ALL) ${kanataPerm}: ${kanataPath}
      '';

      # TODO: replace brew with nixpkgs after https://github.com/NixOS/nixpkgs/pull/334243
      modules.homebrew.extraFormulas = [ "kanata" ];
      # environment.systemPackages = [ cfg.karabiner-package ]; # cfg.package ];

      # NOTE: Remember to give "Accessability" and "Input Monitoring" perm sto kanata exe: 
      launchd.daemons.${deamonLaunchdName} = {
        # script = '' 
        # sudo ${macAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
        command = "${kanataPath} -c ${./kanata.kdb}";
        # command = "echo ${./kanata.kdb}";
        serviceConfig.ProcessType = "Interactive";
        serviceConfig.Label = "org.nixos.${deamonLaunchdName}";
        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive = true;
        serviceConfig.StandardOutPath = "/Library/Logs/Kanata/out.log";
        serviceConfig.StandardErrorPath = "/Library/Logs/Kanata/error.log";
    };

      launchd.daemons.start_kanata_daemons = {
        script = ''
            ${macAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
            # launchctl kickstart system/org.nixos.${deamonLaunchdName}
        '';
        serviceConfig.Label = "org.nixos.start_kanata_daemons";
        serviceConfig.RunAtLoad = true;
        serviceConfig.StandardOutPath = "/Library/Logs/Kanata-Starter/out.log";
        serviceConfig.StandardErrorPath = "/Library/Logs/Kanata-Starter/error.log";
      };

      # system.activationScripts.postActivation.text = ''
      #   echo "Reloading kanata daemons" >&2
      #   sudo launchctl unload /Library/LaunchDaemons/org.nixos.start_kanata_daemons.plist
      #   sudo launchctl load -w /Library/LaunchDaemons/org.nixos.start_kanata_daemons.plist
      # '';

      launchd.daemons.Karabiner-DriverKit-VirtualHIDDevice-Daemon = {
        # NOTE: The quotes are important here so spaces get handled correctly
        command = ''
          "${karabiner-package.driver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"'';
        serviceConfig.ProcessType = "Interactive";
        serviceConfig.Label = "org.pqrs.Karabiner-VirtualHIDDevice-Daemon";
        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive = true;
        serviceConfig.StandardOutPath =
          "/Library/Logs/Karabiner-Driverkit-Daemon/out.log";
        serviceConfig.StandardErrorPath =
          "/Library/Logs/Karabiner-Driverkit-Daemon/error.log";
      };

      # The karabiner driver config is ripped from (but changed client to daemon):
      # https://github.com/LnL7/nix-darwin/blob/master/modules/services/karabiner-elements/default.nix
      system.activationScripts.preActivation.text = ''
        # Copy manager to applications
        # Kernel extensions must reside inside of /Applications, they cannot be symlinks
        rm -rf ${macAppDir}
        mkdir -p ${macAppDir}
        cp -r ${karabiner-package.driver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app ${macAppDir}
      '';

      # Normally karabiner_console_user_server calls activate on the manager but
      # because we use a custom location we need to call activate manually.
      launchd.user.agents.activate_karabiner_system_ext = {
        # This needs to be kept somewhat in-sync with the version required by kanata
        serviceConfig.ProgramArguments = [
          "${macAppDir}/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
          "activate"
        ];
        serviceConfig.RunAtLoad = true;
        serviceConfig.StandardOutPath =
          "/Users/${username}/Library/Logs/Karabiner-activate/out.log";
        serviceConfig.StandardErrorPath =
          "/Users/${username}/Library/Logs/Karabiner-activate/error.log";
      };
    })
  ]);
}
