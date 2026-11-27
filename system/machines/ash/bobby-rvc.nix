# Bobby's voice service (Applio RVC + audio-separator) on ash's GPU.
# Image: ghcr.io/mjmaurer/bobby-rvc, built by https://github.com/mjmaurer/bobby-bot.
# The bots run on maple (system/machines/maple/bobby.nix) and call http://ash:8001 over
# Tailscale. Follows :prod; modules.containerUpdater restarts it when that tag moves.
#
# Before deploying, add to ./secrets.yaml (`sops system/machines/ash/secrets.yaml`):
#   bobbyGhcrToken   GitHub token with read:packages (bobby-bot's images are private)
#
# Voices: copy trained RVC voices to /var/lib/bobby-rvc/voices/<name>/{*.pth,*.index}.
{
  config,
  ...
}:
let
  port = 8001;
  stateDir = "/var/lib/bobby-rvc";
in
{
  imports = [ ../../modules/container-updater.nix ];

  systemd.tmpfiles.rules = [
    "d ${stateDir} 0755 root root - -"
    "d ${stateDir}/voices 0755 root root - -"
  ];

  # Docker needs CDI enabled for --device=nvidia.com/gpu=all (see modules/graphics/nvidia.nix).
  virtualisation.docker.daemon.settings.features.cdi = true;

  virtualisation.oci-containers.containers.bobby-rvc = {
    image = "ghcr.io/mjmaurer/bobby-rvc:prod";
    pull = "always";
    login = {
      registry = "ghcr.io";
      username = "mjmaurer";
      passwordFile = config.sops.secrets.bobbyGhcrToken.path;
    };
    autoRemoveOnStop = true;
    # Reachable from maple over Tailscale (tailscale0 is a trusted interface).
    ports = [ "${toString port}:${toString port}" ];
    volumes = [ "${stateDir}/voices:/voices:ro" ];
    extraOptions = [
      "--replace"
      "--device=nvidia.com/gpu=all"
    ];
  };

  modules.containerUpdater.containers = [ "bobby-rvc" ];

  sops.secrets.bobbyGhcrToken.sopsFile = ./secrets.yaml;
}
