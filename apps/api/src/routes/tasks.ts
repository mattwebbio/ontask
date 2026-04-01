import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'
import { runScheduleForUser } from '../services/scheduling.js'
import { parseTaskUtterance, conductGuidedChatTurn } from '@ontask/ai'

// ── Tasks router ────────────────────────────────────────────────────────────
// CRUD routes for task management (FR1, FR55, FR57, FR58, FR59).
// All routes return stub responses with TODO(impl) markers for real Drizzle
// implementation once auth middleware and database are wired.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createTaskSchema = z.object({
  title: z.string().min(1).openapi({ example: 'Buy groceries' }),
  notes: z.string().nullable().optional().openapi({ example: 'Milk, eggs, bread' }),
  dueDate: z.string().datetime().nullable().optional().openapi({
    example: '2026-04-01T09:00:00.000Z',
    description: 'If null, due date is inherited from section/list default (FR3).',
  }),
  listId: z.string().uuid().nullable().optional(),
  sectionId: z.string().uuid().nullable().optional(),
  parentTaskId: z.string().uuid().nullable().optional(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable().optional(),
  timeWindowStart: z.string().nullable().optional().openapi({
    example: '09:00',
    description: 'HH:mm format. Only used when timeWindow = "custom".',
  }),
  timeWindowEnd: z.string().nullable().optional().openapi({
    example: '11:00',
    description: 'HH:mm format. Only used when timeWindow = "custom".',
  }),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
  priority: z.enum(['normal', 'high', 'critical']).nullable().optional(),
  recurrenceRule: z.enum(['daily', 'weekly', 'monthly', 'custom']).nullable().optional(),
  recurrenceInterval: z.number().int().min(1).nullable().optional(),
  recurrenceDaysOfWeek: z.string().nullable().optional(),
  recurrenceParentId: z.string().uuid().nullable().optional(),
})

const updateTaskSchema = z.object({
  title: z.string().min(1).optional(),
  notes: z.string().nullable().optional(),
  dueDate: z.string().datetime().nullable().optional(),
  listId: z.string().uuid().nullable().optional(),
  sectionId: z.string().uuid().nullable().optional(),
  parentTaskId: z.string().uuid().nullable().optional(),
  position: z.number().int().optional(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable().optional(),
  timeWindowStart: z.string().nullable().optional(),
  timeWindowEnd: z.string().nullable().optional(),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
  priority: z.enum(['normal', 'high', 'critical']).nullable().optional(),
  recurrenceRule: z.enum(['daily', 'weekly', 'monthly', 'custom']).nullable().optional(),
  recurrenceInterval: z.number().int().min(1).nullable().optional(),
  recurrenceDaysOfWeek: z.string().nullable().optional(),
  recurrenceParentId: z.string().uuid().nullable().optional(),
  startedAt: z.string().datetime().nullable().optional(),
  elapsedSeconds: z.number().int().nullable().optional(),
})

const taskSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  listId: z.string().uuid().nullable(),
  sectionId: z.string().uuid().nullable(),
  parentTaskId: z.string().uuid().nullable(),
  title: z.string(),
  notes: z.string().nullable(),
  dueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  timeWindow: z.enum(['morning', 'afternoon', 'evening', 'custom']).nullable(),
  timeWindowStart: z.string().nullable(),
  timeWindowEnd: z.string().nullable(),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable(),
  priority: z.enum(['normal', 'high', 'critical']).nullable(),
  recurrenceRule: z.enum(['daily', 'weekly', 'monthly', 'custom']).nullable(),
  recurrenceInterval: z.number().int().nullable(),
  recurrenceDaysOfWeek: z.string().nullable(),
  recurrenceParentId: z.string().uuid().nullable(),
  startedAt: z.string().datetime().nullable(),
  elapsedSeconds: z.number().int().nullable(),
  archivedAt: z.string().datetime().nullable(),
  completedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
  assignedToUserId: z.string().uuid().nullable(),
  listName: z.string().nullable(),
  proofMode: z.enum(['standard', 'photo', 'watchMode', 'healthKit', 'calendarEvent']),
  proofModeIsCustom: z.boolean(),
  proofRetained: z.boolean(),
  proofMediaUrl: z.string().url().nullable(),
  completedByName: z.string().nullable(),
})

const TaskResponseSchema = z.object({ data: taskSchema })

// ── NLP parse schemas (FR1b) ─────────────────────────────────────────────────

const TaskParseRequestSchema = z.object({
  utterance: z.string().min(1).openapi({ example: 'call the dentist Thursday at 2pm' }),
})

const TaskParseResponseSchema = z.object({
  data: z.object({
    title: z.string(),
    confidence: z.enum(['high', 'low']),
    dueDate: z.string().nullable().optional(),
    scheduledTime: z.string().nullable().optional(),
    estimatedDurationMinutes: z.number().nullable().optional(),
    energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
    listId: z.string().nullable().optional(),
    fieldConfidences: z.record(z.string(), z.enum(['high', 'low'])),
  }),
})

// ── Guided chat schemas (FR14/UX-DR15) ──────────────────────────────────────

const ChatMessageSchema = z.object({
  role: z.enum(['user', 'assistant']),
  content: z.string().min(1),
})

