/// <reference types="../../../../../.continue/types/core/index.d.ts" />
export function modifyConfig(config: Config): Config {
  const anthropicKey = process.env.ANTHROPIC_API_KEY;
  if (anthropicKey) {
    config.models.push({
      title: "Claude 3 Sonnet",
      provider: "anthropic",
      model: "claude-3-5-sonnet-20240620",
      apiKey: anthropicKey,
    });
  } else {
    console.error("Missing ANTHROPIC_API_KEY"); 
  }

  return config;
}
