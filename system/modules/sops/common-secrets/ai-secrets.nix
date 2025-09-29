{
  config,
  pkgs,
  username,
  mylib,
  lib,
  ...
}:
let
  otherSopsFile = ../vault/ai/other.yaml;
in
{

  options.modules.ai-secrets = {
    enableOpenrouter = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
        "dev-client"
      ];
    };
    enableGemini = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
        "dev-client"
      ];
    };
    enableCerebras = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
        "dev-client"
      ];
    };
    enableOpenai = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
      ];
    };
    enableOtherAi = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
      ];
      description = "Includes Anthropic, Codestral, Voyage, Deepseek";
    };
  };

  config = lib.mkMerge [

    (lib.mkIf config.modules.ai-secrets.enableGemini {
      sops.secrets = {
        apiKeyGemini = {
          sopsFile = ../vault/ai/gemini.yaml;
        };
      };
    })

    (lib.mkIf config.modules.ai-secrets.enableOpenai {
      sops.secrets = {
        apiKeyOpenai = {
          sopsFile = ../vault/ai/openai.yaml;
        };
      };
    })

    (lib.mkIf config.modules.ai-secrets.enableCerebras {
      sops.secrets = {
        apiKeyCerebras = {
          sopsFile = ../vault/ai/cerebras.yaml;
        };
      };
    })

    (lib.mkIf config.modules.ai-secrets.enableOpenrouter {
      sops.secrets = {
        apiKeyOpenrouter = {
          sopsFile = ../vault/ai/openrouter.yaml;
        };
      };
    })

    (lib.mkIf config.modules.ai-secrets.enableOtherAi {
      sops.secrets = {
        apiKeyAnthropic = {
          sopsFile = otherSopsFile;
        };
        apiKeyCodestral = {
          sopsFile = otherSopsFile;
        };
        apiKeyVoyage = {
          sopsFile = otherSopsFile;
        };
        apiKeyDeepseek = {
          sopsFile = otherSopsFile;
        };
      };
    })
  ];
}
