import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, list, err } from '../lib/response.js'

// ── Sharing router ───────────────────────────────────────────────────────────
// List sharing invitation endpoints (FR15, FR16, FR86).
// Stub responses with TODO(impl) markers for real Drizzle implementation.

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ──────────────────────────────────────────────────────

const shareListSchema = z.object({
  email: z.string().email().openapi({ example: 'sam@example.com' }),
})

const invitationSchema = z.object({
  invitationId: z.string().uuid(),
  listId: z.string().uuid(),
  inviteeEmail: z.string().email(),
  status: z.enum(['pending', 'accepted', 'declined']),
  expiresAt: z.string().datetime(),
})

const invitationDetailsSchema = z.object({
  listId: z.string().uuid(),
  listTitle: z.string(),
  invitedByName: z.string(),
  inviteeEmail: z.string().email(),
  status: z.enum(['pending', 'accepted', 'declined']),
  expiresAt: z.string().datetime(),
})

const acceptInvitationResponseSchema = z.object({
  listId: z.string().uuid(),
  listTitle: z.string(),
  invitedByName: z.string(),
  membershipId: z.string().uuid(),
})

const listMemberSchema = z.object({
  userId: z.string().uuid(),
  displayName: z.string(),
  avatarInitials: z.string(),
  role: z.enum(['owner', 'member']),
  joinedAt: z.string().datetime(),
  roundRobinIndex: z.number().int(),
})

const InvitationResponseSchema = z.object({ data: invitationSchema })
const InvitationDetailsResponseSchema = z.object({ data: invitationDetailsSchema })
const AcceptResponseSchema = z.object({ data: acceptInvitationResponseSchema })

const MembersListResponseSchema = z.object({
  data: z.array(listMemberSchema),
  pagination: z.object({
    cursor: z.string().nullable(),
    hasMore: z.boolean(),
  }),
})

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── Stub fixtures ───────────────────────────────────────────────────────────

const now = new Date().toISOString()
const future = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()

function stubInvitation(
  listId: string,
  email: string
): z.infer<typeof invitationSchema> {
  return {
    invitationId: 'c0000000-0000-4000-8000-000000000001',
    listId,
    inviteeEmail: email,
    status: 'pending',
    expiresAt: future,
  }
}

function stubInvitationDetails(): z.infer<typeof invitationDetailsSchema> {
  return {
    listId: 'b0000000-0000-4000-8000-000000000001',
    listTitle: 'Household Chores',
    invitedByName: 'Jordan',
    inviteeEmail: 'sam@example.com',
    status: 'pending',
    expiresAt: future,
  }
}

function stubAcceptResponse(listId: string): z.infer<typeof acceptInvitationResponseSchema> {
  return {
    listId,
    listTitle: 'Household Chores',
    invitedByName: 'Jordan',
    membershipId: 'd0000000-0000-4000-8000-000000000099',
  }
}

function stubMembers(): z.infer<typeof listMemberSchema>[] {
  return [
    {
      userId: 'd0000000-0000-4000-8000-000000000001',
      displayName: 'Jordan',
      avatarInitials: 'J',
      role: 'owner',
      joinedAt: now,
      roundRobinIndex: 0,
    },
    {
      userId: 'd0000000-0000-4000-8000-000000000002',
      displayName: 'Sam',
      avatarInitials: 'S',
      role: 'member',
      joinedAt: now,
      roundRobinIndex: 1,
    },
  ]
}

// ── POST /v1/lists/:id/share ─────────────────────────────────────────────────
// Sends an invitation to the given email address to join the list.

const shareListRoute = createRoute({
  method: 'post',
  path: '/v1/lists/{id}/share',
  tags: ['Sharing'],
  summary: 'Invite a user to share a list',
  description:
    'Creates an invitation for the given email address to join the list. ' +
    'Stub implementation: logs intent, no real email sent (Story 5.1). ' +
    'Real email delivery and token generation in a future hardening pass.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: shareListSchema } }, required: true },
  },
  responses: {
    201: {
      content: { 'application/json': { schema: InvitationResponseSchema } },
      description: 'Invitation created',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'List not found',
    },
    409: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invitation already pending for this email',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Validation error',
    },
  },
})

