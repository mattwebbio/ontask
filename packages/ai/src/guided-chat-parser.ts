import { generateObject } from 'ai'
import { z } from 'zod'
import { createAIProvider, type AIProviderEnv } from './provider.js'

// ── Input / Output types ──────────────────────────────────────────────────────

/**
 * GuidedChatInput — the data required for a single turn of guided chat.
 *
 * Caller manages conversation history; this function is stateless.
 * FR14 / UX-DR15: Multi-turn conversational task capture.
 */
export interface GuidedChatInput {
  /** Full conversation history so far (user + assistant turns) */
  messages: Array<{ role: 'user' | 'assistant'; content: string }>
  /** Available lists for matching natural language list references */
  availableLists: Array<{ id: string; title: string }>
  /** Current time — used to resolve relative date expressions */
  now: Date
  /** The user's ID */
  userId: string
}

/**
 * GuidedChatTaskDraft — the partially (or fully) resolved task object.
 * All fields are optional until the conversation is complete.
 */
export interface GuidedChatTaskDraft {
  /** The resolved task title */
  title?: string | null
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
}

/**
 * GuidedChatOutput — the result of a single guided chat turn.
 */
export interface GuidedChatOutput {
  /** The LLM's next conversational message to display to the user */
  reply: string
  /** True when the LLM has collected enough info to create the task */
  isComplete: boolean
  /** Populated when isComplete is true */
  extractedTask?: GuidedChatTaskDraft
}

// ── Zod schema for structured LLM output ─────────────────────────────────────

const GuidedChatResultSchema = z.object({
  reply: z.string().describe("The assistant's next conversational message"),
  isComplete: z
    .boolean()
    .describe('True when the task object is fully ready to be created'),
  extractedTask: z
    .object({
      title: z.string().nullable().optional().describe('The resolved task title'),
      dueDate: z
        .string()
        .nullable()
        .optional()
        .describe('ISO 8601 date string for the due date. Null if not mentioned.'),
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
    })
    .nullable()
    .optional()
    .describe('Populated when isComplete is true; null or omitted during conversation'),
})

// ── LLM timeout constant ──────────────────────────────────────────────────────

/** Maximum ms to wait for the LLM before throwing (NFR-P3: 3-second budget, 2.5s for LLM) */
const LLM_TIMEOUT_MS = 2500

// ── Main export ───────────────────────────────────────────────────────────────

/**
 * conductGuidedChatTurn — executes one turn of guided chat task capture.
 *
 * Stateless: the caller manages conversation history by passing all prior
 * messages in `input.messages`. The LLM asks one clarifying question at a
 * time and sets `isComplete: true` once it has enough to create the task.
 *
 * Architecture note (ARCH-21): All LLM calls belong in `packages/ai`,
 * not in `packages/scheduling`.
 *
 * Multi-turn approach: since `generateObject` accepts `prompt: string` (not
 * a messages array), the full conversation history is serialised into the
 * prompt string. This is consistent with the existing `nlp-parser.ts` pattern.
 *
 * Throws with code 'TIMEOUT' if the LLM exceeds 2500ms (NFR-P3).
 *
 * @param input - GuidedChatInput with messages, availableLists, now, userId
 * @param env - Cloudflare worker bindings (undefined in tests — provider is mocked)
 */
export async function conductGuidedChatTurn(
  input: GuidedChatInput,
  env?: AIProviderEnv,
): Promise<GuidedChatOutput> {
  const provider = createAIProvider(env)
  const model = provider('gpt-4o-mini')

  const nowIso = input.now.toISOString()

  const listsDescription =
    input.availableLists.length > 0
      ? `Available lists:\n${input.availableLists.map((l) => `- "${l.title}" (id: ${l.id})`).join('\n')}`
      : 'No lists available.'

  // Serialise conversation history into prompt string (generateObject pattern)
  const historyText =
    input.messages.length > 0
      ? input.messages
          .map((m) => `${m.role === 'user' ? 'User' : 'Assistant'}: ${m.content}`)
          .join('\n')
      : '(No messages yet — start the conversation)'

  const prompt = `You are a patient task-creation assistant. Ask one clarifying question at a time. Stop asking when you have enough to create the task. Always respond in plain conversational English. When you have a complete task, set isComplete to true and populate extractedTask. Do not ask for information the user has already provided.

Current time (treat this as "now" for resolving relative dates): ${nowIso}

${listsDescription}

The assistant should help capture: task title, due date, time constraints, energy requirements, list assignment.

Conversation so far:
${historyText}

Now produce the next assistant turn. If this is the start of the conversation (no messages yet), begin with a friendly opening question to start capturing the task.`

  // Race the LLM call against a timeout (NFR-P3)
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => {
      const err = new Error('Chat assistant timed out — please try again')
      ;(err as NodeJS.ErrnoException).code = 'TIMEOUT'
      reject(err)
    }, LLM_TIMEOUT_MS)
  })

  const llmPromise = generateObject({
    model,
    schema: GuidedChatResultSchema,
    prompt,
  })

  const { object } = await Promise.race([llmPromise, timeoutPromise])

  return {
    reply: object.reply,
    isComplete: object.isComplete,
    extractedTask: object.isComplete && object.extractedTask
      ? {
          title: object.extractedTask.title ?? null,
          dueDate: object.extractedTask.dueDate ?? null,
          scheduledTime: object.extractedTask.scheduledTime ?? null,
          estimatedDurationMinutes: object.extractedTask.estimatedDurationMinutes ?? null,
          energyRequirement: object.extractedTask.energyRequirement ?? null,
          listId: object.extractedTask.listId ?? null,
        }
      : undefined,
  }
}
