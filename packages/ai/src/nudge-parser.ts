import { generateObject } from 'ai'
import { z } from 'zod'
import { createAIProvider, type AIProviderEnv } from './provider.js'

// ── Input / Output types ──────────────────────────────────────────────────────

/**
 * NudgeInput — the data required to resolve a natural language scheduling
 * nudge to a structured suggested date.
 *
 * FR14: Users can adjust scheduled tasks using natural language nudges.
 */
export interface NudgeInput {
  /** Raw natural language utterance from the user, e.g. "move to tomorrow morning" */
  utterance: string
  /** The task ID being nudged */
  taskId: string
  /** Human-readable task title (used in the prompt for context) */
  taskTitle: string
  /** Current scheduled time for the task, if any */
  currentScheduledTime?: Date
  /** Scheduling window start — used as "current time" reference in the prompt */
  windowStart: Date
  /** Scheduling window end — suggestions outside this range get confidence 'low' */
  windowEnd: Date
}

/**
 * NudgeOutput — the structured result of parsing a scheduling nudge.
 */
export interface NudgeOutput {
  /** The resolved suggested date for the task */
  suggestedDate: Date
  /**
   * Confidence in the interpretation.
   * 'low' when the utterance is ambiguous or the resolved date falls outside
   * the scheduling window.
   */
  confidence: 'high' | 'low'
  /** Human-readable confirmation, e.g. "Tomorrow morning at 9 AM" */
  interpretation: string
}

// ── Zod schema for structured LLM output ─────────────────────────────────────

const NudgeResultSchema = z.object({
  suggestedDate: z.string().describe('ISO 8601 datetime string for the suggested slot'),
  confidence: z.enum(['high', 'low']),
  interpretation: z
    .string()
    .describe('Human-readable confirmation e.g. "Tomorrow morning at 9 AM"'),
})

// ── LLM timeout constant ──────────────────────────────────────────────────────

/** Maximum ms to wait for the LLM before throwing (NFR-P3: 3-second budget, 2.5s for LLM) */
const LLM_TIMEOUT_MS = 2500

// ── Main export ───────────────────────────────────────────────────────────────

/**
 * parseSchedulingNudge — resolves a natural language scheduling utterance to
 * a structured suggested date using the Vercel AI SDK + Cloudflare AI Gateway.
 *
 * The scheduling engine is NLP-agnostic (ARCH-21). This function is the
 * pre-processing layer that converts user intent to `ScheduleInput.suggestedDates`.
 *
 * Returns `confidence: 'low'` when:
 * - The utterance is ambiguous
 * - The resolved date falls outside [windowStart, windowEnd]
 *
 * Throws with code 'TIMEOUT' if the LLM exceeds 2500ms (NFR-P3).
 *
 * @param input - NudgeInput with utterance, task context, and scheduling window
 * @param env - Cloudflare worker bindings (undefined in tests — provider is mocked)
 */
export async function parseSchedulingNudge(
  input: NudgeInput,
  env?: AIProviderEnv,
): Promise<NudgeOutput> {
  const provider = createAIProvider(env)
  const model = provider('gpt-4o-mini')

  const windowStartIso = input.windowStart.toISOString()
  const windowEndIso = input.windowEnd.toISOString()
  const currentIso = input.currentScheduledTime?.toISOString() ?? 'not currently scheduled'

  const prompt = `You are a scheduling assistant. The user wants to reschedule a task.

Task: "${input.taskTitle}"
Current scheduled time: ${currentIso}
Current time reference (treat this as "now"): ${windowStartIso}
Scheduling window: ${windowStartIso} to ${windowEndIso}

User said: "${input.utterance}"

Resolve the user's request to a specific ISO 8601 datetime within the scheduling window.

Rules:
- Relative expressions like "tomorrow morning" = next day between 07:00-12:00 (use 09:00)
- "Tomorrow afternoon" = next day 12:00-17:00 (use 14:00)
- "Tomorrow evening" = next day 17:00-21:00 (use 18:00)
- "After lunch" = same day at 13:00 or next available afternoon slot
- "In 30 minutes" = windowStart + 30 minutes
- "Next week" = 7 days from windowStart at 09:00
- If the resolved date would fall outside the scheduling window, set confidence to "low"
- If the utterance is ambiguous or cannot be resolved, set confidence to "low" and provide a best-guess date

Return a JSON object matching the required schema.`

  // Race the LLM call against a timeout (NFR-P3)
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      const err = new Error('Scheduling assistant timed out — try a simpler phrase')
      ;(err as NodeJS.ErrnoException).code = 'TIMEOUT'
      reject(err)
    }, LLM_TIMEOUT_MS)
  })

  const llmPromise = generateObject({
    model,
    schema: NudgeResultSchema,
    prompt,
  })

  const { object } = await Promise.race([llmPromise, timeoutPromise])

  // Parse the ISO string to Date
  const suggestedDate = new Date(object.suggestedDate)

  // Override confidence to 'low' if the resolved date is outside the window
  let confidence = object.confidence
  if (suggestedDate < input.windowStart || suggestedDate > input.windowEnd) {
    confidence = 'low'
  }

  return {
    suggestedDate,
    confidence,
    interpretation: object.interpretation,
  }
}
