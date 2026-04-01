import { describe, test, expect, vi, beforeEach } from 'vitest'
import { isWithinClockSkewLimit, splitStakeAmount, chargeTriggerConsumer } from './charge-trigger-consumer.js'

// ── Clock skew boundary tests (ARCH-29, AC: 4) ────────────────────────────────
// MANDATORY per ARCH-29 — three boundary tests enforced.
// Use vi.useFakeTimers so the "exactly 30 days" boundary test is deterministic:
// creates the timestamp and calls isWithinClockSkewLimit at the same instant.

const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000

describe('isWithinClockSkewLimit', () => {
  test('accepts timestamp exactly 30 days old', () => {
    // Use fake timer to freeze Date.now() — ensures the age is exactly THIRTY_DAYS_MS
    // when isWithinClockSkewLimit is called (no elapsed ms between timestamp creation and check).
    vi.useFakeTimers()
    const frozenNow = Date.now()
    const ts = new Date(frozenNow - THIRTY_DAYS_MS).toISOString()
    expect(isWithinClockSkewLimit(ts)).toBe(true)
    vi.useRealTimers()
  })

  test('rejects timestamp 30 days + 1 second old', () => {
    vi.useFakeTimers()
    const frozenNow = Date.now()
    const ts = new Date(frozenNow - THIRTY_DAYS_MS - 1000).toISOString()
    expect(isWithinClockSkewLimit(ts)).toBe(false)
    vi.useRealTimers()
  })

  test('accepts current timestamp', () => {
    const ts = new Date().toISOString()
    expect(isWithinClockSkewLimit(ts)).toBe(true)
  })

  test('accepts a timestamp from yesterday', () => {
    const ts = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    expect(isWithinClockSkewLimit(ts)).toBe(true)
  })

  test('rejects a timestamp from 31 days ago', () => {
    const ts = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000).toISOString()
    expect(isWithinClockSkewLimit(ts)).toBe(false)
  })
})

// ── 50/50 split tests ─────────────────────────────────────────────────────────

describe('splitStakeAmount', () => {
  test('$10.00 (1000 cents) splits evenly', () => {
    const result = splitStakeAmount(1000)
    expect(result.charityAmountCents).toBe(500)
    expect(result.platformAmountCents).toBe(500)
  })

  test('$10.01 (1001 cents) — platform absorbs odd cent', () => {
    const result = splitStakeAmount(1001)
    expect(result.charityAmountCents).toBe(500)
    expect(result.platformAmountCents).toBe(501)
  })

  test('$5.00 (500 cents) splits evenly', () => {
    const result = splitStakeAmount(500)
    expect(result.charityAmountCents).toBe(250)
    expect(result.platformAmountCents).toBe(250)
  })

  test('odd amount: 999 cents — charity gets 499, platform gets 500', () => {
    const result = splitStakeAmount(999)
    expect(result.charityAmountCents).toBe(499)
    expect(result.platformAmountCents).toBe(500)
  })

  test('charity + platform always equals total stake', () => {
    const amounts = [500, 999, 1000, 1001, 2501, 10000]
    for (const amount of amounts) {
      const { charityAmountCents, platformAmountCents } = splitStakeAmount(amount)
      expect(charityAmountCents + platformAmountCents).toBe(amount)
    }
  })
})

// ── Consumer idempotency tests ─────────────────────────────────────────────────

// Mock the DB module and services
vi.mock('../db/index.js', () => ({
  createDb: vi.fn(),
}))

vi.mock('../services/stripe.js', () => ({
  createOffSessionCharge: vi.fn(),
}))

vi.mock('../services/analytics.js', () => ({
  trackBusinessEvent: vi.fn(),
}))

vi.mock('@ontask/core', () => ({
  chargeEventsTable: {
    idempotencyKey: 'idempotency_key',
    id: 'id',
    status: 'status',
  },
}))

vi.mock('drizzle-orm', () => ({
  eq: vi.fn((col, val) => ({ col, val })),
}))

import { createDb } from '../db/index.js'
import { createOffSessionCharge } from '../services/stripe.js'

