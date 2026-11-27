# Restarts selected oci-containers whose image tag points at a new image, every few minutes.
# Works with both backends (docker on ash, podman on maple). Unlike
# modules.virt.podmanAutoUpdate (weekly, all labeled podman containers), this only touches the
# listed containers and runs often, for images you publish yourself (e.g. bobby-bot's :dev/:prod).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.containerUpdater;
  backend = config.virtualisation.oci-containers.backend;
  cli = if backend == "podman" then "${pkgs.podman}/bin/podman" else "${pkgs.docker}/bin/docker";
in
{
  options.modules.containerUpdater = {
    containers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Names of virtualisation.oci-containers.containers to keep on their tag's latest image.";
    };
    interval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "How often to check (systemd time span).";
    };
  };

  config = lib.mkIf (cfg.containers != [ ]) {
    systemd.services.container-updater = {
      description = "Restart containers whose image tag moved";
      after = [ "${backend}.service" ];
      requires = [ "${backend}.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        for container in ${lib.concatStringsSep " " cfg.containers}; do
          image=$(${cli} inspect -f '{{.Config.Image}}' "$container" 2>/dev/null) || continue
          ${cli} pull -q "$image" >/dev/null || { echo "pull failed: $image"; continue; }
          latest=$(${cli} image inspect -f '{{.Id}}' "$image")
          running=$(${cli} inspect -f '{{.Image}}' "$container")
          if [ "$latest" != "$running" ]; then
            echo "$container: new image for $image, restarting"
            systemctl restart "${backend}-$container.service"
          fi
        done
      '';
    };
    systemd.timers.container-updater = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = cfg.interval;
        OnUnitActiveSec = cfg.interval;
      };
    };
  };
}
