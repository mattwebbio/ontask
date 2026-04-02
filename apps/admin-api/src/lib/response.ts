/**
 * Standard response envelope helpers for admin-api.
 *
 * Copied from apps/api/src/lib/response.ts — do NOT import cross-app.
 *
 * Shapes:
 *   ok()  → { "data": { ...fields } }
 *   err() → { "error": { "code": "SCREAMING_SNAKE_CASE", "message": "..." } }
 */

/** Wraps a single object in the standard success envelope. */
export function ok<T>(data: T): { data: T } {
  return { data }
}

/**
 * Produces the standard error envelope.
 * @param code - SCREAMING_SNAKE_CASE error code string (never numeric)
 * @param message - Human-readable error message
 */
export function err(
  code: string,
  message: string
): { error: { code: string; message: string } } {
  return {
    error: {
      code,
      message,
    },
  }
}
