import { pgTable, uuid, integer, boolean, timestamp, unique } from 'drizzle-orm/pg-core'
import { groupCommitmentsTable } from './group-commitments.js'

// ── Group commitment members table ───────────────────────────────────────────
// Per-member state within a group commitment: individual stake, approval status,
// and pool mode opt-in (FR29, FR30, Story 6.7).
export const groupCommitmentMembersTable = pgTable('group_commitment_members', {
  id: uuid().primaryKey().defaultRandom(),
  groupCommitmentId: uuid().notNull().references(() => groupCommitmentsTable.id, { onDelete: 'cascade' }),
  userId: uuid().notNull(),
  stakeAmountCents: integer(),         // nullable; each member sets their own amount
  approved: boolean().notNull().default(false),  // explicit approval for the group commitment
  poolModeOptIn: boolean().notNull().default(false), // explicit opt-in for pool mode (separate from approval)
  // Pool mode: if true, this member is charged if ANY opted-in member fails their task
  createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  unique('group_commitment_members_commitment_user_unique').on(
    table.groupCommitmentId, table.userId
  ),
])
