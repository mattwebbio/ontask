/**
 * Standard API response envelope types.
 *
 * All API responses from the OnTask API must conform to one of these three shapes.
 * - DataResponse<T>: successful single-object response
 * - ListResponse<T>: successful list response with cursor-based pagination
 * - ErrorResponse: error response with SCREAMING_SNAKE_CASE code
 */

/** Successful single-object response: { "data": { ...fields } } */
export interface DataResponse<T> {
  data: T
}

/** Successful list response with cursor-based pagination.
 *  Pagination is cursor-based only — NO offset/limit, anywhere, ever.
 */
export interface ListResponse<T> {
  data: T[]
  pagination: {
    cursor: string | null
    hasMore: boolean
  }
}

/** Error response: { "error": { "code": "SCREAMING_SNAKE_CASE", "message": "...", "details": {} } } */
export interface ErrorResponse {
  error: {
    /** SCREAMING_SNAKE_CASE error code — never numeric */
    code: string
    /** Human-readable error message */
    message: string
    /** Optional additional error details */
    details: Record<string, unknown>
  }
}
