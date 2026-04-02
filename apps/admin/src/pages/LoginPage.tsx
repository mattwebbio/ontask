import { useState, FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { saveAuth } from '../lib/auth'

const ADMIN_API_URL = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

export default function LoginPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [totpCode, setTotpCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e: FormEvent) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)

    try {
      const res = await fetch(`${ADMIN_API_URL}/admin/v1/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password, totpCode }),
      })

      if (res.ok) {
        const body = await res.json() as { data: { token: string; operatorEmail: string } }
        saveAuth(body.data.token, body.data.operatorEmail)
        navigate('/')
      } else {
        setError('Invalid credentials or TOTP code')
      }
    } catch {
      setError('Unable to connect to admin API. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: '#f5f5f5',
      fontFamily: 'Arial, Helvetica, sans-serif',
    }}>
      <div style={{
        background: '#fff',
        padding: '2rem',
        borderRadius: '8px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        width: '100%',
        maxWidth: '360px',
      }}>
        <h1 style={{ marginTop: 0, marginBottom: '1.5rem', fontSize: '1.4rem' }}>
          OnTask Admin Login
        </h1>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '1rem' }}>
            <label htmlFor="email" style={{ display: 'block', marginBottom: '0.25rem', fontWeight: 'bold' }}>
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              autoComplete="email"
              style={{ width: '100%', padding: '0.5rem', boxSizing: 'border-box', border: '1px solid #ccc', borderRadius: '4px' }}
            />
          </div>

          <div style={{ marginBottom: '1rem' }}>
            <label htmlFor="password" style={{ display: 'block', marginBottom: '0.25rem', fontWeight: 'bold' }}>
              Password
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              autoComplete="current-password"
              style={{ width: '100%', padding: '0.5rem', boxSizing: 'border-box', border: '1px solid #ccc', borderRadius: '4px' }}
            />
          </div>

          <div style={{ marginBottom: '1.5rem' }}>
            <label htmlFor="totpCode" style={{ display: 'block', marginBottom: '0.25rem', fontWeight: 'bold' }}>
              TOTP Code
            </label>
            <input
              id="totpCode"
              type="text"
              value={totpCode}
              onChange={e => setTotpCode(e.target.value)}
              required
              maxLength={6}
              placeholder="6-digit code"
              autoComplete="one-time-code"
              inputMode="numeric"
              style={{ width: '100%', padding: '0.5rem', boxSizing: 'border-box', border: '1px solid #ccc', borderRadius: '4px' }}
            />
          </div>

          {error && (
            <p style={{ color: '#c0392b', marginBottom: '1rem', fontSize: '0.9rem' }}>
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={submitting}
            style={{
              width: '100%',
              padding: '0.75rem',
              background: '#2c3e50',
              color: '#fff',
              border: 'none',
              borderRadius: '4px',
              fontSize: '1rem',
              cursor: submitting ? 'not-allowed' : 'pointer',
              opacity: submitting ? 0.7 : 1,
            }}
          >
            {submitting ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  )
}
