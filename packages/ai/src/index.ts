// @ontask/ai — AI pipeline abstraction (Vercel AI SDK + Cloudflare AI Gateway)
// Story 3.7: NLP scheduling nudge parser bootstrapped here.
// Story 4.1: NLP task capture parser added (FR1b).

export { parseSchedulingNudge } from './nudge-parser.js'
export type { NudgeInput, NudgeOutput } from './nudge-parser.js'
export { parseTaskUtterance } from './nlp-parser.js'
export type { TaskParseInput, TaskParseOutput } from './nlp-parser.js'
export { createAIProvider } from './provider.js'
export type { AIProviderEnv } from './provider.js'
