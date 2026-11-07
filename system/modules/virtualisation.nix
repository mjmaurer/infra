{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.virt;
in
{
  options.modules.virt = {
    # Podman might have acl problems with zfs: https://blog.dest-unreach.be/2024/01/03/podman-on-zfs/
    withPodman = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Podman support";
    };
    withDocker = lib.mkEnableOption "Docker support";

    enableNvidia = lib.mkEnableOption "Enable NVIDIA GPU support for containers";

    # Enables the podman-auto-update.timer/.service that ship with podman. For each
    # container labeled io.containers.autoupdate=registry, it pulls a newer image
    # if one exists, restarts only that container's unit, and rolls back to the
    # old image if the unit fails to start. The service then prunes old images.
    # Containers opt in with: labels."io.containers.autoupdate" = "registry";
    # Check what it would do with: podman auto-update --dry-run
    podmanAutoUpdate = {
      enable = lib.mkEnableOption "scheduled podman auto-update of labeled containers";
      onCalendar = lib.mkOption {
        type = lib.types.str;
        default = "Mon *-*-* 06:00:00 America/New_York";
        description = "systemd OnCalendar expression for the auto-update run.";
      };
    };
  };

  config = {
    environment.systemPackages = lib.mkIf cfg.withPodman [
      pkgs.podman-tui
    ];

    virtualisation = {
      oci-containers.backend = if cfg.withPodman then "podman" else "docker";

      podman = lib.mkIf cfg.withPodman {
        enable = true;
        enableNvidia = cfg.enableNvidia;
        defaultNetwork.settings.dns_enabled = true;
        dockerCompat = !cfg.withDocker;
        autoPrune.enable = true;
      };

      docker = lib.mkIf cfg.withDocker {
        enable = true;
        enableNvidia = cfg.enableNvidia;
        autoPrune.enable = true;
      };
    };

    systemd.timers.podman-auto-update = lib.mkIf (cfg.withPodman && cfg.podmanAutoUpdate.enable) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # The empty string clears the shipped OnCalendar=daily before setting ours.
        OnCalendar = [
          ""
          cfg.podmanAutoUpdate.onCalendar
        ];
        RandomizedDelaySec = 0;
        Persistent = true; # run at next boot if the host was off at the scheduled time
      };
    };

    assertions = [
      {
        assertion = !(cfg.withPodman && cfg.withDocker);
        message = "Only one of modules.virt.withPodman or modules.virt.withDocker can be enabled at the same time.";
      }
      {
        assertion = cfg.podmanAutoUpdate.enable -> cfg.withPodman;
        message = "modules.virt.podmanAutoUpdate requires modules.virt.withPodman.";
      }
    ];
  };
}
