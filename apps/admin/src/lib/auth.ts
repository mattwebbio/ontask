// ── Admin auth state ──────────────────────────────────────────────────────────
// Stores operator JWT and email in sessionStorage.
// sessionStorage is intentional — tokens must not persist across browser sessions.

const TOKEN_KEY = 'admin_token'
const EMAIL_KEY = 'admin_email'

export function saveAuth(token: string, email: string): void {
  sessionStorage.setItem(TOKEN_KEY, token)
  sessionStorage.setItem(EMAIL_KEY, email)
}

export function getToken(): string | null {
  return sessionStorage.getItem(TOKEN_KEY)
}

export function getOperatorEmail(): string | null {
  return sessionStorage.getItem(EMAIL_KEY)
}

export function clearAuth(): void {
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(EMAIL_KEY)
}

export function isAuthenticated(): boolean {
  return !!getToken()
}
