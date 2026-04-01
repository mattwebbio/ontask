import { Hono } from 'hono'
import { getCommitmentStatus } from './tools/get-commitment-status.js'

// ── OnTask MCP Server ─────────────────────────────────────────────────────────
// Cloudflare Worker hosting the On Task MCP server.
// Tools are added here as they are implemented across stories.
//
// Service Binding: env.API → ontask-api Worker (zero-latency in-process RPC).
// CRITICAL: Never make HTTP calls to api.ontaskhq.com from MCP tools.
// Always use the env.API Service Binding.
//
// See: apps/mcp/wrangler.jsonc [[services]] config for binding definition.

interface Env {
  // Cloudflare Service Binding to the ontask-api Worker.
  // Uncomment in wrangler.jsonc when deploying:
  // "services": [{ "binding": "API", "service": "ontask-api" }]
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  API?: { fetch: (...args: any[]) => Promise<any> }
}

const app = new Hono<{ Bindings: Env }>()

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

// ── Tool: get_commitment_status ───────────────────────────────────────────────
// GET /tools/get-commitment-status?id=<uuid>
//
// Reads the status of a commitment contract by its ID.
// Returns status (active/charged/cancelled/disputed), stake amount, and
// charge timestamp if charged. Scoped to authenticated user's contracts only.
//
// TODO(impl): Replace query-param routing with proper MCP protocol handler
//             when MCP SDK is integrated (Epic 10, Story 10.3).
// TODO(impl): wire OAuth per-client scoping (FR93) — deferred to Story 10.4.

app.get('/tools/get-commitment-status', async (c) => {
  const id = c.req.query('id')
  if (!id) {
    return c.json({ error: { code: 'MISSING_ID', message: 'id query parameter is required' } }, 400)
  }

  const apiBinding = c.env.API
  if (!apiBinding) {
    // In local development / tests the binding may be absent.
    return c.json({ error: { code: 'SERVICE_BINDING_UNAVAILABLE', message: 'API service binding is not configured' } }, 503)
  }

  try {
    const result = await getCommitmentStatus({ id }, apiBinding)
    return c.json({ data: result }, 200)
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e)
    return c.json({ error: { code: 'UPSTREAM_ERROR', message } }, 502)
  }
})

export default app
