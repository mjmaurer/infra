{
  config,
  pkgs,
  username,
  mylib,
  lib,
  ...
}:
let
  cfg = config.modules.ai-secrets;
  otherSopsFile = ./vault/ai/other.yaml;
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

    (lib.optionalAttrs cfg.enableGemini {
      sops.secrets = {
        apiKeyGemini = {
          sopsFile = ./vault/ai/gemini.yaml;
        };
      };
    })

    (lib.optionalAttrs cfg.enableOpenai {
      sops.secrets = {
        apiKeyOpenai = {
          sopsFile = ./vault/ai/openai.yaml;
        };
      };
    })

    (lib.optionalAttrs cfg.enableOpenrouter {
      sops.secrets = {
        apiKeyOpenrouter = {
          sopsFile = ./vault/ai/openrouter.yaml;
        };
      };
    })

    (lib.optionalAttrs cfg.enableOtherAi {
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
