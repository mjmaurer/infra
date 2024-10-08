/// <reference types="/Users/mmaurer7/.continue/types/core/index.d.ts" />
export function modifyConfig(config: Config): Config {
  config.disableIndexing = true;
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  if (anthropicKey) {
    config.models.push({
      title: "Claude 3.5 Sonnet",
      provider: "anthropic",
      model: "claude-3-5-sonnet-20240620",
      apiKey: anthropicKey,
    });
    console.info("Antropic loaded");
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
    console.info("Codestral loaded");
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
    console.info("Voyage loaded");
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
    console.info("OpenAI loaded");
  } else {
    console.error("Missing OPENAI_API_KEY");
  }

  return config;
}
