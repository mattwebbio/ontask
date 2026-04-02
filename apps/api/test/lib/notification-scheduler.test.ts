import { describe, it, expect } from 'vitest'
import {
  REMINDER_LEAD_MINUTES,
  STAKE_WARNING_HOURS,
  formatTime,
  formatDollars,
  hoursUntil,
  buildReminderBody,
  buildDeadlineBody,
  buildStakeWarningBody,
  shouldSendNotification,
  buildChargeNotificationBody,
  buildVerificationApprovedBody,
  buildDisputeFiledBody,
  buildDisputeResolvedBody,
} from '../../src/lib/notification-scheduler.js'

// ── Notification scheduler unit tests ─────────────────────────────────────────
// Tests for pure utility functions exported from notification-scheduler.ts.
// DB-dependent functions (triggerReminderNotifications, etc.) are not tested
// here — they follow the same stub pattern as triggerOverdueCharges() and are
// covered by integration tests in a future story.
// (FR42, FR72, Story 8.2, AC: 1–4)

describe('constants', () => {
  it('REMINDER_LEAD_MINUTES is 15', () => {
    expect(REMINDER_LEAD_MINUTES).toBe(15)
  })

  it('STAKE_WARNING_HOURS is 2', () => {
    expect(STAKE_WARNING_HOURS).toBe(2)
  })
})

describe('formatTime', () => {
  it('formats midnight as 12:00 AM', () => {
    const date = new Date('2026-04-01T00:00:00Z')
    expect(formatTime(date)).toBe('12:00 AM')
  })

  it('formats noon as 12:00 PM', () => {
    const date = new Date('2026-04-01T12:00:00Z')
    expect(formatTime(date)).toBe('12:00 PM')
  })

  it('formats 9:00 AM correctly', () => {
    const date = new Date('2026-04-01T09:00:00Z')
    expect(formatTime(date)).toBe('9:00 AM')
  })

  it('formats 5:30 PM correctly', () => {
    const date = new Date('2026-04-01T17:30:00Z')
    expect(formatTime(date)).toBe('5:30 PM')
  })

  it('pads minutes with leading zero', () => {
    const date = new Date('2026-04-01T09:05:00Z')
    expect(formatTime(date)).toBe('9:05 AM')
  })
})

describe('formatDollars', () => {
  it('formats whole dollar amounts without cents', () => {
    expect(formatDollars(1000)).toBe('$10')
  })

  it('formats amounts with cents', () => {
    expect(formatDollars(1050)).toBe('$10.50')
  })

  it('formats $5 stake', () => {
    expect(formatDollars(500)).toBe('$5')
  })

  it('formats minimum 99 cents', () => {
    expect(formatDollars(99)).toBe('$0.99')
  })

  it('formats large amounts', () => {
    expect(formatDollars(10000)).toBe('$100')
  })
})

describe('buildReminderBody', () => {
  it('includes task title in reminder copy', () => {
    const date = new Date('2026-04-01T09:00:00Z')
    const body = buildReminderBody('Buy groceries', date)
    expect(body).toContain('Buy groceries')
  })

  it('includes formatted time in reminder copy', () => {
    const date = new Date('2026-04-01T14:30:00Z')
    const body = buildReminderBody('Team standup', date)
    expect(body).toContain('2:30 PM')
  })

  it('matches expected copy format — "X is coming up at Y"', () => {
    const date = new Date('2026-04-01T09:00:00Z')
    const body = buildReminderBody('Morning workout', date)
    expect(body).toBe('Morning workout is coming up at 9:00 AM')
  })
})

describe('buildDeadlineBody', () => {
  it('builds deadline_today copy correctly', () => {
    const body = buildDeadlineBody('Submit report', 'deadline_today')
    expect(body).toBe('Submit report is due today')
  })

  it('builds deadline_tomorrow copy correctly', () => {
    const body = buildDeadlineBody('Pay rent', 'deadline_tomorrow')
    expect(body).toBe('Pay rent is due tomorrow')
  })

  it('deadline_today copy includes task title', () => {
    const body = buildDeadlineBody('Doctor appointment', 'deadline_today')
    expect(body).toContain('Doctor appointment')
  })

  it('deadline_tomorrow copy includes task title', () => {
    const body = buildDeadlineBody('Tax filing', 'deadline_tomorrow')
    expect(body).toContain('Tax filing')
  })
})