describe('chargeTriggerConsumer — idempotency', () => {
  const mockDb = {
    select: vi.fn(),
    insert: vi.fn(),
    update: vi.fn(),
  }

  const mockEnv = {
    DATABASE_URL: 'postgresql://test',
    EVERY_ORG_QUEUE: {
      send: vi.fn().mockResolvedValue(undefined),
    },
  } as unknown as CloudflareBindings

  const makeMessage = (overrides: Record<string, unknown> = {}) => ({
    body: {
      type: 'CHARGE_TRIGGER',
      idempotencyKey: 'charge-task-1-user-1',
      payload: {
        taskId: 'task-1',
        userId: 'user-1',
        stakeAmountCents: 1000,
        stripeCustomerId: 'cus_test',
        stripePaymentMethodId: 'pm_test',
        charityId: 'american-red-cross',
        charityName: 'American Red Cross',
        deadlineTimestamp: new Date(Date.now() - 1000).toISOString(), // 1 second ago (valid)
        ...overrides,
      },
      createdAt: new Date().toISOString(),
      retryCount: 0,
    },
    ack: vi.fn(),
    retry: vi.fn(),
  })

  const makeBatch = (messages: ReturnType<typeof makeMessage>[]) => ({
    queue: 'charge-trigger-queue',
    messages,
  }) as unknown as MessageBatch<unknown>

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(createDb).mockReturnValue(mockDb as unknown as ReturnType<typeof createDb>)
  })

  test('duplicate message with status="charged" is acked without re-charging', async () => {
    // Simulate existing 'charged' row
    mockDb.select.mockReturnValue({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue([{ status: 'charged', id: 'ce-1' }]),
        }),
      }),
    })

    const message = makeMessage()
    await chargeTriggerConsumer(makeBatch([message]), mockEnv, {} as ExecutionContext)

    expect(message.ack).toHaveBeenCalledTimes(1)
    expect(createOffSessionCharge).not.toHaveBeenCalled()
  })

  test('duplicate message with status="disbursed" is acked without re-charging', async () => {
    // Simulate existing 'disbursed' row
    mockDb.select.mockReturnValue({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue([{ status: 'disbursed', id: 'ce-2' }]),
        }),
      }),
    })

    const message = makeMessage()
    await chargeTriggerConsumer(makeBatch([message]), mockEnv, {} as ExecutionContext)

    expect(message.ack).toHaveBeenCalledTimes(1)
    expect(createOffSessionCharge).not.toHaveBeenCalled()
  })

  test('new message with no existing charge_events row proceeds to charge', async () => {
    // No existing row
    mockDb.select.mockReturnValueOnce({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue([]),
        }),
      }),
    })
    // Second select for chargeEventId after charge success
    .mockReturnValueOnce({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockReturnValue({
          limit: vi.fn().mockResolvedValue([{ id: 'ce-new' }]),
        }),
      }),
    })

    mockDb.insert.mockReturnValue({
      values: vi.fn().mockReturnValue({
        onConflictDoUpdate: vi.fn().mockResolvedValue(undefined),
      }),
    })

    mockDb.update.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      }),
    })

    vi.mocked(createOffSessionCharge).mockResolvedValue({ paymentIntentId: 'pi_test_123' })

    const message = makeMessage()
    await chargeTriggerConsumer(makeBatch([message]), mockEnv, {} as ExecutionContext)

    expect(createOffSessionCharge).toHaveBeenCalledTimes(1)
    expect(message.ack).toHaveBeenCalledTimes(1)
  })

  test('clock skew reject: message with deadline > 30 days ago is acked without charging', async () => {
    const oldDeadline = new Date(Date.now() - 31 * 24 * 60 * 60 * 1000).toISOString()
    const message = makeMessage({ deadlineTimestamp: oldDeadline } as Record<string, unknown>)

    // Override the payload in the body
    ;(message.body as { payload: { deadlineTimestamp: string } }).payload.deadlineTimestamp = oldDeadline

    await chargeTriggerConsumer(makeBatch([message]), mockEnv, {} as ExecutionContext)

    expect(message.ack).toHaveBeenCalledTimes(1)
    expect(createOffSessionCharge).not.toHaveBeenCalled()
    expect(mockDb.select).not.toHaveBeenCalled()
  })
})
