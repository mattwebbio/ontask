import type { DataResponse, ListResponse, ErrorResponse } from '@ontask/core'

/**
 * Standard response envelope helpers.
 *
 * All API responses must use one of these helpers to ensure consistent envelope shapes.
 *
 * Shapes:
 *   ok()   → { "data": { ...fields } }
 *   list() → { "data": [...], "pagination": { "cursor": "...", "hasMore": true } }
 *   err()  → { "error": { "code": "SCREAMING_SNAKE_CASE", "message": "...", "details": {} } }
 */

/** Wraps a single object in the standard success envelope. */
export function ok<T>(data: T): DataResponse<T> {
  return { data }
}

/**
 * Wraps a list of items in the standard paginated success envelope.
 * Pagination is cursor-based only — never offset/limit.
 */
export function list<T>(data: T[], cursor: string | null, hasMore: boolean): ListResponse<T> {
  return {
    data,
    pagination: { cursor, hasMore },
  }
}

/**
 * Produces the standard error envelope.
 * @param code - SCREAMING_SNAKE_CASE error code string (never numeric)
 * @param message - Human-readable error message
 * @param details - Optional additional error context
 */
export function err(
  code: string,
  message: string,
  details: Record<string, unknown> = {}
): ErrorResponse {
  return {
    error: { code, message, details },
  }
}
