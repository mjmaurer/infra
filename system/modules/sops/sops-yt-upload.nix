{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  sopsFile = ./secrets/yt-upload.yaml;
in
{
  home-manager.users.${username}.imports = [
    (
      {
        config,
        osConfig,
        ...
      }:
      {
        home.file.".config/youtubeuploader/client_secret.json" = {
          source = config.lib.file.mkOutOfStoreSymlink osConfig.sops.templates."yt-client-secret.json".path;
        };
      }
    )
  ];

  sops = {
    secrets = {
      ytClientId = {
        sopsFile = sopsFile;
      };
      ytClientSecret = {
        sopsFile = sopsFile;
      };
      ytProjectId = {
        sopsFile = sopsFile;
      };
    };
    templates = {
      "yt-client-secret.json" = {
        owner = config.users.users.${username}.name;
        content = builtins.toJSON {
          web = {
            client_id = config.sops.placeholder.ytClientId;
            client_secret = config.sops.placeholder.ytClientSecret;
            project_id = config.sops.placeholder.ytProjectId;
            auth_uri = "https://accounts.google.com/o/oauth2/auth";
            token_uri = "https://oauth2.googleapis.com/token";
            auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs";
            redirect_uris = [ "http://localhost:8080/oauth2callback" ];
          };
        };
      };
    };
  };
}
