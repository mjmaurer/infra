{
  config,
  pkgs,
  username,
  lib,
  ...
}:
{

  sops.templates = {
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
  };
}
