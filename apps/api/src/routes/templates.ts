import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

// ── Templates router ─────────────────────────────────────────────────────────
// CRUD routes for task templates (FR78).
// Templates capture a JSON snapshot of a list or section structure for reuse.
// Stub responses with TODO(impl) markers for real Drizzle implementation.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createTemplateSchema = z.object({
  title: z.string().min(1).openapi({ example: 'Sprint planning template' }),
  sourceType: z.enum(['list', 'section']).openapi({ example: 'list' }),
  sourceId: z.string().uuid().openapi({
    description: 'ID of the list or section to snapshot',
  }),
})

const applyTemplateSchema = z.object({
  targetListId: z.string().uuid().optional().openapi({
    description: 'List to apply section template into (required for section templates)',
  }),
  parentSectionId: z.string().uuid().optional().openapi({
    description: 'Parent section to nest under (optional)',
  }),
  dueDateOffsetDays: z.number().int().min(0).optional().openapi({
    example: 7,
    description: 'Number of days from today to offset due dates. If 0 or omitted, keeps original dates.',
  }),
})

const templateSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  title: z.string(),
  sourceType: z.enum(['list', 'section']),
  templateData: z.string().openapi({
    description: 'JSON string containing the full structure snapshot',
  }),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const templateSummarySchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  title: z.string(),
  sourceType: z.enum(['list', 'section']),
  createdAt: z.string().datetime(),
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
  archivedAt: z.string().datetime().nullable(),
  completedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const sectionResponseSchema = z.object({
  id: z.string().uuid(),
  listId: z.string().uuid(),
  parentSectionId: z.string().uuid().nullable(),
  title: z.string(),
  defaultDueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const listResponseSchema = z.object({
  id: z.string().uuid(),
  userId: z.string().uuid(),
  title: z.string(),
  defaultDueDate: z.string().datetime().nullable(),
  position: z.number().int(),
  archivedAt: z.string().datetime().nullable(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
})

const TemplateResponseSchema = z.object({ data: templateSchema })
const TemplateSummaryListResponseSchema = z.object({
  data: z.array(templateSummarySchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const ApplyTemplateResponseSchema = z.object({
  data: z.object({
    list: listResponseSchema.optional(),
    sections: z.array(sectionResponseSchema),
    tasks: z.array(taskSchema),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── Stub fixtures ───────────────────────────────────────────────────────────

const now = '2026-03-30T12:00:00.000Z'

const stubTemplateData = JSON.stringify({
  sections: [
    {
      title: 'Sprint backlog',
      defaultDueDate: '2026-04-01T09:00:00.000Z',
      position: 0,
      parentSectionIndex: null,
      tasks: [
        {
          title: 'Design review',
          notes: 'Check all mockups',
          dueDate: '2026-04-05T09:00:00.000Z',
          position: 0,
          timeWindow: 'morning',
          timeWindowStart: null,
          timeWindowEnd: null,
          energyRequirement: 'high_focus',
          priority: 'high',
          recurrenceRule: null,
          recurrenceInterval: null,
          recurrenceDaysOfWeek: null,
        },
      ],
      childSections: [],
    },
  ],
  rootTasks: [
    {
      title: 'Kick-off meeting',
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
    },
  ],
})

function stubTemplate(
  overrides: Partial<z.infer<typeof templateSchema>> = {},
): z.infer<typeof templateSchema> {
  return {
    id: 'c0000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-a000-000000000001',
    title: 'Sprint planning template',
    sourceType: 'list',
    templateData: stubTemplateData,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  }
}

function stubTemplateSummary(
  overrides: Partial<z.infer<typeof templateSummarySchema>> = {},
): z.infer<typeof templateSummarySchema> {
  return {
    id: 'c0000000-0000-4000-8000-000000000001',
    userId: '00000000-0000-4000-a000-000000000001',
    title: 'Sprint planning template',
    sourceType: 'list',
    createdAt: now,
    ...overrides,
  }
}

// ── POST /v1/templates ──────────────────────────────────────────────────────

const postTemplateRoute = createRoute({
  method: 'post',
  path: '/v1/templates',
  tags: ['Templates'],
  summary: 'Create a template from a list or section',
  description:
    'Snapshots the full structure (sections, tasks, hierarchy) of a list or section ' +
    'and stores it as a reusable template.',
  request: {
    body: {
      content: { 'application/json': { schema: createTemplateSchema } },
      required: true,
    },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: TemplateResponseSchema } },
      description: 'Template created',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Validation error',
    },
  },
})

app.openapi(postTemplateRoute, async (c) => {
  // TODO(impl): fetch list/section structure from DB, snapshot as JSON, insert template
  const body = c.req.valid('json')
  return c.json(
    ok(
      stubTemplate({
        title: body.title,
        sourceType: body.sourceType,
      }),
    ),
    201,
  )
})

// ── GET /v1/templates ───────────────────────────────────────────────────────

const getTemplatesRoute = createRoute({
  method: 'get',
  path: '/v1/templates',
  tags: ['Templates'],
  summary: 'Get all templates for the current user',
  description: 'Returns template summaries (excludes large templateData).',
  request: {
    query: z.object({
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: {
        'application/json': { schema: TemplateSummaryListResponseSchema },
      },
      description: 'Template list',
    },
  },
})

app.openapi(getTemplatesRoute, async (c) => {
  // TODO(impl): filter by userId from JWT, cursor-based pagination
  return c.json(list([stubTemplateSummary()], null, false), 200)
})

// ── GET /v1/templates/:id ───────────────────────────────────────────────────

const getTemplateRoute = createRoute({
  method: 'get',
  path: '/v1/templates/{id}',
  tags: ['Templates'],
  summary: 'Get a single template with full templateData',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: TemplateResponseSchema } },
      description: 'Template found',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Template not found',
    },
  },
})

app.openapi(getTemplateRoute, async (c) => {
  // TODO(impl): verify ownership via userId
  const { id } = c.req.valid('param')
  return c.json(ok(stubTemplate({ id })), 200)
})

// ── POST /v1/templates/:id/apply ────────────────────────────────────────────

const applyTemplateRoute = createRoute({
  method: 'post',
  path: '/v1/templates/{id}/apply',
  tags: ['Templates'],
  summary: 'Apply a template to create new lists/sections/tasks',
  description:
    'Creates a copy of the template structure with all tasks in "not started" state ' +
    '(completedAt = null). Due dates can be offset by a user-specified number of days.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: {
      content: { 'application/json': { schema: applyTemplateSchema } },
      required: true,
    },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: ApplyTemplateResponseSchema } },
      description: 'Template applied — created structure returned',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Template not found',
    },
  },
})