const TaskChatRequestSchema = z.object({
  messages: z.array(ChatMessageSchema).min(1),
  availableLists: z
    .array(z.object({ id: z.string(), title: z.string() }))
    .optional(),
})

const GuidedChatTaskDraftSchema = z.object({
  title: z.string().nullable().optional(),
  dueDate: z.string().nullable().optional(),
  scheduledTime: z.string().nullable().optional(),
  estimatedDurationMinutes: z.number().nullable().optional(),
  energyRequirement: z.enum(['high_focus', 'low_energy', 'flexible']).nullable().optional(),
  listId: z.string().nullable().optional(),
})

const TaskChatResponseSchema = z.object({
  data: z.object({
    reply: z.string(),
    isComplete: z.boolean(),
    extractedTask: GuidedChatTaskDraftSchema.nullable().optional(),
  }),
})

const TaskListResponseSchema = z.object({
  data: z.array(taskSchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const CompleteTaskResponseSchema = z.object({
  data: z.object({
    completedTask: taskSchema,
    nextInstance: taskSchema.nullable(),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── Stub fixtures ───────────────────────────────────────────────────────────

const now = '2026-03-30T12:00:00.000Z'

function stubTask(overrides: Partial<z.infer<typeof taskSchema>> = {}): z.infer<typeof taskSchema> {
  return {
    id: 'a0000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-a000-000000000001',
    listId: null,
    sectionId: null,
    parentTaskId: null,
    title: 'Buy groceries',
    notes: null,
    dueDate: null,
    position: 0,
    timeWindow: null,
    timeWindowStart: null,
    timeWindowEnd: null,
    energyRequirement: null,
    priority: 'normal',
    recurrenceRule: null,
    recurrenceInterval: null,
    recurrenceDaysOfWeek: null,
    recurrenceParentId: null,
    startedAt: null,
    elapsedSeconds: null,
    archivedAt: null,
    completedAt: null,
    createdAt: now,
    updatedAt: now,
    assignedToUserId: null,
    listName: null,
    proofMode: 'standard' as const,
    proofModeIsCustom: false,
    proofRetained: false,
    proofMediaUrl: null,
    completedByName: null,
    ...overrides,
  }
}

// ── POST /v1/tasks/parse ─────────────────────────────────────────────────────
// IMPORTANT: Must be registered BEFORE GET /v1/tasks/:id to prevent Hono from
// interpreting "parse" as a task ID. (Dev Notes: route placement critical)

const postTaskParseRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/parse',
  tags: ['Tasks'],
  summary: 'Parse a natural language task utterance (FR1b)',
  description:
    'Parses a natural language utterance into structured task properties using AI. ' +
    'Does NOT create a task — returns parsed fields for user review before confirmation. ' +
    'Returns 422 when confidence is low or the LLM times out.',
  request: {
    body: { content: { 'application/json': { schema: TaskParseRequestSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskParseResponseSchema } }, description: 'Parsed task fields' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Low confidence or timeout' },
    400: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postTaskParseRoute, async (c) => {
  const body = c.req.valid('json')
  // Auth stub: x-user-id header (same pattern as other task routes)
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'

  try {
    const result = await parseTaskUtterance(
      {
        utterance: body.utterance,
        userId,
        availableLists: [], // TODO(impl): fetch from DB when available
        now: new Date(),
      },
      c.env,
    )

    if (result.confidence === 'low') {
      return c.json(
        err('UNPROCESSABLE', "Could not understand your task — try describing it differently"),
        422,
      )
    }

    return c.json(ok(result), 200)
  } catch (e) {
    const error = e as NodeJS.ErrnoException
    if (error.code === 'TIMEOUT') {
      return c.json(
        err('UNPROCESSABLE', 'Task assistant timed out — try a simpler phrase'),
        422,
      )
    }
    throw e
  }
})

// ── POST /v1/tasks/chat ──────────────────────────────────────────────────────
// IMPORTANT: Must be registered BEFORE POST /v1/tasks and all /:id routes to
// prevent Hono from interpreting "chat" as a task ID. (Dev Notes: route placement)

const postTaskChatRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/chat',
  tags: ['Tasks'],
  summary: 'Guided chat task capture — single turn (FR14/UX-DR15)',
  description:
    'Performs one turn of guided chat task capture. Stateless — caller manages conversation history. ' +
    'Does NOT create a task — returns the next conversational reply and, when complete, the extracted task draft. ' +
    'Returns 422 when the LLM times out.',
  request: {
    body: { content: { 'application/json': { schema: TaskChatRequestSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskChatResponseSchema } }, description: 'Next chat turn' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'LLM timeout' },
    400: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postTaskChatRoute, async (c) => {
  const body = c.req.valid('json')
  // Auth stub: x-user-id header (same pattern as existing routes)
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'

  try {
    const result = await conductGuidedChatTurn(
      {
        messages: body.messages,
        userId,
        availableLists: body.availableLists ?? [], // TODO(impl): fetch from DB when available
        now: new Date(),
      },
      c.env,
    )

    return c.json(ok(result), 200)
  } catch (e) {
    const error = e as NodeJS.ErrnoException
    if (error.code === 'TIMEOUT') {
      return c.json(
        err('UNPROCESSABLE', 'Chat assistant timed out — please try again'),
        422,
      )
    }
    throw e
  }
})

// ── POST /v1/tasks ──────────────────────────────────────────────────────────

const postTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks',
  tags: ['Tasks'],
  summary: 'Create a new task',
  description:
    'Creates a task with title (required), notes, dueDate, listId, sectionId, parentTaskId. ' +
    'If dueDate is null, server applies due date inheritance (FR3): ' +
    'section defaultDueDate > list defaultDueDate.',
  request: {
    body: { content: { 'application/json': { schema: createTaskSchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task created' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(postTaskRoute, async (c) => {
  // TODO(impl): validate listId/sectionId exist, inherit defaultDueDate from section/list
  // if no dueDate provided (FR3), insert via Drizzle
  const body = c.req.valid('json')
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // Fire-and-forget rescheduling — completes within Worker lifetime (NFR-I3)
  try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
  return c.json(
    ok(stubTask({
      title: body.title,
      notes: body.notes ?? null,
      dueDate: body.dueDate ?? null,
      listId: body.listId ?? null,
      sectionId: body.sectionId ?? null,
      parentTaskId: body.parentTaskId ?? null,
      timeWindow: body.timeWindow ?? null,
      timeWindowStart: body.timeWindowStart ?? null,
      timeWindowEnd: body.timeWindowEnd ?? null,
      energyRequirement: body.energyRequirement ?? null,
      priority: body.priority ?? 'normal',
      recurrenceRule: body.recurrenceRule ?? null,
      recurrenceInterval: body.recurrenceInterval ?? null,
      recurrenceDaysOfWeek: body.recurrenceDaysOfWeek ?? null,
      recurrenceParentId: body.recurrenceParentId ?? null,
    })),
    201,
  )
})

// ── GET /v1/tasks ───────────────────────────────────────────────────────────

const getTasksRoute = createRoute({
  method: 'get',
  path: '/v1/tasks',
  tags: ['Tasks'],
  summary: 'Get all tasks for the current user',
  description: 'Returns tasks with cursor-based pagination. Supports filtering by listId, sectionId, archived status.',
  request: {
    query: z.object({
      listId: z.string().uuid().optional(),
      sectionId: z.string().uuid().optional(),
      archived: z.coerce.boolean().optional(),
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskListResponseSchema } }, description: 'Tasks list' },
  },
})

app.openapi(getTasksRoute, async (c) => {
  // TODO(impl): query tasks WHERE assignedToUserId = jwt.sub UNION tasks WHERE userId = jwt.sub; join lists table for listName
  const assignedTask = stubTask({
    id: 'a0000000-0000-4000-8000-000000000002',
    title: 'Clean the kitchen',
    assignedToUserId: 'd0000000-0000-4000-8000-000000000002',
    listId: 'b0000000-0000-4000-8000-000000000001',
    listName: 'Household',
  })
  // Stub: completed task with retained proof to exercise proof indicator in the UI (AC1, FR21)
  const completedProofTask = stubTask({
    id: 'a0000000-0000-4000-8000-000000000003',
    title: 'Morning workout',
    completedAt: '2026-04-01T08:00:00.000Z',
    proofRetained: true,
    proofMediaUrl: 'https://placehold.co/600x400.jpg',
    completedByName: 'Jordan',
    listId: 'b0000000-0000-4000-8000-000000000001',
    listName: 'Household',
  })
  return c.json(list([stubTask(), assignedTask, completedProofTask], null, false), 200)
})

// ── GET /v1/tasks/today ──────────────────────────────────────────────────────

const todayTaskSchema = taskSchema.extend({
  durationMinutes: z.number().int().nullable().openapi({
    example: 30,
    description: 'Estimated duration in minutes. Stub: defaults to 30 for all tasks.',
  }),
  scheduledStartTime: z.string().datetime().nullable().openapi({
    example: '2026-04-01T09:00:00.000Z',
    description: 'Scheduled start time (ISO 8601). Stub: defaults to task dueDate.',
  }),
})

const TodayTaskListResponseSchema = z.object({
  data: z.array(todayTaskSchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const getTodayTasksRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/today',
  tags: ['Tasks'],
  summary: 'Get tasks scheduled for today',
  description:
    'Returns tasks for a given date (defaults to server UTC today), sorted by dueDate ascending. ' +
    'Includes durationMinutes and scheduledStartTime for timeline view rendering.',
  request: {
    query: z.object({
      date: z.string().date().optional(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TodayTaskListResponseSchema } }, description: 'Today tasks list' },
  },
})

app.openapi(getTodayTasksRoute, async (c) => {
  // TODO(impl): filter by userId from JWT, query tasks by date
  const query = c.req.valid('query')
  const dateStr = query.date ?? new Date().toISOString().split('T')[0]
  // Stub: return tasks sorted by dueDate ascending, filtered by date match
  const dueDate = `${dateStr}T09:00:00.000Z`
  const tasks = [{ ...stubTask({ dueDate }), durationMinutes: 30, scheduledStartTime: dueDate }]
  return c.json(list(tasks, null, false), 200)
})

// ── GET /v1/tasks/schedule-health ────────────────────────────────────────────

const ScheduleHealthDaySchema = z.object({
  date: z.string().date(),
  status: z.enum(['healthy', 'at-risk', 'critical']),
  taskCount: z.number().int(),
  capacityPercent: z.number(),
  atRiskTaskIds: z.array(z.string()),
})

const ScheduleHealthResponseSchema = z.object({
  data: z.object({
    days: z.array(ScheduleHealthDaySchema),
  }),
})

const getScheduleHealthRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/schedule-health',
  tags: ['Tasks'],
  summary: 'Get schedule health for a week',
  description:
    'Returns 7-day schedule health starting from the given Monday (weekStartDate). ' +
    'Each day reports healthy/at-risk/critical status.',
  request: {
    query: z.object({
      weekStartDate: z.string().date(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ScheduleHealthResponseSchema } },
      description: 'Weekly schedule health',
    },
  },
})

app.openapi(getScheduleHealthRoute, async (c) => {
  // TODO(impl): real capacity calculation from scheduling engine (Epic 3)
  const { weekStartDate } = c.req.valid('query')
  const startDate = new Date(weekStartDate)
  const days = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(startDate)
    date.setUTCDate(date.getUTCDate() + i)
    return {
      date: date.toISOString().split('T')[0],
      status: 'healthy' as const,
      taskCount: 0,
      capacityPercent: 0,
      atRiskTaskIds: [],
    }
  })
  return c.json(ok({ days }), 200)
})

// ── GET /v1/tasks/current ─────────────────────────────────────────────────────

const currentTaskSchema = taskSchema.extend({
  listName: z.string().nullable(),
  assignorName: z.string().nullable(),
  stakeAmountCents: z.number().int().nullable(),
})

const CurrentTaskResponseSchema = z.object({
  data: currentTaskSchema.nullable(),
})

const getCurrentTaskRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/current',
  tags: ['Tasks'],
  summary: 'Get the current task for the Now tab',
  description:
    'Returns the single current task enriched with list name, assignor, stake amount, and proof mode. ' +
    'Returns { data: null } when no current task (rest state). ' +
    'Pass ?demo=assigned to exercise the attribution path (stub only).',
  request: {
    query: z.object({
      demo: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: CurrentTaskResponseSchema } },
      description: 'Current task or null',
    },
  },
})

app.openapi(getCurrentTaskRoute, async (c) => {
  // TODO(impl): determine actual current task from scheduling engine
  // TODO(impl): look up assignorName from list_members where userId = task.assignedByUserId; resolve listName from lists table
  const { demo } = c.req.valid('query')
  const dateStr = new Date().toISOString().split('T')[0]
  const task = stubTask({ dueDate: `${dateStr}T09:00:00.000Z` })

  if (demo === 'assigned') {
    // Stub: exercise the assigned-task attribution path (AC2)
    return c.json(
      ok({
        ...task,
        title: 'Clean the kitchen',
        listId: 'b0000000-0000-4000-8000-000000000001',
        listName: 'Household',
        assignorName: 'Jordan',
        stakeAmountCents: null,
        proofMode: 'standard' as const,
      }),
      200,
    )
  }

  return c.json(
    ok({
      ...task,
      listName: 'Personal',
      assignorName: null,
      stakeAmountCents: null,
      proofMode: 'standard' as const,
    }),
    200,
  )
})

// ── GET /v1/tasks/:id/prediction ────────────────────────────────────────────
// IMPORTANT: This nested resource route MUST be registered BEFORE /v1/tasks/{id} —
// Hono matches routes in registration order. If {id} comes first, "prediction"
// sub-resource paths would never be reached.

const taskPredictionSchema = z.object({
  taskId: z.string().uuid(),
  predictedDate: z.string().datetime().nullable(),
  status: z.enum(['on_track', 'at_risk', 'behind', 'unknown']),
  tasksRemaining: z.number().int(),
  estimatedMinutesRemaining: z.number().int(),
  availableWindowsCount: z.number().int(),
  reasoning: z.string(),
})

const TaskPredictionResponseSchema = z.object({ data: taskPredictionSchema })

const getTaskPredictionRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/{id}/prediction',
  tags: ['Tasks'],
  summary: 'Get predicted completion for a task',
  description:
    'Returns predicted completion date, status (on_track/at_risk/behind/unknown), and reasoning for a task. ' +
    'Stub returns plausible static data; real implementation comes in Epic 3.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskPredictionResponseSchema } }, description: 'Task prediction' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(getTaskPredictionRoute, async (c) => {
  // TODO(impl): real prediction from scheduling engine (Epic 3)
  const { id } = c.req.valid('param')
  const predictedDate = new Date()
  predictedDate.setUTCDate(predictedDate.getUTCDate() + 7)
  return c.json(
    ok({
      taskId: id,
      predictedDate: predictedDate.toISOString(),
      status: 'on_track' as const,
      tasksRemaining: 3,
      estimatedMinutesRemaining: 90,
      availableWindowsCount: 5,
      reasoning: 'At current pace, this task will be completed before its due date.',
    }),
    200,
  )
})

// ── GET /v1/tasks/search ─────────────────────────────────────────────────────
// IMPORTANT: This named route MUST be registered BEFORE /v1/tasks/{id} —
// Hono matches routes in registration order. If {id} comes first, "search"
// would be treated as a task ID and fail UUID validation.

const searchResultSchema = taskSchema.extend({
  listName: z.string().nullable(),
})

const SearchResultListResponseSchema = z.object({
  data: z.array(searchResultSchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const getTaskSearchRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/search',
  tags: ['Tasks'],
  summary: 'Search tasks across all lists',
  description:
    'Returns tasks matching query text and/or filter criteria. ' +
    'Filters combine with AND logic. Results include listName for display context.',
  request: {
    query: z.object({
      q: z.string().optional(),
      listId: z.string().uuid().optional(),
      status: z.enum(['upcoming', 'overdue', 'completed']).optional(),
      dueDateFrom: z.string().date().optional(),
      dueDateTo: z.string().date().optional(),
      hasStake: z.coerce.boolean().optional(),
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: SearchResultListResponseSchema } },
      description: 'Search results',
    },
  },
})

// Stub search data — diverse tasks for meaningful filter testing
const searchStubTasks = [
  {
    ...stubTask({
      id: 'a0000000-0000-4000-8000-000000000010',
      title: 'Buy groceries',
      notes: 'Milk, eggs, bread from the store',
      listId: 'a0000000-0000-4000-8000-000000000100',
      dueDate: '2026-04-01T09:00:00.000Z',
      completedAt: null,
    }),
    listName: 'Personal',
  },
  {
    ...stubTask({
      id: 'a0000000-0000-4000-8000-000000000011',
      title: 'Finish quarterly report',
      notes: 'Include Q1 revenue figures',
      listId: 'a0000000-0000-4000-8000-000000000101',
      dueDate: '2026-03-28T17:00:00.000Z',
      completedAt: null,
      position: 1,
    }),
    listName: 'Work',
  },
  {
    ...stubTask({
      id: 'a0000000-0000-4000-8000-000000000012',
      title: 'Morning workout',
      notes: null,
      listId: 'a0000000-0000-4000-8000-000000000102',
      dueDate: '2026-04-02T07:00:00.000Z',
      completedAt: '2026-04-02T07:45:00.000Z',
      position: 2,
    }),
    listName: 'Fitness',
  },
  {
    ...stubTask({
      id: 'a0000000-0000-4000-8000-000000000013',
      title: 'Call dentist',
      notes: 'Schedule cleaning appointment',
      listId: 'a0000000-0000-4000-8000-000000000100',
      dueDate: null,
      completedAt: null,
      position: 3,
    }),
    listName: 'Personal',
  },
]

app.openapi(getTaskSearchRoute, async (c) => {
  // TODO(impl): real full-text search via Drizzle ILIKE / tsvector
  const query = c.req.valid('query')
  const nowDate = new Date()

  let results = [...searchStubTasks]

  // Filter by query text (case-insensitive substring match on title and notes)
  if (query.q) {
    const q = query.q.toLowerCase()
    results = results.filter(
      (t) =>
        t.title.toLowerCase().includes(q) ||
        (t.notes && t.notes.toLowerCase().includes(q)),
    )
  }

  // Filter by listId
  if (query.listId) {
    results = results.filter((t) => t.listId === query.listId)
  }

  // Filter by status
  if (query.status) {
    results = results.filter((t) => {
      switch (query.status) {
        case 'completed':
          return t.completedAt !== null
        case 'overdue':
          return (
            t.completedAt === null &&
            t.dueDate !== null &&
            new Date(t.dueDate) < nowDate
          )
        case 'upcoming':
          return (
            t.completedAt === null &&
            (t.dueDate === null || new Date(t.dueDate) >= nowDate)
          )
        default:
          return true
      }
    })
  }

  // Filter by due date range
  if (query.dueDateFrom) {
    const from = new Date(query.dueDateFrom)
    results = results.filter(
      (t) => t.dueDate !== null && new Date(t.dueDate) >= from,
    )
  }
  if (query.dueDateTo) {
    const to = new Date(query.dueDateTo + 'T23:59:59.999Z')
    results = results.filter(
      (t) => t.dueDate !== null && new Date(t.dueDate) <= to,
    )
  }

  // Filter by hasStake (future-proofed — stub has no staked tasks)
  if (query.hasStake) {
    results = results.filter(() => false) // No staked tasks in stub
  }

  return c.json(list(results, null, false), 200)
})

// ── GET /v1/tasks/schedule-changes ──────────────────────────────────────────
// IMPORTANT: Named route MUST be registered BEFORE /v1/tasks/{id} —
// Hono matches routes in registration order.

const scheduleChangeItemSchema = z.object({
  taskId: z.string().uuid(),
  taskTitle: z.string(),
  changeType: z.enum(['moved', 'removed']),
  oldTime: z.string().datetime().nullable(),
  newTime: z.string().datetime().nullable(),
})

const scheduleChangesSchema = z.object({
  hasMeaningfulChanges: z.boolean(),
  changeCount: z.number().int(),
  changes: z.array(scheduleChangeItemSchema),
})

const ScheduleChangesResponseSchema = z.object({ data: scheduleChangesSchema })

const getScheduleChangesRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/schedule-changes',
  tags: ['Tasks'],
  summary: 'Get schedule changes since last view',
  description:
    'Returns schedule change events (moved/removed tasks) since last user view. ' +
    'Stub returns static data; real integration comes in Epic 3.',
  responses: {
    200: {
      content: { 'application/json': { schema: ScheduleChangesResponseSchema } },
      description: 'Schedule changes',
    },
  },
})

