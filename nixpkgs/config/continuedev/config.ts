/// <reference types="../../../../../.continue/types/core/index.d.ts" />
export function modifyConfig(config: Config): Config {
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  if (anthropicKey) {
    config.models.push({
      title: "Claude 3.5 Sonnet",
      provider: "anthropic",
      model: "claude-3-5-sonnet-20240620",
      apiKey: anthropicKey,
    });
  } else {
    console.error("Missing ANTHROPIC_API_KEY");
  }
  const codestralKey = process.env.CODESTRAL_API_KEY;
  if (codestralKey) {
    const codstral: ModelDescription = {
      title: "Codestral Latest",
      provider: "mistral",
      model: "codestral-latest",
      apiKey: codestralKey,
    };
    config.models.push(codstral);
    config.tabAutocompleteModel = codstral;
  } else {
    console.error("Missing CODESTRAL_API_KEY");
  }
  const voyageKey = process.env.VOYAGE_API_KEY;
  if (voyageKey) {
    config.embeddingsProvider = {
      provider: "openai",
      model: "voyage-code-2",
      apiBase: "https://api.voyageai.com/v1/",
      apiKey: voyageKey,
    };
  } else {
    console.error("Missing VOYAGE_API_KEY");
  }
  const openAiKey = process.env.OPENAI_API_KEY;
  if (openAiKey) {
    config.models.push({
      title: "GPT 4",
      provider: "openai",
      model: "gpt-4",
      apiKey: openAiKey,
    });
    config.models.push({
      title: "GPT 4o",
      provider: "openai",
      model: "gpt-4o",
      apiKey: openAiKey,
    });
  } else {
    console.error("Missing OPEN_AI_API_KEY");
  }

  return config;
}
