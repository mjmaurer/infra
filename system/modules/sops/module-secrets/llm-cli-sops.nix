{
  config,
  pkgs,
  username,
  mylib,
  lib,
  ...
}:
let
  cfg = config.modules.llm-cli-sops;
in
{
  options.modules.llm-cli-sops = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = mylib.sysTagsIn [
        "darwin"
        "full-client"
        "dev-client"
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    sops.templates = {
      "llm-keys" = {
        owner = config.users.users.${username}.name;
        content = builtins.toJSON (
          lib.filterAttrs (n: v: v != null) {
            anthropic =
              if config.sops.placeholder ? apiKeyAnthropic then config.sops.placeholder.apiKeyAnthropic else null;
            gemini =
              if config.sops.placeholder ? apiKeyGemini then config.sops.placeholder.apiKeyGemini else null;
            cerebras =
              if config.sops.placeholder ? apiKeyCerebras then config.sops.placeholder.apiKeyCerebras else null;
            codestral =
              if config.sops.placeholder ? apiKeyCodestral then config.sops.placeholder.apiKeyCodestral else null;
            voyage =
              if config.sops.placeholder ? apiKeyVoyage then config.sops.placeholder.apiKeyVoyage else null;
            deepseek =
              if config.sops.placeholder ? apiKeyDeepseek then config.sops.placeholder.apiKeyDeepseek else null;
            openai =
              if config.sops.placeholder ? apiKeyOpenai then config.sops.placeholder.apiKeyOpenai else null;
            openrouter =
              if config.sops.placeholder ? apiKeyOpenrouter then
                config.sops.placeholder.apiKeyOpenrouter
              else
                null;
          }
        );
      };
    };
  };
}