app.openapi(getScheduleChangesRoute, async (c) => {
  // TODO(impl): compare current schedule with cached previous snapshot (Epic 3)
  const today = new Date().toISOString().split('T')[0]
  return c.json(
    ok({
      hasMeaningfulChanges: true,
      changeCount: 2,
      changes: [
        {
          taskId: 'a0000000-0000-4000-8000-000000000001',
          taskTitle: 'Morning review',
          changeType: 'moved' as const,
          oldTime: `${today}T09:00:00.000Z`,
          newTime: `${today}T14:00:00.000Z`,
        },
        {
          taskId: 'a0000000-0000-4000-8000-000000000002',
          taskTitle: 'Team sync prep',
          changeType: 'removed' as const,
          oldTime: `${today}T11:00:00.000Z`,
          newTime: null,
        },
      ],
    }),
    200,
  )
})

// ── GET /v1/tasks/overbooking-status ─────────────────────────────────────────
// IMPORTANT: Named route MUST be registered BEFORE /v1/tasks/{id} —
// Hono matches routes in registration order.

const overbookedTaskSchema = z.object({
  taskId: z.string().uuid(),
  taskTitle: z.string(),
  hasStake: z.boolean(),
  durationMinutes: z.number().int(),
})

const overbookingStatusSchema = z.object({
  isOverbooked: z.boolean(),
  severity: z.enum(['none', 'at_risk', 'critical']),
  capacityPercent: z.number(),
  overbookedTasks: z.array(overbookedTaskSchema),
})

