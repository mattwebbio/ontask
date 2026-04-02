import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core'

// ── MCP OAuth Tokens ──────────────────────────────────────────────────────────
// Per-client scoped bearer tokens for the MCP Worker (FR93, Story 10.4).
//
// Raw tokens are NEVER stored — only the SHA-256 hex hash is persisted.
// The raw token is returned once at issuance and then discarded.
//
// userId has no FK constraint yet — deferred-FK pattern used here as the
// users table does not exist in the schema yet (consistent with this codebase).

export const mcpOauthTokensTable = pgTable('mcp_oauth_tokens', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull(),
  clientName: text('client_name').notNull(),
  tokenHash: text('token_hash').notNull().unique(),
  scopes: text('scopes').array().notNull(),
  revokedAt: timestamp('revoked_at'),
  lastUsedAt: timestamp('last_used_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
})
