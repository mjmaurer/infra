{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  cfg = config.modules.sops;
in
{

  options.modules.sops = {
    includePcSecrets = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
      description = "Include personal computer secrets.";
    };
  };

  config = {
    sops = lib.mkMerge [

      {
        # Generate age key based on SSH key to this path
        age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        age.keyFile = "/var/lib/sops-nix/key.txt";
        age.generateKey = true;

        # Not using host GPG keys, so unset default
        gnupg.sshKeyPaths = [ ];

        defaultSopsFile = ./secrets/common.yaml;
        secrets = {
          gpgAuthKeygrip = { };
          mjmaurerHashedPassword = {
            neededForUsers = true;
          };
        };
      }

      (lib.optionalAttrs cfg.includePcSecrets {
        secrets =
          let
            pcSopsFile = ./secrets/common-pc.yaml;
          in
          {
            smbHost = {
              sopsFile = pcSopsFile;
            };
            smbUrl = {
              sopsFile = pcSopsFile;
            };

            # TODO: probably want this via sops home-manager module,
            # but it does create issues with (permissions? I tried but can't remember the error)
            apiKeyAnthropic = {
              sopsFile = pcSopsFile;
            };
            apiKeyGemini = {
              sopsFile = pcSopsFile;
            };
            apiKeyCodestral = {
              sopsFile = pcSopsFile;
            };
            apiKeyVoyage = {
              sopsFile = pcSopsFile;
            };
            apiKeyOpenai = {
              sopsFile = pcSopsFile;
            };
            apiKeyDeepseek = {
              sopsFile = pcSopsFile;
            };
          };
        templates = {
          "shell.env" = {
            # mode = "0400";
            # group = config.users.groups.${username}.name;
            # restartUnits = [ "home-assistant.service" ];
            owner = config.users.users.${username}.name;
            content = ''
              export ANTHROPIC_API_KEY=${config.sops.placeholder.apiKeyAnthropic}
              export GEMINI_API_KEY=${config.sops.placeholder.apiKeyGemini}
              export CLAUDE_API_KEY=${config.sops.placeholder.apiKeyAnthropic}
              export CODESTRAL_API_KEY=${config.sops.placeholder.apiKeyCodestral}
              export VOYAGE_API_KEY=${config.sops.placeholder.apiKeyVoyage}
              export OPENAI_API_KEY=${config.sops.placeholder.apiKeyOpenai}
              export DEEPSEEK_API_KEY=${config.sops.placeholder.apiKeyDeepseek}
            '';
          };
          "gpg_sshcontrol" = {
            owner = config.users.users.${username}.name;
            content = ''
              ${config.sops.placeholder.gpgAuthKeygrip}

            '';
            # Newlines in 'content' are needed!
          };
        };
      })
    ];
  };
}