const OverbookingStatusResponseSchema = z.object({ data: overbookingStatusSchema })

const getOverbookingStatusRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/overbooking-status',
  tags: ['Tasks'],
  summary: 'Get overbooking status for today',
  description:
    'Returns whether today is overbooked, severity level, and list of overloaded tasks. ' +
    'Stub returns static data; real capacity calculation comes in Epic 3.',
  responses: {
    200: {
      content: { 'application/json': { schema: OverbookingStatusResponseSchema } },
      description: 'Overbooking status',
    },
  },
})

app.openapi(getOverbookingStatusRoute, async (c) => {
  // TODO(impl): real capacity calculation from scheduling engine (Epic 3)
  return c.json(
    ok({
      isOverbooked: true,
      severity: 'at_risk' as const,
      capacityPercent: 115,
      overbookedTasks: [
        {
          taskId: 'a0000000-0000-4000-8000-000000000001',
          taskTitle: 'Deep work block',
          hasStake: true,
          durationMinutes: 120,
        },
      ],
    }),
    200,
  )
})

// ── GET /v1/tasks/:id/proof ──────────────────────────────────────────────────
// IMPORTANT: Registered BEFORE GET /v1/tasks/{id} (catch-all). Specific
// sub-resource paths must come before the parameterized catch-all.

