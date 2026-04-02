// ── get_commitment_status MCP tool (FR71, Story 6.9) ──────────────────────────
//
// Tool name: get_commitment_status
// Description: Reads the status of a commitment contract by its ID.
//              Returns status (active/charged/cancelled/disputed), stake amount,
//              and charge timestamp if charged. Scoped to authenticated user's contracts only.
// Input: { id: string } — UUID of the contract
// Output: { id, status, stakeAmountCents, chargeTimestamp }
//
// Uses Cloudflare Service Binding (env.API) to call GET /v1/contracts/:id/status
// on the API Worker — NEVER makes HTTP calls to the public API URL.
//
// userId is provided by the OAuth middleware (FR93, Story 10.4) — not caller-supplied.

export interface GetCommitmentStatusInput {
  id: string
}

export interface GetCommitmentStatusOutput {
  id: string
  status: 'active' | 'charged' | 'cancelled' | 'disputed'
  stakeAmountCents: number | null
  chargeTimestamp: string | null
}

/**
 * Calls GET /v1/contracts/:id/status via the API Service Binding.
 *
 * CRITICAL: Always uses the `apiBinding` Service Binding — NEVER calls api.ontaskhq.com directly.
 * This is a zero-latency in-process call within the Cloudflare network.
 * The `apiBinding` is `env.API` from the Cloudflare Worker environment.
 *
 * Note: `apiBinding` is typed as `unknown` to avoid pulling in web/Worker global types
 * that are not available in ESNext-only tsconfig. The actual binding at runtime provides
 * a fetch-compatible interface (Cloudflare Service Binding).
 */
export async function getCommitmentStatus(
  input: GetCommitmentStatusInput,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  apiBinding: { fetch: (...args: any[]) => Promise<any> },
  userId: string,
): Promise<GetCommitmentStatusOutput> {
  // Cloudflare Service Bindings accept a URL string + init object (fetch-compatible)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const response: any = await apiBinding.fetch(
    `https://ontask-api-internal/v1/contracts/${input.id}/status`,
    {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'x-user-id': userId,
      },
    },
  )

  if (!response.ok) {
    const errorBody: string = await response.text()
    throw new Error(
      `get_commitment_status: API returned ${response.status} — ${errorBody}`,
    )
  }

  const json = (await response.json()) as { data: GetCommitmentStatusOutput }
  return json.data
}
