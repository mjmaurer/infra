{ pkgs-latest, config, ... }:
{
  services.open-webui = {
    enable = true;
    port = 8181;
    stateDir = "/var/lib/open-webui";
    package = pkgs-latest.open-webui.overridePythonAttrs (old: {
      dependencies = old.dependencies ++ [
        pkgs-latest.python3Packages.itsdangerous
      ];
    });
    environment = {
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };
    openFirewall = true;
  };
}
