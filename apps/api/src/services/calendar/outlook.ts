import type { CalendarEvent } from '@ontask/core'

// ── Outlook Calendar service stub ─────────────────────────────────────────────
// v2
// Microsoft Graph OAuth implementation for Outlook calendar will be added in a future story.

export async function fetchOutlookCalendarEvents(
  _connectionId: string,
  _userId: string,
  _windowStart: Date,
  _windowEnd: Date,
  _env: CloudflareBindings,
): Promise<CalendarEvent[]> {
  return Promise.resolve([])
}
