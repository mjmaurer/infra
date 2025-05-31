{
  config,
  pkgs,
  username,
  lib,
  ...
}:
let
  cfg = config.modules.sops;
  minimalSopsFile = ./secrets/minimal.yaml;
  fullSopsFile = ./secrets/full.yaml;
in
{

  options.modules.sops = {
    enableFullSecrets = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
      description = "Include personal computer secrets.";
    };
    enableMinimalSecrets = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include minimal secrets.";
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
        templates = {
          "llm-keys-common" = {
            owner = config.users.users.${username}.name;
            content = builtins.toJSON {
              gemini = config.sops.placeholder.apiKeyGemini;
            };
          };
        };
      }

      (lib.optionalAttrs cfg.enableMinimalSecrets {
        secrets = {
          apiKeyGemini = {
            sopsFile = minimalSopsFile;
          };
        };
        templates = {
          "llm-keys-minimal" = {
            owner = config.users.users.${username}.name;
            content = builtins.toJSON {
              gemini = config.sops.placeholder.apiKeyGemini;
            };
          };
        };
      })

      (lib.optionalAttrs cfg.enableFullSecrets {
        secrets = {
          smbHost = {
            sopsFile = fullSopsFile;
          };
          smbUrl = {
            sopsFile = fullSopsFile;
          };

          # TODO: probably want this via sops home-manager module,
          # but it does create issues with (permissions? I tried but can't remember the error)
          apiKeyAnthropic = {
            sopsFile = fullSopsFile;
          };
          apiKeyCodestral = {
            sopsFile = fullSopsFile;
          };
          apiKeyGemini = {
            sopsFile = fullSopsFile;
          };
          apiKeyVoyage = {
            sopsFile = fullSopsFile;
          };
          apiKeyOpenai = {
            sopsFile = fullSopsFile;
          };
          apiKeyDeepseek = {
            sopsFile = fullSopsFile;
          };
          apiKeyOpenrouter = {
            sopsFile = fullSopsFile;
          };
        };
        templates = {
          "pro-25-preview.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: Gemini Pro 2.5
              id: gemini-2.5-pro-preview-03-25 
              apiKey: ${config.sops.placeholder.apiKeyGemini}
              apiType: google
              url: https://generativelanguage.googleapis.com
            '';
          };
          "flash-25-preview.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: Gemini Flash 2.5
              id: gemini-2.5-flash-preview-04-17
              apiKey: ${config.sops.placeholder.apiKeyGemini}
              apiType: google
              url: https://generativelanguage.googleapis.com
            '';
          };
          "flash-thinking-25-preview-openrouter.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: Gemini Flash Thinking 2.5 (OpenRouter)
              id: google/gemini-2.5-flash-preview:thinking
              apiKey: ${config.sops.placeholder.apiKeyOpenrouter}
              url: https://openrouter.ai/api/v1
            '';
          };
          "flash-25-preview-openrouter.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: Gemini Flash 2.5 (OpenRouter)
              id: google/gemini-2.5-flash-preview
              apiKey: ${config.sops.placeholder.apiKeyOpenrouter}
              url: https://openrouter.ai/api/v1


            '';
          };
          "pro-25-preview-openrouter.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: Gemini Pro 2.5 (OpenRouter)
              id: google/gemini-2.5-pro-preview-03-25
              apiKey: ${config.sops.placeholder.apiKeyOpenrouter}
              url: https://openrouter.ai/api/v1
            '';
          };
          "o3.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: o3 
              id: openai/o3 
              apiKey: ${config.sops.placeholder.apiKeyOpenrouter}
              url: https://openrouter.ai/api/v1
            '';
          };
          "o4-mini.yaml" = {
            owner = config.users.users.${username}.name;
            content = ''
              name: o4-mini
              id: openai/o4-mini
              apiKey: ${config.sops.placeholder.apiKeyOpenrouter}
              url: https://openrouter.ai/api/v1
            '';
          };
          "llm-keys-full" = {
            owner = config.users.users.${username}.name;
            content = builtins.toJSON {
              gemini = config.sops.placeholder.apiKeyGemini;
              openai = config.sops.placeholder.apiKeyOpenai;
              anthropic = config.sops.placeholder.apiKeyAnthropic;
            };
          };
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
