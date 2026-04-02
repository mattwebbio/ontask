import { describe, expect, it, vi, beforeEach } from 'vitest'

// Route-level tests for POST /internal/live-activities/update (Story 12.4, AC: 1, 3)
//
// Tests the internal route handler in apps/api/src/routes/internal.ts.
// Uses vi.mock to simulate the DB and the live-activity service.
// Does NOT modify test/routes/live-activities.test.ts (that file tests the token
// registration route from Story 12.1 — unrelated to this story).

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// Mock the DB module
vi.mock('../../src/db/index.js', () => ({
  createDb: vi.fn(),
}))

// Mock the live-activity service
vi.mock('../../src/services/live-activity.js', () => ({
  sendLiveActivityUpdate: vi.fn(),
}))

// Mock scheduling (imported transitively by index.ts)
vi.mock('../../src/services/scheduling.js', () => ({
  runScheduleForUser: vi.fn().mockResolvedValue({}),
}))

const { createDb } = await import('../../src/db/index.js')
const { sendLiveActivityUpdate } = await import('../../src/services/live-activity.js')
const app = (await import('../../src/index.js')).default

const stubEnv: Partial<CloudflareBindings> = {
  DATABASE_URL: 'postgresql://placeholder',
  ENVIRONMENT: 'test',
}

const stubUserId = 'u0000000-0000-4000-8000-000000000001'
const stubTaskId = 't0000000-0000-4000-8000-000000000002'
const stubTokenId = 'k0000000-0000-4000-8000-000000000003'

const validBody = {
  userId: stubUserId,
  taskId: stubTaskId,
  activityType: 'task_timer',
  event: 'update',
  contentState: {
    taskTitle: 'Pay rent',
    deadlineTimestamp: Math.floor(Date.now() / 1000) + 3600,
    stakeAmount: 50,
    activityStatus: 'active',
  },
}

describe('POST /internal/live-activities/update', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('returns 200 { sent: false, reason: no_token } when no token row exists in DB', async () => {
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),  // empty — no token found
          }),
        }),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(validBody),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.sent).toBe(false)
    expect(body.data.reason).toBe('no_token')
    expect(sendLiveActivityUpdate).not.toHaveBeenCalled()
  })

  it('returns 400 when required field userId is missing', async () => {
    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          taskId: stubTaskId,
          activityType: 'task_timer',
          event: 'update',
          contentState: { taskTitle: 'Pay rent', activityStatus: 'active' },
        }),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(400)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('BAD_REQUEST')
  })

  it('returns 400 when event field is invalid', async () => {
    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...validBody,
          event: 'invalid_event',
        }),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(400)
    const body = await res.json() as AnyJson
    expect(body.error.code).toBe('BAD_REQUEST')
  })

  it('returns 400 when contentState is missing', async () => {
    const { contentState: _cs, ...bodyWithoutContentState } = validBody
    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(bodyWithoutContentState),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(400)
  })

  it('returns 400 when body is invalid JSON', async () => {
    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: 'not-json',
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(400)
  })

  it('returns 200 { sent: true } when token exists and APNs succeeds', async () => {
    const futureExpiry = new Date(Date.now() + 8 * 60 * 60 * 1000)
    const stubToken = {
      id: stubTokenId,
      userId: stubUserId,
      taskId: stubTaskId,
      activityType: 'task_timer',
      pushToken: 'activitykit-token-abc123',
      expiresAt: futureExpiry,
    }

    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([stubToken]),
          }),
        }),
      }),
      delete: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue([]),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)
    vi.mocked(sendLiveActivityUpdate).mockResolvedValue({ success: true, tokenExpired: false })

    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(validBody),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.sent).toBe(true)
    expect(sendLiveActivityUpdate).toHaveBeenCalledOnce()
  })

  it('deletes token and returns { sent: false, reason: token_expired } on APNs 410', async () => {
    const futureExpiry = new Date(Date.now() + 8 * 60 * 60 * 1000)
    const stubToken = {
      id: stubTokenId,
      userId: stubUserId,
      taskId: stubTaskId,
      activityType: 'task_timer',
      pushToken: 'activitykit-token-stale',
      expiresAt: futureExpiry,
    }

    const mockDeleteWhere = vi.fn().mockResolvedValue([])
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([stubToken]),
          }),
        }),
      }),
      delete: vi.fn().mockReturnValue({
        where: mockDeleteWhere,
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)
    vi.mocked(sendLiveActivityUpdate).mockResolvedValue({ success: false, tokenExpired: true })

    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(validBody),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.sent).toBe(false)
    expect(body.data.reason).toBe('token_expired')
    // DB delete must have been called to remove stale token
    expect(mockDb.delete).toHaveBeenCalled()
    expect(mockDeleteWhere).toHaveBeenCalled()
  })

  it('returns 200 { sent: false, reason: token_expired } and deletes row when expiresAt is in the past', async () => {
    const pastExpiry = new Date(Date.now() - 1000)  // already expired
    const stubToken = {
      id: stubTokenId,
      userId: stubUserId,
      taskId: stubTaskId,
      activityType: 'task_timer',
      pushToken: 'activitykit-token-past',
      expiresAt: pastExpiry,
    }

    const mockDeleteWhere = vi.fn().mockResolvedValue([])
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([stubToken]),
          }),
        }),
      }),
      delete: vi.fn().mockReturnValue({
        where: mockDeleteWhere,
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(validBody),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.sent).toBe(false)
    expect(body.data.reason).toBe('token_expired')
    // APNs should NOT have been called for an already-expired token
    expect(sendLiveActivityUpdate).not.toHaveBeenCalled()
    // Token row should be deleted
    expect(mockDb.delete).toHaveBeenCalled()
  })

  it('handles taskId = null (watch_mode) without error', async () => {
    const mockDb = {
      select: vi.fn().mockReturnValue({
        from: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            limit: vi.fn().mockResolvedValue([]),  // no token — simplest path
          }),
        }),
      }),
    }
    vi.mocked(createDb).mockReturnValue(mockDb as AnyJson)

    const res = await app.request(
      '/internal/live-activities/update',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...validBody,
          taskId: null,
          activityType: 'watch_mode',
        }),
      },
      stubEnv as CloudflareBindings,
    )

    expect(res.status).toBe(200)
    const body = await res.json() as AnyJson
    expect(body.data.sent).toBe(false)
    expect(body.data.reason).toBe('no_token')
  })
})
