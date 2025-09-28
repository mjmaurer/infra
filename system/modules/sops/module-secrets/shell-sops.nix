{
  config,
  pkgs,
  username,
  lib,
  mylib,
  ...
}:
let
  cfg = config.modules.shell-sops;
in
{
  options.modules.shell-sops = {
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
      "shell.env" = {
        # mode = "0400";
        # group = config.users.groups.${username}.name;
        # restartUnits = [ "home-assistant.service" ];
        owner = config.users.users.${username}.name;
        content = ''
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyAnthropic
          ) "export ANTHROPIC_API_KEY=${config.sops.placeholder.apiKeyAnthropic}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyGemini
          ) "export GEMINI_API_KEY=${config.sops.placeholder.apiKeyGemini}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyAnthropic
          ) "export CLAUDE_API_KEY=${config.sops.placeholder.apiKeyAnthropic}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyCodestral
          ) "export CODESTRAL_API_KEY=${config.sops.placeholder.apiKeyCodestral}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyVoyage
          ) "export VOYAGE_API_KEY=${config.sops.placeholder.apiKeyVoyage}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyOpenai
          ) "export OPENAI_API_KEY=${config.sops.placeholder.apiKeyOpenai}"}
          ${lib.optionalString (
            config.sops.placeholder ? apiKeyDeepseek
          ) "export DEEPSEEK_API_KEY=${config.sops.placeholder.apiKeyDeepseek}"}
        '';
      };
    };
  };
}
