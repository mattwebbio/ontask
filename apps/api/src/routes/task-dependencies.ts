import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Task Dependencies router ──────────────────────────────────────────────
// CRUD routes for task dependency relationships (FR73).
// Dependencies are directional: Task B (dependent) depends on Task A (prerequisite).

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const createDependencySchema = z.object({
  dependentTaskId: z.string().uuid().openapi({
    example: 'a0000000-0000-4000-8000-000000000002',
    description: 'The task that depends on another (Task B — the one that waits)',
  }),
  dependsOnTaskId: z.string().uuid().openapi({
    example: 'a0000000-0000-4000-8000-000000000001',
    description: 'The prerequisite task (Task A — must complete first)',
  }),
})

const dependencySchema = z.object({
  id: z.string().uuid(),
  dependentTaskId: z.string().uuid(),
  dependsOnTaskId: z.string().uuid(),
  createdAt: z.string().datetime(),
})

const DependencyResponseSchema = z.object({ data: dependencySchema })

const DependencyListResponseSchema = z.object({
  data: z.object({
    dependsOn: z.array(dependencySchema),
    blocks: z.array(dependencySchema),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── Stub fixtures ───────────────────────────────────────────────────────────

const now = '2026-03-30T12:00:00.000Z'

function stubDependency(overrides: Partial<z.infer<typeof dependencySchema>> = {}): z.infer<typeof dependencySchema> {
  return {
    id: 'b0000000-0000-4000-8000-000000000001',
    dependentTaskId: 'a0000000-0000-4000-8000-000000000002',
    dependsOnTaskId: 'a0000000-0000-4000-8000-000000000001',
    createdAt: now,
    ...overrides,
  }
}

// ── POST /v1/task-dependencies ──────────────────────────────────────────────

const postDependencyRoute = createRoute({
  method: 'post',
  path: '/v1/task-dependencies',
  tags: ['Task Dependencies'],
  summary: 'Create a dependency between two tasks',
  description:
    'Creates a directional dependency: dependentTaskId depends on dependsOnTaskId. ' +
    'Validates no self-dependency. Circular dependency detection is deferred.',
  request: {
    body: { content: { 'application/json': { schema: createDependencySchema } }, required: true },
  },
  responses: {
    201: { content: { 'application/json': { schema: DependencyResponseSchema } }, description: 'Dependency created' },
    422: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Validation error (e.g. self-dependency)' },
  },
})

app.openapi(postDependencyRoute, async (c) => {
  const body = c.req.valid('json')

  // Validate no self-dependency
  if (body.dependentTaskId === body.dependsOnTaskId) {
    return c.json(err('SELF_DEPENDENCY', 'A task cannot depend on itself'), 422)
  }

  // TODO(impl): insert into task_dependencies table via Drizzle, check unique constraint
  return c.json(
    ok(stubDependency({
      dependentTaskId: body.dependentTaskId,
      dependsOnTaskId: body.dependsOnTaskId,
    })),
    201,
  )
})

// ── GET /v1/task-dependencies ───────────────────────────────────────────────

const getDependenciesRoute = createRoute({
  method: 'get',
  path: '/v1/task-dependencies',
  tags: ['Task Dependencies'],
  summary: 'Get all dependencies for a task',
  description:
    'Returns dependencies in both directions: tasks this one depends on (dependsOn) ' +
    'and tasks this one blocks (blocks).',
  request: {
    query: z.object({
      taskId: z.string().uuid(),
    }),
  },
  responses: {
    200: { content: { 'application/json': { schema: DependencyListResponseSchema } }, description: 'Dependencies for task' },
  },
})

app.openapi(getDependenciesRoute, async (c) => {
  const { taskId } = c.req.valid('query')

  // TODO(impl): query task_dependencies where dependentTaskId = taskId OR dependsOnTaskId = taskId
  // Stub: return empty lists
  return c.json(
    ok({
      dependsOn: [] as z.infer<typeof dependencySchema>[],
      blocks: [] as z.infer<typeof dependencySchema>[],
    }),
    200,
  )
})

// ── DELETE /v1/task-dependencies/:id ────────────────────────────────────────

const deleteDependencyRoute = createRoute({
  method: 'delete',
  path: '/v1/task-dependencies/{id}',
  tags: ['Task Dependencies'],
  summary: 'Remove a dependency',
  request: {
    params: z.object({ id: z.string().uuid() }),
  },
  responses: {
    204: { description: 'Dependency removed' },
    404: { content: { 'application/json': { schema: ErrorSchema } }, description: 'Dependency not found' },
  },
})

app.openapi(deleteDependencyRoute, async (c) => {
  // TODO(impl): delete from task_dependencies via Drizzle
  return new Response(null, { status: 204 })
})

export { app as taskDependenciesRouter }
