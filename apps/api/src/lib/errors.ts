/**
 * Typed application error classes.
 *
 * All application errors extend AppError, which carries:
 *   - code: SCREAMING_SNAKE_CASE string (used in error envelope)
 *   - httpStatus: HTTP status code to send in the response
 *
 * Usage:
 *   throw new NotFoundError('Task not found')
 *   throw new ValidationError('Invalid input', { field: 'email' })
 */

export class AppError extends Error {
  constructor(
    public readonly code: string,
    public readonly httpStatus: number,
    message: string,
    public readonly details?: Record<string, unknown>
  ) {
    super(message)
    this.name = this.constructor.name
  }
}

/** 404 — Resource not found */
export class NotFoundError extends AppError {
  constructor(message = 'Not found', details?: Record<string, unknown>) {
    super('NOT_FOUND', 404, message, details)
  }
}

/** 400 — Validation failure (Zod parse error, malformed input) */
export class ValidationError extends AppError {
  constructor(message = 'Validation failed', details?: Record<string, unknown>) {
    super('VALIDATION_ERROR', 400, message, details)
  }
}

/** 401 — Missing or invalid authentication token */
export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized', details?: Record<string, unknown>) {
    super('UNAUTHORIZED', 401, message, details)
  }
}

/** 403 — Authenticated but insufficient permissions */
export class ForbiddenError extends AppError {
  constructor(message = 'Forbidden', details?: Record<string, unknown>) {
    super('FORBIDDEN', 403, message, details)
  }
}

/** 409 — Conflict (duplicate resource, invalid state transition) */
export class ConflictError extends AppError {
  constructor(message = 'Conflict', details?: Record<string, unknown>) {
    super('CONFLICT', 409, message, details)
  }
}

/** 422 — Business logic error (e.g. deadline already passed, quota exceeded) */
export class BusinessLogicError extends AppError {
  constructor(message = 'Unprocessable entity', details?: Record<string, unknown>) {
    super('BUSINESS_LOGIC_ERROR', 422, message, details)
  }
}

/** 429 — Rate limit exceeded */
export class RateLimitError extends AppError {
  constructor(message = 'Rate limit exceeded', details?: Record<string, unknown>) {
    super('RATE_LIMIT_EXCEEDED', 429, message, details)
  }
}

/** 422 — Stake is locked; modification window has closed (FR63, Story 6.6) */
export class StakeLockedError extends AppError {
  constructor(message = 'Stake is locked — the deadline is too close to change it', details?: Record<string, unknown>) {
    super('STAKE_LOCKED', 422, message, details)
  }
}

/** 422 — No active stake exists on the task (FR63, Story 6.6) */
export class NoActiveStakeError extends AppError {
  constructor(message = 'No active stake on this task', details?: Record<string, unknown>) {
    super('NO_ACTIVE_STAKE', 422, message, details)
  }
}
