import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── Impersonate user page ──────────────────────────────────────────────────────
// Shows operator the impersonated user's account state with a persistent banner.
// Enforces 30-minute session timeout with auto-end.
// Audit logs all session events via operator_impersonation_logs (NFR-S6).
// (Story 11.4, FR53, NFR-S6)

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

interface ImpersonationSession {
  sessionId: string
  userId: string
  userEmail: string
  operatorEmail: string
  expiresAt: string
  startedAt: string
}

// ── Required banner styles (AC1) ──────────────────────────────────────────────
const bannerStyle: React.CSSProperties = {
  background: '#e74c3c',
  color: '#fff',
  padding: '0.6rem 1.5rem',
  fontSize: '0.9rem',
  fontFamily: 'Arial, Helvetica, sans-serif',
  display: 'flex',
  justifyContent: 'space-between',
  alignItems: 'center',
}

export default function ImpersonateUserPage() {
  const navigate = useNavigate()
  const { userId } = useParams<{ userId: string }>()
  const [session, setSession] = useState<ImpersonationSession | null>(null)
  const [sessionExpired, setSessionExpired] = useState(false)
  const [ending, setEnding] = useState(false)
  const [endError, setEndError] = useState<string | null>(null)

  // ── Session end helpers ──────────────────────────────────────────────────────

  async function callEndSession(sessionId: string, impersonatedUserId: string, reason: 'operator_ended' | 'session_timeout'): Promise<void> {
    const token = getToken()
    try {
      const res = await fetch(`${API_BASE}/admin/v1/impersonation/${sessionId}/end`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: impersonatedUserId, reason }),
      })
      if (res.status === 401) {
        clearAuth()
        navigate('/login')
        return
      }
      if (!res.ok) {
        console.warn(`End session returned ${res.status}`)
      }
    } catch {
      // Best effort — always clean up sessionStorage and navigate
    }
  }

  async function callLogAction(sessionId: string, impersonatedUserId: string, actionDetail: string): Promise<void> {
    const token = getToken()
    try {
      await fetch(`${API_BASE}/admin/v1/impersonation/${sessionId}/log-action`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: impersonatedUserId, actionDetail }),
      })
    } catch {
      // Best effort — audit log failure should not block session cleanup
    }
  }

  // ── Mount: load session from sessionStorage ──────────────────────────────────

  useEffect(() => {
    const raw = sessionStorage.getItem('impersonationSession')
    if (!raw) {
      navigate('/users')
      return
    }

    let parsed: ImpersonationSession
    try {
      parsed = JSON.parse(raw) as ImpersonationSession
    } catch {
      navigate('/users')
      return
    }

    // Check if already expired on mount
    if (new Date(parsed.expiresAt).getTime() < Date.now()) {
      setSessionExpired(true)
      sessionStorage.removeItem('impersonationSession')
      void (async () => {
        await callLogAction(parsed.sessionId, parsed.userId, 'Session timed out after 30 minutes')
        await callEndSession(parsed.sessionId, parsed.userId, 'session_timeout')
        setTimeout(() => navigate('/users'), 3000)
      })()
      return
    }

    setSession(parsed)

    // ── Session timeout interval (checks every 30 seconds) ───────────────────
    const intervalId = setInterval(() => {
      const stillRaw = sessionStorage.getItem('impersonationSession')
      if (!stillRaw) {
        clearInterval(intervalId)
        navigate('/users')
        return
      }

      let current: ImpersonationSession
      try {
        current = JSON.parse(stillRaw) as ImpersonationSession
      } catch {
        clearInterval(intervalId)
        navigate('/users')
        return
      }

      if (new Date(current.expiresAt).getTime() < Date.now()) {
        clearInterval(intervalId)
        setSessionExpired(true)
        sessionStorage.removeItem('impersonationSession')
        void (async () => {
          await callLogAction(current.sessionId, current.userId, 'Session timed out after 30 minutes')
          await callEndSession(current.sessionId, current.userId, 'session_timeout')
          setTimeout(() => navigate('/users'), 3000)
        })()
      }
    }, 30_000)

    return () => clearInterval(intervalId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigate])

  // ── End impersonation button handler ────────────────────────────────────────

  async function handleEndImpersonation() {
    if (!session) return
    setEnding(true)
    setEndError(null)

    const token = getToken()

    try {
      await callLogAction(session.sessionId, session.userId, 'Operator ended session')
      const res = await fetch(`${API_BASE}/admin/v1/impersonation/${session.sessionId}/end`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ userId: session.userId, reason: 'operator_ended' }),
      })

      if (res.status === 401) {
        setEnding(false)
        clearAuth()
        navigate('/login')
        return
      }

      if (!res.ok) {
        const body = await res.json().catch(() => null) as { error?: { message?: string } } | null
        setEndError(body?.error?.message ?? 'Failed to end impersonation session. Please try again.')
        setEnding(false)
        return
      }

      sessionStorage.removeItem('impersonationSession')
      setEnding(false)
      navigate('/users')
    } catch {
      setEndError('Failed to end impersonation session. Please try again.')
      setEnding(false)
    }
  }

  // ── Session expired state ────────────────────────────────────────────────────

  if (sessionExpired) {
    return (
      <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50', padding: '2rem' }}>
        <div style={{ color: '#e74c3c', fontSize: '1rem', marginBottom: '0.5rem', fontWeight: 'bold' }}>
          Impersonation session expired
        </div>
        <p style={{ color: '#7f8c8d', fontSize: '0.9rem' }}>
          The 30-minute session has ended. Redirecting to Users…
        </p>
      </div>
    )
  }

  // ── Loading state (session not yet parsed) ──────────────────────────────────

  if (!session) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
        Loading impersonation session…
      </div>
    )
  }

  // ── Main impersonation view ──────────────────────────────────────────────────

  const expiresAtFormatted = new Date(session.expiresAt).toLocaleTimeString()

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
      {/* Persistent impersonation banner — always visible (AC1) */}
      <div style={bannerStyle}>
        <span>
          Viewing as <strong>{session.userEmail}</strong> — {session.operatorEmail}
          <span style={{ marginLeft: '1.5rem', fontSize: '0.85rem', opacity: 0.9 }}>
            Session expires at {expiresAtFormatted}
          </span>
        </span>
        <button
          onClick={() => void handleEndImpersonation()}
          disabled={ending}
          style={{
            background: 'rgba(255,255,255,0.15)',
            color: '#fff',
            border: '1px solid rgba(255,255,255,0.5)',
            padding: '0.35rem 0.9rem',
            borderRadius: '4px',
            cursor: ending ? 'not-allowed' : 'pointer',
            fontSize: '0.85rem',
            opacity: ending ? 0.7 : 1,
          }}
        >
          {ending ? 'Ending…' : 'End Impersonation'}
        </button>
      </div>

      {/* Page content */}
      <div style={{ padding: '1.5rem' }}>
        <h2 style={{ marginTop: 0, marginBottom: '1.25rem', fontSize: '1.4rem' }}>
          Impersonation View
        </h2>

        {endError && (
          <div style={{ color: '#e74c3c', fontSize: '0.9rem', marginBottom: '1rem' }}>
            {endError}
          </div>
        )}

        {/* Read-only user account data view */}
        {/* TODO(impl): Replace with full read-only user account data view once user data APIs are available */}
        <div style={{
          background: '#fff',
          border: '1px solid #bdc3c7',
          borderRadius: '6px',
          padding: '1.5rem',
          maxWidth: '560px',
        }}>
          <h3 style={{ marginTop: 0, marginBottom: '1rem', fontSize: '1.1rem', color: '#2c3e50' }}>
            Session Details
          </h3>

          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
            <tbody>
              <tr style={{ borderBottom: '1px solid #ecf0f1' }}>
                <td style={{ padding: '0.6rem 0', color: '#7f8c8d', width: '160px', fontWeight: 'bold' }}>User ID</td>
                <td style={{ padding: '0.6rem 0', fontFamily: 'monospace', fontSize: '0.85rem' }}>{userId ?? session.userId}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #ecf0f1' }}>
                <td style={{ padding: '0.6rem 0', color: '#7f8c8d', fontWeight: 'bold' }}>User Email</td>
                <td style={{ padding: '0.6rem 0' }}>{session.userEmail}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #ecf0f1' }}>
                <td style={{ padding: '0.6rem 0', color: '#7f8c8d', fontWeight: 'bold' }}>Session ID</td>
                <td style={{ padding: '0.6rem 0', fontFamily: 'monospace', fontSize: '0.85rem' }}>{session.sessionId}</td>
              </tr>
              <tr style={{ borderBottom: '1px solid #ecf0f1' }}>
                <td style={{ padding: '0.6rem 0', color: '#7f8c8d', fontWeight: 'bold' }}>Session Started</td>
                <td style={{ padding: '0.6rem 0' }}>{new Date(session.startedAt).toLocaleString()}</td>
              </tr>
              <tr>
                <td style={{ padding: '0.6rem 0', color: '#7f8c8d', fontWeight: 'bold' }}>Session Expires</td>
                <td style={{ padding: '0.6rem 0' }}>{new Date(session.expiresAt).toLocaleString()}</td>
              </tr>
            </tbody>
          </table>

          <div style={{ marginTop: '1.25rem' }}>
            <button
              onClick={() => navigate(`/users/${userId ?? session.userId}/charges`)}
              style={{
                background: 'transparent',
                border: 'none',
                color: '#2980b9',
                cursor: 'pointer',
                fontSize: '0.9rem',
                padding: 0,
                textDecoration: 'underline',
              }}
            >
              View Charge History
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
