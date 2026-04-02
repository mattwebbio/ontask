import { useEffect, useState } from 'react'
import { NavLink, useNavigate, Routes, Route } from 'react-router-dom'
import { isAuthenticated, getOperatorEmail, clearAuth, getToken } from '../lib/auth'
import DisputesPage from './DisputesPage'
import DisputeDetailPage from './DisputeDetailPage'
import UsersPage from './UsersPage'
import UserChargesPage from './UserChargesPage'
import ImpersonateUserPage from './ImpersonateUserPage'
import MonitoringPage from './MonitoringPage'

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

function BillingPage() {
  return <h2>Billing</h2>
}

// ── Sidebar styles ────────────────────────────────────────────────────────────

const navLinkStyle: React.CSSProperties = {
  display: 'block',
  padding: '0.6rem 1rem',
  color: '#ecf0f1',
  textDecoration: 'none',
  borderRadius: '4px',
  marginBottom: '0.25rem',
  fontFamily: 'Arial, Helvetica, sans-serif',
}

const navLinkActiveStyle: React.CSSProperties = {
  ...navLinkStyle,
  background: '#34495e',
  fontWeight: 'bold',
}

// ── Alert badge style ─────────────────────────────────────────────────────────

const badgeStyle: React.CSSProperties = {
  background: '#e74c3c',
  color: '#fff',
  borderRadius: '50%',
  padding: '0.1rem 0.4rem',
  fontSize: '0.7rem',
  marginLeft: '0.4rem',
  fontWeight: 'bold',
  display: 'inline-block',
}

// ── Dashboard shell ───────────────────────────────────────────────────────────

export default function DashboardShell() {
  const navigate = useNavigate()
  const operatorEmail = getOperatorEmail()
  const [unacknowledgedAlertCount, setUnacknowledgedAlertCount] = useState(0)

  useEffect(() => {
    if (!isAuthenticated()) {
      navigate('/login', { replace: true })
    }
  }, [navigate])

  // ── Alert polling (every 60 seconds) ─────────────────────────────────────────
  useEffect(() => {
    async function pollAlerts() {
      try {
        const token = getToken()
        const res = await fetch(`${API_BASE}/admin/v1/alerts`, {
          headers: { 'Authorization': `Bearer ${token}` },
        })
        if (res.status === 401) {
          clearAuth()
          navigate('/login')
          return
        }
        if (!res.ok) {
          // Non-401 errors: silently ignore — don't interrupt operator workflow
          return
        }
        const body = await res.json() as { data?: { unacknowledgedCount?: number } }
        setUnacknowledgedAlertCount(body.data?.unacknowledgedCount ?? 0)
      } catch {
        // Silently ignore network errors — never show a polling error to the operator
      }
    }

    // Initial poll on mount
    void pollAlerts()

    // Poll every 60 seconds
    const intervalId = setInterval(() => {
      void pollAlerts()
    }, 60_000)

    return () => clearInterval(intervalId)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [navigate])

  function handleLogout() {
    clearAuth()
    navigate('/login')
  }

  return (
    <div style={{ display: 'flex', minHeight: '100vh', fontFamily: 'Arial, Helvetica, sans-serif' }}>
      {/* Sidebar */}
      <nav style={{
        width: '200px',
        background: '#2c3e50',
        padding: '1rem',
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
      }}>
        <div style={{ color: '#ecf0f1', fontWeight: 'bold', marginBottom: '1.5rem', fontSize: '1rem' }}>
          Navigation
        </div>
        <NavLink
          to="/disputes"
          style={({ isActive }) => isActive ? navLinkActiveStyle : navLinkStyle}
        >
          Disputes
        </NavLink>
        <NavLink
          to="/users"
          style={({ isActive }) => isActive ? navLinkActiveStyle : navLinkStyle}
        >
          Users
        </NavLink>
        <NavLink
          to="/billing"
          style={({ isActive }) => isActive ? navLinkActiveStyle : navLinkStyle}
        >
          Billing
        </NavLink>
        <NavLink
          to="/monitoring"
          style={({ isActive }) => isActive ? navLinkActiveStyle : navLinkStyle}
        >
          Monitoring
          {unacknowledgedAlertCount > 0 && (
            <span style={badgeStyle}>
              {unacknowledgedAlertCount}
            </span>
          )}
        </NavLink>
      </nav>

      {/* Main area */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        {/* Header */}
        <header style={{
          background: '#34495e',
          color: '#ecf0f1',
          padding: '0.75rem 1.5rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
        }}>
          <span style={{ fontWeight: 'bold', fontSize: '1.1rem' }}>OnTask Admin</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            {operatorEmail && (
              <span style={{ fontSize: '0.9rem' }}>{operatorEmail}</span>
            )}
            <button
              onClick={handleLogout}
              style={{
                background: 'transparent',
                border: '1px solid #ecf0f1',
                color: '#ecf0f1',
                padding: '0.3rem 0.75rem',
                borderRadius: '4px',
                cursor: 'pointer',
                fontSize: '0.85rem',
              }}
            >
              Logout
            </button>
          </div>
        </header>

        {/* Content */}
        <main style={{ flex: 1, padding: '1.5rem' }}>
          <Routes>
            <Route path="/disputes" element={<DisputesPage />} />
            <Route path="/disputes/:id" element={<DisputeDetailPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/users/:userId/charges" element={<UserChargesPage />} />
            <Route path="/users/:userId/impersonate-view" element={<ImpersonateUserPage />} />
            <Route path="/billing" element={<BillingPage />} />
            <Route path="/monitoring" element={<MonitoringPage />} />
            <Route path="/" element={<DisputesPage />} />
          </Routes>
        </main>
      </div>
    </div>
  )
}
