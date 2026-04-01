// @ontask/ai — AI pipeline abstraction (Vercel AI SDK + Cloudflare AI Gateway)
// Story 3.7: NLP scheduling nudge parser bootstrapped here.
// Epic 4 (AI-Powered Task Capture) will add further exports.

export { parseSchedulingNudge } from './nudge-parser.js'
export type { NudgeInput, NudgeOutput } from './nudge-parser.js'
export { createAIProvider } from './provider.js'
export type { AIProviderEnv } from './provider.js'
