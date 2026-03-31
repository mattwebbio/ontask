/**
 * Scheduling engine types for @ontask/scheduling.
 *
 * Types live in /packages/core to avoid circular dependencies between
 * @ontask/scheduling and any consumer packages. The scheduling engine itself
 * is a pure function: no side effects, no external calls, no randomness.
 */

export type TimeWindow = 'morning' | 'afternoon' | 'evening' | 'custom'
export type EnergyRequirement = 'high_focus' | 'low_energy' | 'flexible'

export interface ScheduleTask {
  id: string
  title: string
  dueDate?: Date
  estimatedDurationMinutes?: number
  timeWindow?: TimeWindow
  timeWindowStart?: string // HH:mm, when timeWindow === 'custom'
  timeWindowEnd?: string // HH:mm, when timeWindow === 'custom'
  energyRequirement?: EnergyRequirement
  priority?: 'normal' | 'high' | 'critical'
  dependsOnTaskIds?: string[] // FR73 — task dependency constraints
  lockedStartTime?: Date // FR8 — user manually pinned this slot
  suggestedDate?: Date // FR14 — UI nudge (date picker / NLP pre-resolved)
}

export interface CalendarEvent {
  id: string
  startTime: Date
  endTime: Date
  isAllDay: boolean
}

export interface ScheduleInput {
  tasks: ScheduleTask[]
  calendarEvents: CalendarEvent[] // merged from all providers — engine never knows which provider
  windowStart: Date // scheduling horizon start (typically now)
  windowEnd: Date // scheduling horizon end (typically +14 days)
  suggestedDates?: Record<string, Date> // taskId → suggested date (FR14 nudging)
}

export interface ScheduledBlock {
  taskId: string
  startTime: Date
  endTime: Date
  isLocked: boolean // FR8 — manual override flag
  isAtRisk: boolean // true if no valid slot found before due date
  constraintNotes?: string // optional: which constraints shaped this slot (for explainer)
}

export interface ScheduleOutput {
  scheduledBlocks: ScheduledBlock[]
  unscheduledTaskIds: string[] // tasks that could not be placed in the window
  generatedAt: Date // for determinism auditing — always set by caller, not by engine
}

export interface ExplainOutput {
  reasons: string[]
}
