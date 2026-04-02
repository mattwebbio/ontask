import { drizzle } from 'drizzle-orm/neon-http'
import { neon } from '@neondatabase/serverless'

export function getDb(databaseUrl: string) {
  return drizzle(neon(databaseUrl), { casing: 'camelCase' })
}