const taskProofResponseSchema = z.object({
  taskId: z.string().uuid(),
  proofMediaUrl: z.string().url().nullable(),
  proofRetained: z.boolean(),
  completedAt: z.string().datetime().nullable(),
  completedByUserId: z.string().uuid().nullable(),
  completedByName: z.string().nullable(),
})

const TaskProofResponseSchema = z.object({ data: taskProofResponseSchema })

const TaskProofForbiddenSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

const getTaskProofRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/{id}/proof',
  tags: ['Tasks'],
  summary: 'Get proof media for a completed task (FR21)',
  description:
    'Returns proof media URL and completion metadata for a task. ' +
    'Access is scoped to members of the shared list only (NFR-S4). ' +
    'Pass ?demo=withProof to exercise the retained-proof path in tests.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    query: z.object({
      demo: z.string().optional(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskProofResponseSchema } }, description: 'Proof data' },
    403: { content: { 'application/json': { schema: TaskProofForbiddenSchema } }, description: 'Not a list member' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(getTaskProofRoute, async (c) => {
  // TODO(impl): verify caller is a list_member for the task's listId before returning the URL.
  // If the task is not in a shared list, only the task owner (userId == jwt.sub) may access it.
  // If proofRetained == false or proofMediaUrl IS NULL in DB: return null.
  // Generate a 15-minute presigned Backblaze B2 URL (NFR-S4) — do NOT store presigned URLs in DB.
  const { id } = c.req.valid('param')
  const { demo } = c.req.valid('query')

  if (demo === 'withProof') {
    // Stub: exercise the retained-proof path — task completed with retained proof
    return c.json(
      ok({
        taskId: id,
        proofMediaUrl: 'https://placehold.co/600x400.jpg',
        proofRetained: true,
        completedAt: '2026-04-01T08:00:00.000Z',
        completedByUserId: 'd0000000-0000-4000-8000-000000000002',
        completedByName: 'Jordan',
      }),
      200,
    )
  }

  // Stub: default path — task not completed or proof not retained
  return c.json(
    ok({
      taskId: id,
      proofMediaUrl: null,
      proofRetained: false,
      completedAt: null,
      completedByUserId: null,
      completedByName: null,
    }),
    200,
  )
})

// ── GET /v1/tasks/:id ───────────────────────────────────────────────────────

const getTaskRoute = createRoute({
  method: 'get',
  path: '/v1/tasks/{id}',
  tags: ['Tasks'],
  summary: 'Get a single task',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task found' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(getTaskRoute, async (c) => {
  // TODO(impl): verify ownership via userId
  const { id } = c.req.valid('param')
  return c.json(ok(stubTask({ id })), 200)
})

// ── PATCH /v1/tasks/:id/proof-mode ──────────────────────────────────────────
// IMPORTANT: Registered BEFORE PATCH /v1/tasks/{id} (catch-all) to prevent
// Hono from matching "proof-mode" as a task ID.

const setTaskProofModeSchema = z.object({
  // Note: 'calendarEvent' is NOT accepted here — read-only from calendar integration (Epic 3)
  proofMode: z.enum(['standard', 'photo', 'watchMode', 'healthKit']),
})

const patchTaskProofModeRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{id}/proof-mode',
  tags: ['Tasks'],
  summary: 'Override the proof mode for a specific task (FR20)',
  description:
    'Sets a per-task proof mode override (proofModeIsCustom = true). ' +
    'This overrides any list- or section-level proof requirement for this task. ' +
    'calendarEvent is NOT accepted — it is set only by calendar integration.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: setTaskProofModeSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Proof mode updated' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error' },
  },
})

