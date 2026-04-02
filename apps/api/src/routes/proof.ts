import { OpenAPIHono, createRoute } from '@hono/zod-openapi'
import { z } from 'zod'
import { ok, err } from '../lib/response.js'

// ── Proof submission router ───────────────────────────────────────────────────
// Stub endpoints for AI-verified photo, screenshot/document, Watch Mode, HealthKit, or offline proof submission,
// proof retention preference setting, and AI verification dispute filing.
// (Epic 7, Stories 7.2–7.8, FR31, FR33-34, FR35-36, FR37, FR38-40, FR47, FR66-67).
// FR31: camera capture only — no gallery import (photo path).
// FR33-34: Watch Mode passive camera monitoring (watchMode path).
// FR35, FR47: HealthKit auto-verification — reads Apple Health data to verify task completion.
// FR36: screenshot/document path — PNG, JPG, or PDF up to 25 MB.
// FR37: offline queued proof — clientTimestamp validated server-side; charge reversal if predates deadline.
// FR38: proof retention — user chooses whether proof is kept as a completion record (retain=true: B2 storage for task lifetime; retain=false: deletion within 24h).
// FR39-40: dispute filing — no-proof-required review request; stake charge placed on hold immediately.
// FR32: AI verification stub — always returns verified: true by default.
//       Add ?demo=fail to exercise the rejection path.
// FR66-67: Watch Mode session summary — durationSeconds + activityPercentage in body.
//
// TODO(impl): upload to Backblaze B2 (NFR-S4); call packages/ai proof-verification.ts;
//             enqueue job via proof-verification-consumer.ts

const app = new OpenAPIHono<{ Bindings: CloudflareBindings }>()

// ── Schema definitions ────────────────────────────────────────────────────────

const proofResponseDataSchema = z.object({
  verified: z.boolean(),
  reason: z.string().nullable(),
  taskId: z.string(),
})

const ProofResponseSchema = z.object({ data: proofResponseDataSchema })

const ErrorSchema = z.object({
  error: z.object({ code: z.string(), message: z.string() }),
})

// ── POST /v1/tasks/{taskId}/proof ─────────────────────────────────────────────
// Accepts multipart/form-data with a `media` file field.
// Returns AI verification result for the uploaded media.

const submitProofRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{taskId}/proof',
  tags: ['Proof'],
  summary: 'Submit photo, screenshot/document, Watch Mode session, HealthKit data, or offline queued proof for AI verification',
  description:
    'Accepts multipart/form-data with a `media` file field (photo/screenshot path), ' +
    'JSON body with durationSeconds/activityPercentage (watchMode path), ' +
    'JSON body with activityType/durationSeconds/startedAt/endedAt/calorie (healthKit path), or ' +
    'JSON body with clientTimestamp (offline path — FR37). ' +
    'FR31: photo path — camera capture only; FR36: screenshot/document path — PNG, JPG, PDF up to 25 MB; ' +
    'FR33-34/FR66-67: Watch Mode session path — passive camera monitoring, session summary submitted as JSON. ' +
    'FR35/FR47: HealthKit auto-verification — reads Apple Health data to verify task completion. ' +
    'FR37: offline path — clientTimestamp validated server-side; charge reversal triggered if predates task deadline. ' +
    'FR38: After verification, user is presented a retention choice — use PATCH /v1/tasks/{taskId}/proof-retention to set preference. ' +
    'Returns a stub verification result. ' +
    'Add ?demo=fail to exercise the rejection path. ' +
    'Use ?proofType=screenshot, ?proofType=watchMode, ?proofType=healthKit, or ?proofType=offline to indicate submission type. ' +
    'Stub implementation (Stories 7.2–7.7) — real AI pipeline deferred.',
  request: {
    params: z.object({
      taskId: z.string().min(1),
    }),
    query: z.object({
      demo: z.string().optional(),
      proofType: z.enum(['photo', 'screenshot', 'watchMode', 'healthKit', 'offline']).optional(),
    }),
  },
  responses: {
    200: {
      content: { 'application/json': { schema: ProofResponseSchema } },
      description: 'Verification result',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Bad request — missing taskId or media file',
    },
  },
})

