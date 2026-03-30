import type { Config } from 'drizzle-kit'

export default {
  schema: '../../packages/core/src/schema/index.ts',
  out: '../../packages/core/src/schema/migrations',
  dialect: 'postgresql',
} satisfies Config
