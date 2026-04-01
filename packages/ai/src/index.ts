// @ontask/ai — AI pipeline abstraction (Vercel AI SDK + Cloudflare AI Gateway)
// Story 3.7: NLP scheduling nudge parser bootstrapped here.
// Story 4.1: NLP task capture parser added (FR1b).
// Story 4.2: Guided chat task capture parser added (FR14/UX-DR15).

export { parseSchedulingNudge } from './nudge-parser.js'
export type { NudgeInput, NudgeOutput } from './nudge-parser.js'
export { parseTaskUtterance } from './nlp-parser.js'
export type { TaskParseInput, TaskParseOutput } from './nlp-parser.js'
export { conductGuidedChatTurn } from './guided-chat-parser.js'
export type { GuidedChatInput, GuidedChatOutput, GuidedChatTaskDraft } from './guided-chat-parser.js'
export { createAIProvider } from './provider.js'
export type { AIProviderEnv } from './provider.js'
