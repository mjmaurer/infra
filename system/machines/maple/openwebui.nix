{ pkgs-latest, config, ... }:
let
  hostStateDir = "/var/lib/open-webui";
  containerStateDir = "/state";
in
{
  virtualisation.oci-containers.containers."open-webui" = {
    image = "ghcr.io/open-webui/open-webui:latest";

    pull = "always";
    autoStart = true;
    autoRemoveOnStop = true;
    extraOptions = [ "--replace" ];

    ports = [ "0.0.0.0:8181:8181/tcp" ];
    volumes = [
      "${hostStateDir}:${containerStateDir}"
    ];
    environment = {
      PORT = "8181";
      FRONTEND_BUILD_DIR = "${containerStateDir}/build";
      SENTENCE_TRANSFORMERS_HOME = "${containerStateDir}/transformers_home";
      STATIC_DIR = "${containerStateDir}/static";
      DATA_DIR = "${containerStateDir}/data";

      WEBUI_URL = "http://localhost:8181";

      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${hostStateDir} 0755 root root -"
    "d ${hostStateDir}/data 0755 root root -"
    "d ${hostStateDir}/build 0755 root root -"
    "d ${hostStateDir}/transformers_home 0755 root root -"
    "d ${hostStateDir}/static 0755 root root -"
  ];
}