app.openapi(shareListRoute, async (c) => {
  // TODO(impl): verify list ownership from JWT, insert invitation via Drizzle,
  //             generate secure token, send invitation email via email service
  const { id } = c.req.valid('param')
  const { email } = c.req.valid('json')
  console.log(`[stub] Invitation for list ${id} to ${email} — email delivery not yet implemented`)
  return c.json(ok(stubInvitation(id, email)), 201)
})

// ── GET /v1/invitations/:token ───────────────────────────────────────────────
// Returns invitation details for display on the accept screen.
// IMPORTANT: Registered BEFORE POST /v1/invitations/:token/accept to avoid path conflicts.

const getInvitationRoute = createRoute({
  method: 'get',
  path: '/v1/invitations/{token}',
  tags: ['Sharing'],
  summary: 'Get invitation details by token',
  description:
    'Returns the list name and inviter name for display on the invitation accept screen (FR16).',
  request: {
    params: z.object({ token: z.string() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: InvitationDetailsResponseSchema } },
      description: 'Invitation details',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invitation not found or expired',
    },
  },
})

app.openapi(getInvitationRoute, async (c) => {
  // TODO(impl): look up invitation by token via Drizzle, check expiry
  const { token } = c.req.valid('param')
  console.log(`[stub] Getting invitation details for token: ${token}`)
  return c.json(ok(stubInvitationDetails()), 200)
})

// ── POST /v1/invitations/:token/accept ───────────────────────────────────────
// Accepts the invitation — adds the current user as a list member.

const acceptInvitationRoute = createRoute({
  method: 'post',
  path: '/v1/invitations/{token}/accept',
  tags: ['Sharing'],
  summary: 'Accept a list sharing invitation',
  description:
    'Marks the invitation as accepted and adds the authenticated user as a list member (FR16).',
  request: {
    params: z.object({ token: z.string() }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AcceptResponseSchema } },
      description: 'Invitation accepted',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invitation not found or expired',
    },
    409: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Already a member of this list',
    },
  },
})

app.openapi(acceptInvitationRoute, async (c) => {
  // TODO(impl): verify token, check expiry, insert list_member row via Drizzle,
  //             update invitation status to 'accepted'
  const { token } = c.req.valid('param')
  console.log(`[stub] Accepting invitation token: ${token}`)
  return c.json(ok(stubAcceptResponse('b0000000-0000-4000-8000-000000000001')), 200)
})

// ── POST /v1/invitations/:token/decline ─────────────────────────────────────
// Declines the invitation — marks it as declined, no list_member row created.

const declineInvitationRoute = createRoute({
  method: 'post',
  path: '/v1/invitations/{token}/decline',
  tags: ['Sharing'],
  summary: 'Decline a list sharing invitation',
  description: 'Marks the invitation as declined (FR16).',
  request: {
    params: z.object({ token: z.string() }),
  },
  responses: {
    204: { description: 'Invitation declined' },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Invitation not found',
    },
  },
})

app.openapi(declineInvitationRoute, async (c) => {
  // TODO(impl): verify token, update invitation status to 'declined' via Drizzle
  const { token } = c.req.valid('param')
  console.log(`[stub] Declining invitation token: ${token}`)
  return new Response(null, { status: 204 })
})

// ── POST /v1/lists/:id/assign ────────────────────────────────────────────────
// Manually assigns a specific task to a specific member (FR18).
// IMPORTANT: Registered BEFORE GET /v1/lists/{id}/members to avoid path conflicts.

const assignTaskSchema = z.object({
  taskId: z.string().uuid(),
  assignedToUserId: z.string().uuid(),
})

const assignTaskResponseSchema = z.object({
  taskId: z.string().uuid(),
  assignedToUserId: z.string().uuid(),
  listId: z.string().uuid(),
})

const AssignTaskResponseSchema = z.object({ data: assignTaskResponseSchema })