app.openapi(applyTemplateRoute, async (c) => {
  // TODO(impl): parse templateData, create entities with new UUIDs, offset due dates
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')

  // Parse the stub template data
  const templateData = JSON.parse(stubTemplateData)
  const offsetDays = body.dueDateOffsetDays

  // Helper to offset a date string
  function offsetDate(dateStr: string | null): string | null {
    if (!dateStr || !offsetDays) return dateStr

    // Find earliest date to compute offset base
    const allDates: string[] = []
    for (const section of templateData.sections) {
      for (const task of section.tasks) {
        if (task.dueDate) allDates.push(task.dueDate)
      }
    }
    for (const task of templateData.rootTasks) {
      if (task.dueDate) allDates.push(task.dueDate)
    }

    if (allDates.length === 0) return dateStr

    const minDate = new Date(
      Math.min(...allDates.map((d) => new Date(d).getTime())),
    )
    const today = new Date(now) // stub uses fixed "now"
    const offsetBase = today.getTime() - minDate.getTime()
    const date = new Date(dateStr)
    date.setTime(
      date.getTime() + offsetBase + offsetDays * 24 * 60 * 60 * 1000,
    )
    return date.toISOString()
  }

  const stubUserId = '00000000-0000-4000-a000-000000000001'
  const newListId = 'd0000000-0000-4000-8000-000000000001'

  // Build stub task responses
  const tasks: z.infer<typeof taskSchema>[] = []
  const sections: z.infer<typeof sectionResponseSchema>[] = []
  let taskIndex = 1
  let sectionIndex = 1

  for (const section of templateData.sections) {
    const sectionId = `d0000000-0000-4000-8000-0000000000${String(sectionIndex + 10).padStart(2, '0')}`
    sections.push({
      id: sectionId,
      listId: newListId,
      parentSectionId: null,
      title: section.title,
      defaultDueDate: section.defaultDueDate ?? null,
      position: section.position,
      createdAt: now,
      updatedAt: now,
    })
    sectionIndex++

    for (const task of section.tasks) {
      tasks.push({
        id: `d0000000-0000-4000-8000-0000000000${String(taskIndex + 50).padStart(2, '0')}`,
        userId: stubUserId,
        listId: newListId,
        sectionId,
        parentTaskId: null,
        title: task.title,
        notes: task.notes ?? null,
        dueDate: offsetDate(task.dueDate),
        position: task.position,
        timeWindow: task.timeWindow ?? null,
        timeWindowStart: task.timeWindowStart ?? null,
        timeWindowEnd: task.timeWindowEnd ?? null,
        energyRequirement: task.energyRequirement ?? null,
        priority: task.priority ?? 'normal',
        recurrenceRule: task.recurrenceRule ?? null,
        recurrenceInterval: task.recurrenceInterval ?? null,
        recurrenceDaysOfWeek: task.recurrenceDaysOfWeek ?? null,
        recurrenceParentId: null,
        archivedAt: null,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      })
      taskIndex++
    }
  }

  for (const task of templateData.rootTasks) {
    tasks.push({
      id: `d0000000-0000-4000-8000-0000000000${String(taskIndex + 50).padStart(2, '0')}`,
      userId: stubUserId,
      listId: newListId,
      sectionId: null,
      parentTaskId: null,
      title: task.title,
      notes: task.notes ?? null,
      dueDate: offsetDate(task.dueDate),
      position: task.position,
      timeWindow: task.timeWindow ?? null,
      timeWindowStart: task.timeWindowStart ?? null,
      timeWindowEnd: task.timeWindowEnd ?? null,
      energyRequirement: task.energyRequirement ?? null,
      priority: task.priority ?? 'normal',
      recurrenceRule: task.recurrenceRule ?? null,
      recurrenceInterval: task.recurrenceInterval ?? null,
      recurrenceDaysOfWeek: task.recurrenceDaysOfWeek ?? null,
      recurrenceParentId: null,
      archivedAt: null,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    })
    taskIndex++
  }

  return c.json(
    ok({
      list: {
        id: newListId,
        userId: stubUserId,
        title: 'From template',
        defaultDueDate: null,
        position: 0,
        archivedAt: null,
        createdAt: now,
        updatedAt: now,
      },
      sections,
      tasks,
    }),
    201,
  )
})

// ── DELETE /v1/templates/:id ────────────────────────────────────────────────

const deleteTemplateRoute = createRoute({
  method: 'delete',
  path: '/v1/templates/{id}',
  tags: ['Templates'],
  summary: 'Delete a template',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Template deleted' },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Template not found',
    },
  },
})

app.openapi(deleteTemplateRoute, async (c) => {
  // TODO(impl): verify ownership, delete via Drizzle
  return new Response(null, { status: 204 })
})

export { app as templatesRouter }