describe('buildStakeWarningBody — warm tone, UX-DR32', () => {
  it('includes staked amount in copy', () => {
    const body = buildStakeWarningBody(1000, 1, 'American Red Cross')
    expect(body).toContain('$10')
  })

  it('includes charity name in copy', () => {
    const body = buildStakeWarningBody(1000, 1, 'American Red Cross')
    expect(body).toContain('American Red Cross')
  })

  it('includes hours remaining in copy', () => {
    const body = buildStakeWarningBody(1000, 2, 'Doctors Without Borders')
    expect(body).toContain('2h')
  })

  it('builds correct full stake warning copy', () => {
    const body = buildStakeWarningBody(2000, 1, 'UNICEF')
    expect(body).toBe('$20 staked, deadline in 1h. UNICEF gets half if it\'s not done.')
  })

  it('includes warm tone phrase — "gets half if it\'s not done"', () => {
    // UX-DR32: warm tone, not punitive — never "you owe" or "you failed"
    const body = buildStakeWarningBody(500, 1, 'Any Charity')
    expect(body).toContain("gets half if it's not done")
    expect(body).not.toContain('you owe')
    expect(body).not.toContain('you failed')
    expect(body).not.toContain('charged')
  })
})

describe('shouldSendNotification — preference enforcement (AC: 4)', () => {
  it('returns true when no preferences are set (default ON)', () => {
    const result = shouldSendNotification([], 'task-1', 'device-token-1')
    expect(result).toBe(true)
  })

  it('returns false when global preference is disabled', () => {
    const prefs = [
      { scope: 'global', deviceId: null, taskId: null, enabled: false },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(false)
  })

  it('returns true when global preference is enabled', () => {
    const prefs = [
      { scope: 'global', deviceId: null, taskId: null, enabled: true },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(true)
  })

  it('returns false when task-scoped preference is disabled for this task', () => {
    const prefs = [
      { scope: 'task', deviceId: null, taskId: 'task-1', enabled: false },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(false)
  })

  it('returns true when task-scoped preference is disabled for a DIFFERENT task', () => {
    const prefs = [
      { scope: 'task', deviceId: null, taskId: 'task-2', enabled: false },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(true)
  })

  it('returns false when device-scoped preference is disabled for this device token', () => {
    const prefs = [
      { scope: 'device', deviceId: 'device-token-1', taskId: null, enabled: false },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(false)
  })

  it('returns true when device-scoped preference is disabled for a DIFFERENT device', () => {
    const prefs = [
      { scope: 'device', deviceId: 'device-token-2', taskId: null, enabled: false },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(true)
  })

  it('global off takes precedence over task/device preferences', () => {
    // Even if task and device prefs say "enabled", global off wins
    const prefs = [
      { scope: 'global', deviceId: null, taskId: null, enabled: false },
      { scope: 'task', deviceId: null, taskId: 'task-1', enabled: true },
      { scope: 'device', deviceId: 'device-token-1', taskId: null, enabled: true },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(false)
  })

  it('task off suppresses even if device pref is enabled', () => {
    const prefs = [
      { scope: 'task', deviceId: null, taskId: 'task-1', enabled: false },
      { scope: 'device', deviceId: 'device-token-1', taskId: null, enabled: true },
    ]
    const result = shouldSendNotification(prefs, 'task-1', 'device-token-1')
    expect(result).toBe(false)
  })
})

describe('hoursUntil', () => {
  it('returns 0 for a past date', () => {
    const past = new Date(Date.now() - 1000 * 60 * 60)
    expect(hoursUntil(past)).toBe(0)
  })

  it('returns approximately correct hours for a future date', () => {
    const future = new Date(Date.now() + 1000 * 60 * 60 * 2)
    // Allow 1 hour tolerance due to execution time
    const hours = hoursUntil(future)
    expect(hours).toBeGreaterThanOrEqual(1)
    expect(hours).toBeLessThanOrEqual(2)
  })
})

// ── Story 8.3: Commitment, Charge & Verification Notification helpers ──────────
// (FR42, UX-DR36, AC: 1–4)

describe('buildChargeNotificationBody — affirming tone, UX-DR36 (AC: 1)', () => {
  it('includes task title, charge amount, charity name, and charity amount', () => {
    const body = buildChargeNotificationBody('Complete report', 2000, 'Red Cross', 1000)
    expect(body).toContain('Complete report')
    expect(body).toContain('$20')
    expect(body).toContain('Red Cross')
    expect(body).toContain('$10')
  })

  it('includes "Thanks for trying" affirming phrase and does NOT contain punitive language', () => {
    // UX-DR36: affirming, never punitive
    const body = buildChargeNotificationBody('Morning run', 1000, 'UNICEF', 500)
    expect(body).toContain('Thanks for trying')
    expect(body).not.toContain('failed')
    expect(body).not.toContain('owe')
    expect(body).not.toContain('penalty')
    expect(body).not.toContain('violation')
  })
})

describe('buildVerificationApprovedBody — stake safe (AC: 2)', () => {
  it('includes task title, stake amount, and "stake is safe"', () => {
    const body = buildVerificationApprovedBody('Finish project', 5000)
    expect(body).toContain('Finish project')
    expect(body).toContain('$50')
    expect(body).toContain('stake is safe')
  })

  it('does NOT contain punitive language', () => {
    // UX-DR36: affirming, never punitive
    const body = buildVerificationApprovedBody('Exercise 30 min', 2000)
    expect(body).not.toContain('failed')
    expect(body).not.toContain('owe')
    expect(body).not.toContain('penalty')
    expect(body).not.toContain('violation')
    expect(body).not.toContain('charged')
  })
})

describe('buildDisputeFiledBody — stake on hold (AC: 3)', () => {
  it('includes task title, "dispute filed", and "on hold"', () => {
    const body = buildDisputeFiledBody('Write chapter 3')
    expect(body).toContain('Write chapter 3')
    expect(body).toContain('dispute filed')
    expect(body).toContain('on hold')
  })

  it('does NOT contain punitive language (UX-DR36)', () => {
    const body = buildDisputeFiledBody('Write chapter 3')
    expect(body).not.toContain('failed')
    expect(body).not.toContain('owe')
    expect(body).not.toContain('penalty')
    expect(body).not.toContain('violation')
  })
})

describe('buildDisputeResolvedBody — both outcomes, affirming tone, UX-DR36 (AC: 4)', () => {
  it('approved=true — includes task title, "cancelled", and stake amount', () => {
    const body = buildDisputeResolvedBody('Submit report', true, 3000, 'Doctors Without Borders', 1500)
    expect(body).toContain('Submit report')
    expect(body).toContain('$30')
    expect(body).toContain('cancelled')
  })

  it('approved=false — includes task title, charge amount, charity name, and "Thanks for trying"', () => {
    const body = buildDisputeResolvedBody('Morning workout', false, 2000, 'UNICEF', 1000)
    expect(body).toContain('Morning workout')
    expect(body).toContain('$20')
    expect(body).toContain('UNICEF')
    expect(body).toContain('Thanks for trying')
  })

  it('approved=false — does NOT contain punitive language (UX-DR36)', () => {
    const body = buildDisputeResolvedBody('Read 10 pages', false, 1000, 'Red Cross', 500)
    expect(body).not.toContain('failed')
    expect(body).not.toContain('owe')
    expect(body).not.toContain('penalty')
    expect(body).not.toContain('rejected')
    expect(body).not.toContain('violation')
  })

  it('approved=true — does NOT contain punitive language (UX-DR36)', () => {
    const body = buildDisputeResolvedBody('Submit report', true, 3000, 'Doctors Without Borders', 1500)
    expect(body).not.toContain('failed')
    expect(body).not.toContain('owe')
    expect(body).not.toContain('penalty')
    expect(body).not.toContain('violation')
  })
})