const assignTaskRoute = createRoute({
  method: 'post',
  path: '/v1/lists/{id}/assign',
  tags: ['Sharing'],
  summary: 'Manually assign a task to a member',
  description:
    'Assigns a specific task to a specific member of the list. ' +
    'Enforces FR18: a task can only be assigned to one member per due-date window.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: assignTaskSchema } }, required: true },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AssignTaskResponseSchema } },
      description: 'Task assigned',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'List or task not found',
    },
    409: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Task already assigned to a different member in the same due-date window (FR18)',
    },
    422: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Task does not belong to this list',
    },
  },
})

app.openapi(assignTaskRoute, async (c) => {
  // TODO(impl): verify membership from JWT, enforce FR18 uniqueness constraint,
  //             write assignedToUserId to tasks table via Drizzle
  const { id } = c.req.valid('param')
  const body = c.req.valid('json')
  console.log(`[stub] Assigning task ${body.taskId} to user ${body.assignedToUserId} in list ${id}`)
  return c.json(ok({ taskId: body.taskId, assignedToUserId: body.assignedToUserId, listId: id }), 200)
})

// ── POST /v1/lists/:id/auto-assign ───────────────────────────────────────────
// Trigger strategy-based auto-assignment for all unassigned tasks in a list (FR17).

const autoAssignResponseSchema = z.object({
  assigned: z.number().int(),
  strategy: z.string(),
  assignments: z.array(z.object({
    taskId: z.string().uuid(),
    assignedToUserId: z.string().uuid(),
  })),
})

const AutoAssignResponseSchema = z.object({ data: autoAssignResponseSchema })

const autoAssignRoute = createRoute({
  method: 'post',
  path: '/v1/lists/{id}/auto-assign',
  tags: ['Sharing'],
  summary: 'Auto-assign all unassigned tasks using the configured strategy',
  description:
    'Triggers strategy-based assignment (round-robin, least-busy, or ai-assisted) ' +
    'for all unassigned tasks in the list. Enforces FR18: no duplicate assignments per window.',
  request: {
    params: z.object({ id: z.string().uuid() }),
    body: { content: { 'application/json': { schema: z.object({}) } }, required: false },
  },
  responses: {
    200: {
      content: { 'application/json': { schema: AutoAssignResponseSchema } },
      description: 'Auto-assignment complete',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'No assignment strategy configured on this list',
    },
    403: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Caller is not the list owner',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'List not found',
    },
  },
})

app.openapi(autoAssignRoute, async (c) => {
  // TODO(impl): implement round-robin, least-busy, AI-assisted logic;
  //             enforce FR18 uniqueness; read strategy from lists table via Drizzle
  const { id } = c.req.valid('param')
  const members = stubMembers()
  console.log(`[stub] Auto-assigning tasks for list ${id}`)
  return c.json(
    ok({
      assigned: 2,
      strategy: 'round-robin',
      assignments: [
        { taskId: 'a0000000-0000-4000-8000-000000000001', assignedToUserId: members[0].userId },
        { taskId: 'a0000000-0000-4000-8000-000000000002', assignedToUserId: members[1].userId },
      ],
    }),
    200,
  )
})

// ── GET /v1/lists/:id/members ────────────────────────────────────────────────
// Returns all members of a shared list.

const getListMembersRoute = createRoute({
  method: 'get',
  path: '/v1/lists/{id}/members',
  tags: ['Sharing'],
  summary: 'Get all members of a shared list',
  description: 'Returns member list for shared indicator display in Lists tab (FR15, FR16).',
  request: {
    params: z.object({ id: z.string().uuid() }),
    query: z.object({
      cursor: z.string().optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: MembersListResponseSchema } },
      description: 'List members',
    },
    404: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'List not found',
    },
  },
})

app.openapi(getListMembersRoute, async (c) => {
  // TODO(impl): filter by listId, verify membership from JWT, cursor pagination
  const { id } = c.req.valid('param')
  console.log(`[stub] Getting members for list: ${id}`)
  return c.json(list(stubMembers(), null, false), 200)
})

export { app as sharingRouter }
