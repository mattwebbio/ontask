import { createOpenAI } from '@ai-sdk/openai'

/** Minimal env shape needed by the AI provider — avoids coupling to apps/api's CloudflareBindings. */
export interface AIProviderEnv {
  AI_GATEWAY_URL?: string
}

/**
 * createAIProvider — returns a model factory configured to use the
 * Cloudflare AI Gateway binding when available, or falls back to direct
 * OpenAI for local development without `wrangler dev`.
 *
 * Callers invoke the returned factory with a model name:
 *   const provider = createAIProvider(env)
 *   const model = provider('gpt-4o-mini')
 *
 * Architecture note: the AI Gateway binding is named "AI" in wrangler.toml.
 * The gateway URL format for Cloudflare Workers AI Gateway:
 *   https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/openai
 *
 * @param env - Cloudflare worker bindings (may be undefined in unit tests)
 */
export function createAIProvider(env?: AIProviderEnv) {
  // When running under wrangler dev the AI binding is available.
  // Use the gateway URL if configured via env; otherwise fall back to
  // direct OpenAI (needed for local `flutter run` dev without wrangler).
  const gatewayUrl = env?.AI_GATEWAY_URL ?? undefined

  const openai = createOpenAI({
    ...(gatewayUrl ? { baseURL: gatewayUrl } : {}),
  })

  return openai
}
