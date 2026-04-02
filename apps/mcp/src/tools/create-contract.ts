// ── create_contract MCP tool (FR45, Story 10.5) ────────────────────────────────
//
// Tool name: create_contract
// Description: Creates a commitment contract for a task.
// Input: { taskId, stakeAmountCents, charityId, deadline }
// Output: MCP content format — { content: [{ type: 'text', text: JSON.stringify(contract) }] }
//         or error with NO_PAYMENT_METHOD (includes setupUrl) or MISSING_REQUIRED_FIELD
//
// Proxies to POST /v1/contracts on the API Worker via Service Binding.
// CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.
// Scope required: contracts:write

import type { McpResult } from './create-task.js'

export interface CreateContractInput {
  taskId: string
  stakeAmountCents: number
  charityId: string
  /** ISO 8601 UTC datetime string */
  deadline: string
}

/**
 * Creates a commitment contract via the API Service Binding (POST /v1/contracts).
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 * This is a zero-latency in-process call within the Cloudflare network.
 * The `apiBinding` is `env.API` from the Cloudflare Worker environment.
 *
 * If the user has no stored payment method, the API returns 422 NO_PAYMENT_METHOD with a setupUrl.
 * This tool preserves and surfaces the setupUrl to the AI client so it can guide the user.
 */
export async function createContract(
  input: CreateContractInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<McpResult> {
  // Input validation — all fields required
  if (!input.taskId || typeof input.taskId !== 'string') {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: { code: 'MISSING_REQUIRED_FIELD', message: 'taskId is required' },
          }),
        },
      ],
      isError: true,
    }
  }

  if (!input.charityId || typeof input.charityId !== 'string') {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: { code: 'MISSING_REQUIRED_FIELD', message: 'charityId is required' },
          }),
        },
      ],
      isError: true,
    }
  }

  if (!input.deadline || typeof input.deadline !== 'string') {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: { code: 'MISSING_REQUIRED_FIELD', message: 'deadline is required' },
          }),
        },
      ],
      isError: true,
    }
  }

  if (
    typeof input.stakeAmountCents !== 'number' ||
    !Number.isInteger(input.stakeAmountCents) ||
    input.stakeAmountCents <= 0
  ) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: {
              code: 'MISSING_REQUIRED_FIELD',
              message: 'stakeAmountCents must be a positive integer',
            },
          }),
        },
      ],
      isError: true,
    }
  }

  try {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const response: any = await apiBinding.fetch(
      'https://ontask-api-internal/v1/contracts',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
        body: JSON.stringify({
          taskId: input.taskId,
          stakeAmountCents: input.stakeAmountCents,
          charityId: input.charityId,
          deadline: input.deadline,
        }),
      },
    )

    if (response.status === 201) {
      const json = (await response.json()) as { data: unknown }
      return {
        content: [{ type: 'text', text: JSON.stringify(json.data) }],
      }
    }

    if (response.status === 422) {
      // Parse the 422 body — may be NO_PAYMENT_METHOD with setupUrl
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const errorJson = (await response.json()) as { error: { code: string; message: string; setupUrl?: string } }
      // Preserve setupUrl if present so AI clients can surface it to users
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: {
                code: errorJson.error.code,
                message: errorJson.error.message,
                ...(errorJson.error.setupUrl !== undefined ? { setupUrl: errorJson.error.setupUrl } : {}),
              },
            }),
          },
        ],
        isError: true,
      }
    }

    // Any other non-2xx
    const errorBody: string = await response.text()
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            error: {
              code: 'UPSTREAM_ERROR',
              message: `create_contract: API returned ${response.status} — ${errorBody}`,
            },
          }),
        },
      ],
      isError: true,
    }
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({ error: { code: 'UPSTREAM_ERROR', message } }),
        },
      ],
      isError: true,
    }
  }
}
