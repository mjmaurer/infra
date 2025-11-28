{ pkgs-latest, config, ... }:
let
  hostStateDir = "/var/lib/openwebui";
  containerStateDir = "/state";
in
{
  virtualisation.oci-containers.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:main";

    pull = "always";
    autoStart = true;
    autoRemoveOnStop = true;
    extraOptions = [ "--replace" ];

    ports = [ "0.0.0.0:8181:8181/tcp" ];
    volumes = [
      "${hostStateDir}:/app/backend/data"
    ];
    # environmentFiles = [ config.sops.templates."openwebui.env".path ];
    environment = {
      PORT = "8181";

      WEBUI_URL = "http://localhost:8181";

      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root -"
  ];

  # sops = {
  #   templates = {
  #     "openwebui.env" = {
  #       content = ''
  #         DEFAULT_USER_PASSWORD=${config.sops.placeholder.karaokeUserPassword}
  #         DJANGO_SECRET_KEY=${config.sops.placeholder.karaokeSecretKey}
  #       '';
  #     };
  #   };
  # };

  # modules.ai-secrets = {
  #   enableOpenrouter = true;
  #   enableGemini = true;
  #   enableOpenai = true;
  # };
}
