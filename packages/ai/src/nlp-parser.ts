import { generateObject } from 'ai'
import { z } from 'zod'
import { createAIProvider, type AIProviderEnv } from './provider.js'

// ── Input / Output types ──────────────────────────────────────────────────────

/**
 * TaskParseInput — the data required to parse a natural language task
 * utterance into structured task properties.
 *
 * FR1b: Users can create tasks using natural language input.
 */
export interface TaskParseInput {
  /** Raw natural language utterance from the user, e.g. "call the dentist Thursday at 2pm" */
  utterance: string
  /** The user's ID */
  userId: string
  /** Available lists for matching natural language list references */
  availableLists: Array<{ id: string; title: string }>
  /** Current time — used to resolve relative date expressions ("tomorrow", "Thursday") */
  now: Date
}

/**
 * TaskParseOutput — the structured result of parsing a task utterance.
 */
export interface TaskParseOutput {
  /** The resolved task title */
  title: string
  /**
   * Overall confidence in the parse.
   * 'low' when the utterance is too ambiguous to extract even a title.
   */
  confidence: 'high' | 'low'
  /** ISO 8601 date string for the due date, if resolved */
  dueDate?: string | null
  /** ISO 8601 datetime string for the scheduled time, if resolved */
  scheduledTime?: string | null
  /** Estimated duration in minutes, if resolved */
  estimatedDurationMinutes?: number | null
  /** Energy requirement, if resolved */
  energyRequirement?: 'high_focus' | 'low_energy' | 'flexible' | null
  /** Matched list ID from availableLists, if resolved */
  listId?: string | null
  /**
   * Per-field confidence map.
   * UI renders dashed borders on fields with 'low' confidence (UX-DR29).
   */
  fieldConfidences: Record<string, 'high' | 'low'>
}

// ── Zod schema for structured LLM output ─────────────────────────────────────

const TaskParseResultSchema = z.object({
  title: z.string().describe('The task title extracted from the utterance'),
  confidence: z.enum(['high', 'low']).describe(
    'Overall confidence. Set to low when utterance is too ambiguous to extract even a title.',
  ),
  dueDate: z
    .string()
    .nullable()
    .optional()
    .describe('ISO 8601 date string for the due date (date part only, e.g. 2026-04-03T00:00:00.000Z). Null if not mentioned.'),
  scheduledTime: z
    .string()
    .nullable()
    .optional()
    .describe('ISO 8601 datetime string for the specific scheduled time. Null if not mentioned.'),
  estimatedDurationMinutes: z
    .number()
    .nullable()
    .optional()
    .describe('Estimated duration in minutes. Null if not mentioned.'),
  energyRequirement: z
    .enum(['high_focus', 'low_energy', 'flexible'])
    .nullable()
    .optional()
    .describe('Energy requirement. Null if not mentioned.'),
  listId: z
    .string()
    .nullable()
    .optional()
    .describe('The ID of the matched list from availableLists. Null if no list reference detected.'),
  fieldConfidences: z
    .record(z.enum(['high', 'low']))
    .describe('Per-field confidence map. Include entries for each resolved field.'),
})

// ── LLM timeout constant ──────────────────────────────────────────────────────

/** Maximum ms to wait for the LLM before throwing (NFR-P3: 3-second budget, 2.5s for LLM) */
const LLM_TIMEOUT_MS = 2500

// ── Main export ───────────────────────────────────────────────────────────────

/**
 * parseTaskUtterance — resolves a natural language task utterance into
 * structured task properties using the Vercel AI SDK + Cloudflare AI Gateway.
 *
 * Architecture note (ARCH-21): The scheduling engine is NLP-agnostic.
 * This function lives in `packages/ai`, NOT in `packages/scheduling`.
 *
 * Returns `confidence: 'low'` when:
 * - The utterance is too ambiguous to extract even a title
 *
 * Per-field confidence in `fieldConfidences` allows the UI to render
 * dashed borders on uncertain fields (UX-DR29).
 *
 * Throws with code 'TIMEOUT' if the LLM exceeds 2500ms (NFR-P3).
 *
 * @param input - TaskParseInput with utterance, userId, availableLists, and now
 * @param env - Cloudflare worker bindings (undefined in tests — provider is mocked)
 */
export async function parseTaskUtterance(
  input: TaskParseInput,
  env?: AIProviderEnv,
): Promise<TaskParseOutput> {
  const provider = createAIProvider(env)
  const model = provider('gpt-4o-mini')

  const nowIso = input.now.toISOString()

  const listsDescription =
    input.availableLists.length > 0
      ? `Available lists:\n${input.availableLists.map((l) => `- "${l.title}" (id: ${l.id})`).join('\n')}`
      : 'No lists available.'

  const prompt = `You are a task capture assistant. Parse the user's natural language utterance into structured task properties.

Current time (treat this as "now" for resolving relative dates): ${nowIso}

${listsDescription}

User said: "${input.utterance}"

Extract the following from the utterance:
- title: A clear, concise task title (required)
- dueDate: ISO 8601 datetime string if a due date is mentioned (resolve relative expressions like "Thursday", "next Monday", "tomorrow" relative to the current time above). Null if not mentioned.
- scheduledTime: ISO 8601 datetime string for a specific time ("at 2pm", "at 9:30"). Null if not mentioned.
- estimatedDurationMinutes: Integer duration in minutes if mentioned ("for 30 minutes", "1 hour"). Null if not mentioned.
- energyRequirement: "high_focus" for demanding work, "low_energy" for easy tasks, "flexible" if adaptable. Null if not clear.
- listId: Match to one of the available lists by name. Return the list ID if matched, null if no list reference or no match.
- fieldConfidences: For each resolved field, indicate "high" or "low" confidence.
- confidence: "low" only when the utterance is completely incomprehensible and you cannot extract even a title.

Rules:
- Resolve relative days based on current time: "Thursday" = the next upcoming Thursday
- "Tomorrow morning" = next day at 09:00, "tomorrow afternoon" = next day at 14:00, "tomorrow evening" = next day at 18:00
- If a time is mentioned (e.g. "at 2pm"), set scheduledTime to that datetime
- Set confidence to "low" only when utterance is entirely unclear
- When in doubt about optional fields, leave them null rather than guessing

Return a JSON object matching the required schema.`

  // Race the LLM call against a timeout (NFR-P3)
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      const err = new Error('Task assistant timed out — try a simpler phrase')
      ;(err as NodeJS.ErrnoException).code = 'TIMEOUT'
      reject(err)
    }, LLM_TIMEOUT_MS)
  })

  const llmPromise = generateObject({
    model,
    schema: TaskParseResultSchema,
    prompt,
  })

  const { object } = await Promise.race([llmPromise, timeoutPromise])

  return {
    title: object.title,
    confidence: object.confidence,
    dueDate: object.dueDate ?? null,
    scheduledTime: object.scheduledTime ?? null,
    estimatedDurationMinutes: object.estimatedDurationMinutes ?? null,
    energyRequirement: object.energyRequirement ?? null,
    listId: object.listId ?? null,
    fieldConfidences: object.fieldConfidences,
  }
}
