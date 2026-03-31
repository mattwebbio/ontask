import { pgTable, uuid, timestamp, unique } from 'drizzle-orm/pg-core'
import { tasksTable } from './tasks.js'

// ── Task Dependencies table ────────────────────────────────────────────────
// Join table for directional task dependencies.
// Task B (dependentTaskId) depends on Task A (dependsOnTaskId).
// A task can have multiple dependencies (many-to-many, directional).

export const taskDependenciesTable = pgTable(
  'task_dependencies',
  {
    id: uuid().primaryKey().defaultRandom(),
    dependentTaskId: uuid().notNull(), // Task B — the task that waits
    dependsOnTaskId: uuid().notNull(), // Task A — the prerequisite
    createdAt: timestamp({ withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    unique('uq_dependency').on(table.dependentTaskId, table.dependsOnTaskId),
  ]
)
