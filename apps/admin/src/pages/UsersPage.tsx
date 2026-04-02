import { useState } from 'react'
import { useNavigate } from 'react-router-dom'

// ── Users page ────────────────────────────────────────────────────────────────
// Accepts a raw userId (UUID) input and navigates to the charge history view.
// TODO(impl): Replace raw-UUID input with email search once users table is queryable.

export default function UsersPage() {
  const navigate = useNavigate()
  const [userId, setUserId] = useState('')
  const [inputError, setInputError] = useState<string | null>(null)

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    const trimmed = userId.trim()
    if (!trimmed) {
      setInputError('User ID is required')
      return
    }
    setInputError(null)
    navigate(`/users/${trimmed}/charges`)
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
          Enter a user ID to view their charge history.
        </p>
        {/* TODO(impl): Replace raw-UUID input with email search once users table is queryable */}
        <form onSubmit={handleSubmit}>
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
        </form>
      </div>
    </div>
  )
}
