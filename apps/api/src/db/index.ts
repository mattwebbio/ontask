import { neon } from '@neondatabase/serverless'
import { drizzle } from 'drizzle-orm/neon-http'

/**
 * Creates a Drizzle ORM database instance using the Neon HTTP transport.
 *
 * IMPORTANT: Uses HTTP transport only — no WebSocket connection pooling.
 * This is required for compatibility with the Cloudflare Workers edge runtime.
 *
 * The `casing: 'camelCase'` option ensures DB snake_case column names are
 * automatically transformed to camelCase in query results — no manual mapping needed.
 *
 * Usage in route handlers:
 *   const db = createDb(c.env.DATABASE_URL)
 */
export function createDb(databaseUrl: string) {
  const sql = neon(databaseUrl)
  return drizzle(sql, { casing: 'camelCase' })
}