app.openapi(submitProofRoute, async (c) => {
  const { taskId } = c.req.valid('param')
  const { demo } = c.req.valid('query')

  if (!taskId) {
    return c.json(err('BAD_REQUEST', 'taskId is required'), 400)
  }

  // TODO(impl): parse multipart/form-data and extract `media` file field (photo/screenshot paths)
  // TODO(impl): upload file to Backblaze B2 (NFR-S4) and store mediaUrl
  // TODO(impl): call packages/ai/src/proof-verification.ts with task context
  // TODO(impl): enqueue async job via proof-verification-consumer.ts
  // TODO(impl): store result in proof_submissions table
  // TODO(impl): Story 7.4 — store watch_mode_sessions table entry; validate activityPercentage; trigger AI frame scoring via packages/ai/src/watch-mode.ts
  // TODO(impl): Story 7.5 — read HealthKit verification data from request body; match against task activityType; store in proof_submissions; auto-verify if data within buffer window
  // TODO(impl): Story 7.6 — read clientTimestamp from request body; compare against task deadline; trigger charge reversal via stripe service if clientTimestamp < deadline

  // TODO(impl): When verified=true AND task has stakeAmountCents:
  //   1. const userId = c.get('jwtPayload').sub (same JWT pattern as other routes)
  //   2. const db = createDb(c.env.DATABASE_URL)
  //   3. Query tasks WHERE id = taskId to get title, stakeAmountCents
  //   4. If stakeAmountCents IS NOT NULL: cancel the stake
  //      - Update tasks.stakeAmountCents = null (or commitment_contracts.status = 'cancelled')
  //   5. Query device_tokens WHERE userId = userId
  //   6. Query notificationPreferencesTable WHERE userId = userId
  //   7. For each token: enforce preferences + call sendPush({
  //        payload: {
  //          title: task.title,
  //          body: buildVerificationApprovedBody(task.title, task.stakeAmountCents),
  //          data: { taskId, type: 'verification_approved' },
  //        }
  //      }, c.env)
  //
  // NOTE: When verified=false (rejection), Story 8.3 does NOT send a push here.
  //       The user already sees the rejection in-app. Notification on rejection
  //       is only triggered after dispute resolution (AC 4).

  // Demo failure path for testing rejection flow.
  if (demo === 'fail') {
    return c.json(
      ok({
        verified: false,
        reason: 'The photo does not clearly show the completed task. Please retake with the task visible.',
        taskId,
      }),
      200,
    )
  }

  // Default stub: approved.
  // offline path: clientTimestamp validated server-side; charge reversal triggered if predates task deadline
  return c.json(
    ok({
      verified: true,
      reason: null,
      taskId,
    }),
    200,
  )
})

// ── PATCH /v1/tasks/{taskId}/proof-retention ──────────────────────────────────
// Sets whether the submitted proof media is retained as a completion record.
// (Epic 7, Story 7.7, FR38, NFR-R8, NFR-S4)

const setProofRetentionRoute = createRoute({
  method: 'patch',
  path: '/v1/tasks/{taskId}/proof-retention',
  tags: ['Proof'],
  summary: 'Set proof retention preference for a submitted task',
  description:
    'Sets whether the submitted proof media is retained as a completion record on the task (FR38). ' +
    'retain=true: proof stored in B2 for task lifetime (NFR-R8, NFR-S4). ' +
    'retain=false: media scheduled for deletion within 24 hours of verification. ' +
    'Updates proof_retained column in tasks table. ' +
    'Stub implementation (Story 7.7) — real B2 deletion scheduling deferred.',
  request: {
    params: z.object({ taskId: z.string().min(1) }),
    body: {
      content: {
        'application/json': {
          schema: z.object({ retain: z.boolean() }),
        },
      },
    },
  },
  responses: {
    204: { description: 'Retention preference updated' },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Bad request',
    },
  },
})

app.openapi(setProofRetentionRoute, async (c) => {
  // TODO(impl): update tasks.proof_retained column in DB for taskId
  // TODO(impl): if retain=false, enqueue B2 media deletion job (delete within 24h of verification)
  // TODO(impl): if retain=true, ensure B2 media is preserved; update proof_submissions.mediaUrl
  return c.body(null, 204)
})

// ── POST /v1/tasks/{taskId}/disputes ─────────────────────────────────────────
// Files a no-proof-required dispute for a failed AI verification (FR39, FR40).

const DisputeResponseSchema = z.object({
  data: z.object({
    disputeId: z.string(),
    taskId: z.string(),
    status: z.literal('pending'),
  }),
})

const postDisputeRoute = createRoute({
  method: 'post',
  path: '/v1/tasks/{taskId}/disputes',
  tags: ['Proof'],
  summary: 'File a dispute against a failed AI verification result',
  description:
    'Files a no-proof-required dispute for a failed AI verification on the given task (FR39). ' +
    'Immediately places the stake charge on hold — no charge is processed while under review. ' +
    'Dispute is queued for human operator review with a 24-hour SLA (NFR-R3, FR40). ' +
    'Stub implementation (Story 7.8) — real DB write and charge-hold deferred.',
  request: {
    params: z.object({ taskId: z.string().min(1) }),
  },
  responses: {
    201: {
      content: { 'application/json': { schema: DisputeResponseSchema } },
      description: 'Dispute filed — stake charge placed on hold',
    },
    400: {
      content: { 'application/json': { schema: ErrorSchema } },
      description: 'Bad request',
    },
  },
})

app.openapi(postDisputeRoute, async (c) => {
  const { taskId } = c.req.valid('param')
  // TODO(impl): insert row into verification_disputes table
  //   (taskId, userId from JWT, proofSubmissionId, status='pending', filedAt=now())
  // TODO(impl): place stake charge on hold — set tasks.charge_status = 'on_hold' or update
  //   commitment_contracts.status = 'disputed' for this taskId
  // TODO(impl): notify operator queue (Story 11.2) of new dispute
  // TODO(impl): After inserting the dispute row and placing stake on hold:
  //   1. const userId = c.get('jwtPayload').sub
  //   2. Query device_tokens WHERE userId = userId
  //   3. Query notificationPreferencesTable WHERE userId = userId
  //   4. Enforce preferences + for each token: call sendPush({
  //        payload: {
  //          title: taskTitle,
  //          body: buildDisputeFiledBody(taskTitle),
  //          data: { taskId, type: 'dispute_filed' },
  //        }
  //      }, c.env)
  return c.json(
    ok({
      disputeId: '00000000-0000-4000-a000-000000000078',
      taskId,
      status: 'pending' as const,
    }),
    201,
  )
})

export { app as proofRouter }
