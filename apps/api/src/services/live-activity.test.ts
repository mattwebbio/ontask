import { describe, expect, it, vi, beforeEach } from 'vitest'
import { ApnsError } from '@fivesheepco/cloudflare-apns2'

// Unit tests for live-activity.ts service (Story 12.4, AC: 1, 3)
//
// Mocks @fivesheepco/cloudflare-apns2 to verify:
//   - APNs payload shape (content-state, event, timestamp)
//   - Correct apns-push-type (liveactivity) and apns-topic headers via Notification options
//   - tokenExpired: true returned on APNs HTTP 410 (Unregistered)
//   - elapsedSeconds is NOT included in the push payload
//   - dismissal-date is included when dismissalDate is provided

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyJson = any

// Capture the last notification sent so we can inspect its options
let lastNotificationOptions: AnyJson = null
const mockSend = vi.fn()

vi.mock('@fivesheepco/cloudflare-apns2', async (importOriginal) => {
  const actual = await importOriginal() as AnyJson
  return {
    ...actual,
    ApnsClient: vi.fn().mockImplementation(() => ({
      send: mockSend,
    })),
    Notification: vi.fn().mockImplementation((deviceToken: string, options: AnyJson) => {
      lastNotificationOptions = options
      return { deviceToken, options }
    }),
  }
})

const { sendLiveActivityUpdate } = await import('./live-activity.js')

const stubEnv = {
  APNS_TEAM_ID: 'TEAM123456',
  APNS_KEY_ID: 'KEY1234567',
  APNS_KEY: '-----BEGIN EC PRIVATE KEY-----\nstub\n-----END EC PRIVATE KEY-----',
  ENVIRONMENT: 'staging',
} as unknown as CloudflareBindings

const stubOptions = {
  pushToken: 'live-activity-push-token-abc123',
  expiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000),
  event: 'update' as const,
  contentState: {
    taskTitle: 'Pay rent',
    deadlineTimestamp: Math.floor(Date.now() / 1000) + 3600,
    stakeAmount: 50,
    activityStatus: 'active' as const,
  },
}

describe('sendLiveActivityUpdate', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    lastNotificationOptions = null
    mockSend.mockResolvedValue({})
  })

  it('returns { success: true, tokenExpired: false } on APNs success', async () => {
    const result = await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(result).toEqual({ success: true, tokenExpired: false })
    expect(mockSend).toHaveBeenCalledOnce()
  })

  it('returns { success: false, tokenExpired: true } on APNs HTTP 410', async () => {
    // Simulate APNs 410 Unregistered error
    const apnsError = new ApnsError({
      statusCode: 410,
      notification: {} as AnyJson,
      response: { reason: 'Unregistered', timestamp: Date.now() },
    })
    mockSend.mockRejectedValue(apnsError)

    const result = await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(result).toEqual({ success: false, tokenExpired: true })
  })

  it('returns { success: false, tokenExpired: false } on other APNs errors', async () => {
    mockSend.mockRejectedValue(
      new ApnsError({
        statusCode: 500,
        notification: {} as AnyJson,
        response: { reason: 'InternalServerError', timestamp: Date.now() },
      })
    )

    const result = await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(result).toEqual({ success: false, tokenExpired: false })
  })

  it('sets apns-push-type to liveactivity via PushType.liveactivity', async () => {
    const { PushType } = await import('@fivesheepco/cloudflare-apns2')
    await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(lastNotificationOptions.type).toBe(PushType.liveactivity)
  })

  it('sets apns-topic to com.ontaskhq.ontask.push-type.liveactivity', async () => {
    await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(lastNotificationOptions.topic).toBe('com.ontaskhq.ontask.push-type.liveactivity')
  })

  it('includes correct event in aps payload', async () => {
    await sendLiveActivityUpdate(stubOptions, stubEnv)
    expect(lastNotificationOptions.aps.event).toBe('update')

    mockSend.mockResolvedValue({})
    await sendLiveActivityUpdate({ ...stubOptions, event: 'end' }, stubEnv)
    expect(lastNotificationOptions.aps.event).toBe('end')
  })

  it('includes content-state with taskTitle, deadlineTimestamp, stakeAmount, activityStatus', async () => {
    await sendLiveActivityUpdate(stubOptions, stubEnv)
    const cs = lastNotificationOptions.aps['content-state'] as AnyJson
    expect(cs.taskTitle).toBe('Pay rent')
    expect(cs.deadlineTimestamp).toBe(stubOptions.contentState.deadlineTimestamp)
    expect(cs.stakeAmount).toBe(50)
    expect(cs.activityStatus).toBe('active')
  })

  it('does NOT include elapsedSeconds in the push payload', async () => {
    const optionsWithElapsed = {
      ...stubOptions,
      contentState: {
        ...stubOptions.contentState,
        elapsedSeconds: 1842,  // should be ignored in server push
      },
    }
    await sendLiveActivityUpdate(optionsWithElapsed, stubEnv)
    const cs = lastNotificationOptions.aps['content-state'] as AnyJson
    // elapsedSeconds must NEVER appear in server pushes (client-driven timer)
    expect('elapsedSeconds' in cs).toBe(false)
  })

  it('includes dismissal-date in aps when dismissalDate is provided', async () => {
    const dismissalDate = Math.floor(Date.now() / 1000) + 3600
    await sendLiveActivityUpdate({ ...stubOptions, dismissalDate }, stubEnv)
    expect(lastNotificationOptions.aps['dismissal-date']).toBe(dismissalDate)
  })

  it('omits dismissal-date from aps when dismissalDate is not provided', async () => {
    await sendLiveActivityUpdate(stubOptions, stubEnv)  // no dismissalDate
    expect('dismissal-date' in lastNotificationOptions.aps).toBe(false)
  })

  it('sets expiration to Unix seconds from expiresAt', async () => {
    const expiresAt = new Date(Date.now() + 8 * 60 * 60 * 1000)
    await sendLiveActivityUpdate({ ...stubOptions, expiresAt }, stubEnv)
    const expectedExpiration = Math.floor(expiresAt.getTime() / 1000)
    expect(lastNotificationOptions.expiration).toBe(expectedExpiration)
  })

  it('omits optional contentState fields (deadlineTimestamp, stakeAmount) when undefined', async () => {
    const minimalOptions = {
      ...stubOptions,
      contentState: {
        taskTitle: 'Pay rent',
        activityStatus: 'completed' as const,
      },
    }
    await sendLiveActivityUpdate(minimalOptions, stubEnv)
    const cs = lastNotificationOptions.aps['content-state'] as AnyJson
    expect(cs.taskTitle).toBe('Pay rent')
    expect(cs.activityStatus).toBe('completed')
    expect('deadlineTimestamp' in cs).toBe(false)
    expect('stakeAmount' in cs).toBe(false)
  })
})