app.openapi(patchTaskProofModeRoute, async (c) => {
  // TODO(impl): set proofMode = body.proofMode, proofModeIsCustom = true in tasks table
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  return c.json(ok(stubTask({ id, proofMode: body.proofMode, proofModeIsCustom: true })), 200)
})
// ── PATCH /v1/tasks/:id ─────────────────────────────────────────────────────

const patchTaskRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{id}',
  tags: ['Tasks'],
  summary: 'Update task properties',
  description: 'Accepts partial update of title, notes, dueDate, listId, sectionId, parentTaskId, position.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: updateTaskSchema } }, required: true },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task updated' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(patchTaskRoute, async (c) => {
  // TODO(impl): upsert via Drizzle, validate ownership
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // Fire-and-forget rescheduling — completes within Worker lifetime (NFR-I3)
  try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
  return c.json(ok(stubTask({ id, ...body, dueDate: body.dueDate ?? null })), 200)
})

// ── DELETE /v1/tasks/:id ─────────────────────────────────────────────────────

const deleteTaskRoute = createRoute({
  method: 'delete',
  path: '/v1/tasks/{id}',
  tags: ['Tasks'],
  summary: 'Hard-delete a task',
  description: 'Permanently removes a task and its associated calendar blocks.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Task deleted' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(deleteTaskRoute, async (c) => {
  // TODO(impl): hard-delete task from DB via Drizzle
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // Fire-and-forget rescheduling — stale calendar blocks will be cleaned up (NFR-I3)
  try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
  return new Response(null, { status: 204 })
})

// ── DELETE /v1/tasks/:id/archive ────────────────────────────────────────────

const archiveTaskRoute = createRoute({
  method: 'delete',
  path: '/v1/tasks/{id}/archive',
  tags: ['Tasks'],
  summary: 'Archive a task (soft delete — FR59)',
  description: 'Sets archivedAt = now(). NOT a hard delete — archive only per FR59.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Task archived' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(archiveTaskRoute, async (c) => {
  // TODO(impl): set archivedAt = now() via Drizzle
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // Fire-and-forget rescheduling — stale calendar blocks will be cleaned up (NFR-I3)
  try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
  return new Response(null, { status: 204 })
})

// ── PATCH /v1/tasks/:id/reorder ─────────────────────────────────────────────

const reorderTaskRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{id}/reorder',
  tags: ['Tasks'],
  summary: 'Reorder a task',
  description: 'Updates position, shifts sibling positions.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: {
      content: {
        'application/json': {
          schema: z.object({ position: z.number().int() }),
        },
      },
      required: true,
    },
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task reordered' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(reorderTaskRoute, async (c) => {
  // TODO(impl): update position, shift sibling positions
  const { id } = c.req.valid('param')
  const { position } = c.req.valid('json')
  return c.json(ok(stubTask({ id, position })), 200)
})

// ── POST /v1/tasks/:id/complete ────────────────────────────────────────────

/**
 * Computes the next due date for a recurring task.
 * If the completed task has no dueDate, computes from now().
 */
function computeNextDueDate(
  recurrenceRule: string,
  baseDateStr: string | null,
  recurrenceInterval: number | null,
  recurrenceDaysOfWeek: string | null,
): string {
  const baseDate = baseDateStr ? new Date(baseDateStr) : new Date()

  switch (recurrenceRule) {
    case 'daily': {
      baseDate.setUTCDate(baseDate.getUTCDate() + 1)
      return baseDate.toISOString()
    }
    case 'weekly': {
      // Parse days of week from JSON string
      const days: number[] = recurrenceDaysOfWeek ? JSON.parse(recurrenceDaysOfWeek) : []
      if (days.length === 0) {
        // Fallback: next week same day
        baseDate.setUTCDate(baseDate.getUTCDate() + 7)
        return baseDate.toISOString()
      }
      // ISO: Mon=1..Sun=7; JS getUTCDay(): Sun=0..Sat=6
      // Convert JS day to ISO day
      const nextDay = new Date(baseDate)
      nextDay.setUTCDate(nextDay.getUTCDate() + 1) // start from day after
      for (let i = 0; i < 7; i++) {
        const jsDay = nextDay.getUTCDay()
        const isoDay = jsDay === 0 ? 7 : jsDay
        if (days.includes(isoDay)) {
          return nextDay.toISOString()
        }
        nextDay.setUTCDate(nextDay.getUTCDate() + 1)
      }
      // Should not reach here, but fallback
      baseDate.setUTCDate(baseDate.getUTCDate() + 7)
      return baseDate.toISOString()
    }
    case 'monthly': {
      const day = baseDate.getUTCDate()
      baseDate.setUTCMonth(baseDate.getUTCMonth() + 1)
      // Clamp to month end if needed (e.g., Jan 31 -> Feb 28)
      if (baseDate.getUTCDate() !== day) {
        baseDate.setUTCDate(0) // last day of previous month
      }
      return baseDate.toISOString()
    }
    case 'custom': {
      const interval = recurrenceInterval ?? 1
      baseDate.setUTCDate(baseDate.getUTCDate() + interval)
      return baseDate.toISOString()
    }
    default:
      baseDate.setUTCDate(baseDate.getUTCDate() + 1)
      return baseDate.toISOString()
  }
}

const completeTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{id}/complete',
  tags: ['Tasks'],
  summary: 'Complete a task',
  description:
    'Sets completedAt = now(). For recurring tasks, returns both the completed task and an auto-generated next instance.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: CompleteTaskResponseSchema } },
      description: 'Task completed; next instance returned for recurring tasks',
    },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(completeTaskRoute, async (c) => {
  // TODO(impl): look up real task from DB, set completedAt via Drizzle
  const { id } = c.req.valid('param')
  const userId = c.req.header('x-user-id') ?? 'stub-user-id'
  // Fire-and-forget rescheduling — completes within Worker lifetime (NFR-I3)
  try { c.executionCtx.waitUntil(runScheduleForUser(userId, c.env)) } catch { /* no executionCtx in test */ }
  const completedTask = stubTask({
    id,
    completedAt: new Date().toISOString(),
  })

  // If recurring, generate next instance
  let nextInstance: z.infer<typeof taskSchema> | null = null
  if (completedTask.recurrenceRule) {
    const seriesParentId = completedTask.recurrenceParentId ?? completedTask.id
    const nextDueDate = computeNextDueDate(
      completedTask.recurrenceRule,
      completedTask.dueDate,
      completedTask.recurrenceInterval,
      completedTask.recurrenceDaysOfWeek,
    )
    // Copy all properties except id, completedAt, createdAt, updatedAt, dueDate
    nextInstance = stubTask({
      id: 'a0000000-0000-4000-8000-000000000099',
      userId: completedTask.userId,
      listId: completedTask.listId,
      sectionId: completedTask.sectionId,
      parentTaskId: completedTask.parentTaskId,
      title: completedTask.title,
      notes: completedTask.notes,
      position: completedTask.position,
      timeWindow: completedTask.timeWindow,
      timeWindowStart: completedTask.timeWindowStart,
      timeWindowEnd: completedTask.timeWindowEnd,
      energyRequirement: completedTask.energyRequirement,
      priority: completedTask.priority,
      recurrenceRule: completedTask.recurrenceRule,
      recurrenceInterval: completedTask.recurrenceInterval,
      recurrenceDaysOfWeek: completedTask.recurrenceDaysOfWeek,
      recurrenceParentId: seriesParentId,
      dueDate: nextDueDate,
      completedAt: null,
    })
  }

  return c.json({ data: { completedTask, nextInstance } }, 200)
})

