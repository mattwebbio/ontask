import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── Users page ────────────────────────────────────────────────────────────────
// Accepts a raw userId (UUID) input and navigates to the charge history view
// or starts an impersonation session.
// TODO(impl): Replace raw-UUID input with email search once users table is queryable.

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

export default function UsersPage() {
  const navigate = useNavigate()
  const [userId, setUserId] = useState('')
  const [inputError, setInputError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [actionError, setActionError] = useState<string | null>(null)

  function handleViewCharges(e: React.FormEvent) {
    e.preventDefault()
    const trimmed = userId.trim()
    if (!trimmed) {
      setInputError('User ID is required')
      return
    }
    setInputError(null)
    setActionError(null)
    navigate(`/users/${trimmed}/charges`)
  }

  async function handleImpersonate(e: React.MouseEvent) {
    e.preventDefault()
    const trimmed = userId.trim()
    if (!trimmed) {
      setInputError('User ID is required')
      return
    }
    setInputError(null)
    setActionError(null)
    setLoading(true)

    try {
      const token = getToken()
      const res = await fetch(`${API_BASE}/admin/v1/users/${trimmed}/impersonate`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (res.status === 401) {
        setLoading(false)
        clearAuth()
        navigate('/login')
        return
      }
      if (res.status === 404) {
        setActionError('User not found')
        setLoading(false)
        return
      }
      if (!res.ok) {
        setActionError('Failed to start impersonation session')
        setLoading(false)
        return
      }

      const body = await res.json() as {
        data: {
          sessionId: string
          userId: string
          userEmail: string
          operatorEmail: string
          expiresAt: string
          startedAt: string
        }
      }

      sessionStorage.setItem('impersonationSession', JSON.stringify({
        sessionId: body.data.sessionId,
        userId: body.data.userId,
        userEmail: body.data.userEmail,
        operatorEmail: body.data.operatorEmail,
        expiresAt: body.data.expiresAt,
        startedAt: body.data.startedAt,
      }))

      setLoading(false)
      navigate(`/users/${trimmed}/impersonate-view`)
    } catch {
      setActionError('Failed to start impersonation session')
      setLoading(false)
    }
  }

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
      <h2 style={{ marginTop: 0, marginBottom: '1.25rem', fontSize: '1.4rem' }}>Users</h2>

      <div style={{
        padding: '1.5rem',
        background: '#fff',
        border: '1px solid #bdc3c7',
        borderRadius: '6px',
        maxWidth: '480px',
      }}>
        <p style={{ margin: '0 0 1rem', fontSize: '0.95rem', color: '#34495e' }}>
          Enter a user ID to view their charge history or start an impersonation session.
        </p>
        {/* TODO(impl): Replace raw-UUID input with email search once users table is queryable */}
        <form onSubmit={handleViewCharges}>
          <div style={{ marginBottom: '1rem' }}>
            <label
              htmlFor="userId"
              style={{ display: 'block', fontWeight: 'bold', marginBottom: '0.4rem', fontSize: '0.9rem' }}
            >
              User ID (UUID)
            </label>
            <input
              id="userId"
              type="text"
              value={userId}
              onChange={(e) => setUserId(e.target.value)}
              placeholder="e.g. 00000000-0000-4000-a000-000000000010"
              style={{
                width: '100%',
                padding: '0.5rem 0.75rem',
                borderRadius: '4px',
                border: '1px solid #bdc3c7',
                fontSize: '0.9rem',
                fontFamily: 'Arial, Helvetica, sans-serif',
                boxSizing: 'border-box',
              }}
            />
          </div>

          {inputError && (
            <div style={{ color: '#e74c3c', fontSize: '0.85rem', marginBottom: '0.75rem' }}>
              {inputError}
            </div>
          )}

          {actionError && (
            <div style={{ color: '#e74c3c', fontSize: '0.85rem', marginBottom: '0.75rem' }}>
              {actionError}
            </div>
          )}

          <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
            <button
              type="submit"
              style={{
                background: '#2c3e50',
                color: '#ecf0f1',
                border: 'none',
                padding: '0.55rem 1.25rem',
                borderRadius: '4px',
                cursor: 'pointer',
                fontSize: '0.9rem',
              }}
            >
              View Charges
            </button>

            <button
              type="button"
              onClick={(e) => void handleImpersonate(e)}
              disabled={loading}
              style={{
                background: loading ? '#95a5a6' : '#e74c3c',
                color: '#fff',
                border: 'none',
                padding: '0.55rem 1.25rem',
                borderRadius: '4px',
                cursor: loading ? 'not-allowed' : 'pointer',
                fontSize: '0.9rem',
                opacity: loading ? 0.7 : 1,
              }}
            >
              {loading ? 'Starting…' : 'Impersonate User'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
