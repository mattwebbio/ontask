import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok } from '../lib/response.js'

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

const HealthResponseSchema = z.object({
  data: z.object({
    status: z.string().openapi({ example: 'ok' }),
  }),
})

const healthRoute = createRoute({
  method: 'get',
  path: '/v1/health',
  tags: ['System'],
  summary: 'Health check',
  description: 'Returns the operational status of the API worker.',
  responses: {
    200: {
      content: {
        'application/json': {
          schema: HealthResponseSchema,
        },
      },
      description: 'API is healthy',
    },
  },
})

app.openapi(healthRoute, (c) => {
  return c.json(ok({ status: 'ok' }))
})

export { app as healthRouter }
