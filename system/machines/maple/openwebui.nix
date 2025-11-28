{ pkgs-latest, config, ... }:
{
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8181;
    stateDir = "/var/lib/open-webui";
    package = pkgs-latest.open-webui.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ [
        pkgs-latest.python3Packages.itsdangerous
      ];
    });
    environment = {
      # See https://github.com/NixOS/nixpkgs/pull/431395#issuecomment-3161532401
      FRONTEND_BUILD_DIR = "${config.services.open-webui.stateDir}/build";
      SENTENCE_TRANSFORMERS_HOME = "${config.services.open-webui.stateDir}/transformers_home";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
    openFirewall = false;
  };
}