// ── POST /v1/tasks/:id/start ──────────────────────────────────────────────

const startTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{id}/start',
  tags: ['Tasks'],
  summary: 'Start a task timer',
  description: 'Sets startedAt = now(), marking the task as actively in-progress (FR76).',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task timer started' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(startTaskRoute, async (c) => {
  // TODO(impl): look up real task from DB, set startedAt via Drizzle
  const { id } = c.req.valid('param')
  return c.json(
    ok(stubTask({ id, startedAt: new Date().toISOString() })),
    200,
  )
})

// ── POST /v1/tasks/:id/pause ──────────────────────────────────────────────

const pauseTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{id}/pause',
  tags: ['Tasks'],
  summary: 'Pause a task timer',
  description:
    'Computes elapsedSeconds += diff(now, startedAt), clears startedAt. Timer can be resumed later.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task timer paused' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(pauseTaskRoute, async (c) => {
  // TODO(impl): look up real task from DB, compute elapsed, update via Drizzle
  const { id } = c.req.valid('param')
  // Stub: simulate 120 seconds of elapsed time
  return c.json(
    ok(stubTask({ id, startedAt: null, elapsedSeconds: 120 })),
    200,
  )
})

// ── POST /v1/tasks/:id/stop ───────────────────────────────────────────────

const stopTaskRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{id}/stop',
  tags: ['Tasks'],
  summary: 'Stop a task timer',
  description:
    'Computes elapsedSeconds += diff(now, startedAt), clears startedAt. ' +
    'Stopping the timer does NOT mark the task as complete — that requires POST /complete.',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: { content: { 'application/json': { schema: TaskResponseSchema } }, description: 'Task timer stopped' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Task not found' },
  },
})

app.openapi(stopTaskRoute, async (c) => {
  // TODO(impl): look up real task from DB, compute elapsed, update via Drizzle
  const { id } = c.req.valid('param')
  // Stub: simulate 300 seconds of elapsed time
  return c.json(
    ok(stubTask({ id, startedAt: null, elapsedSeconds: 300 })),
    200,
  )
})

export { app as tasksRouter }
