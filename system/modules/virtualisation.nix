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
    withPodman = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Podman support";
    };
    withDocker = lib.mkEnableOption "Docker support";

    enableNvidia = lib.mkEnableOption "Enable NVIDIA GPU support for containers";
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
        dockerCompat = true;
        autoPrune.enable = true;
      };
    };

    assertions = [
      {
        assertion = !(cfg.withPodman && cfg.withDocker);
        message = "Only one of modules.virt.withPodman or modules.virt.withDocker can be enabled at the same time.";
      }
    ];
  };
}
