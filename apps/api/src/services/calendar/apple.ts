import type { CalendarEvent } from '@ontask/core'

// ── Apple Calendar service stub ───────────────────────────────────────────────
// v2 — EventKit native, no server tokens
// Apple Calendar access uses EventKit on-device (no server-side OAuth tokens).
// The Flutter layer handles EventKit directly; no server-side implementation needed.

export async function fetchAppleCalendarEvents(
  _connectionId: string,
  _userId: string,
  _windowStart: Date,
  _windowEnd: Date,
  _env: CloudflareBindings,
): Promise<CalendarEvent[]> {
  return Promise.resolve([])
}
