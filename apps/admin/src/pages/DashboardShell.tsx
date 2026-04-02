import { useEffect } from 'react'
import { NavLink, useNavigate, Routes, Route } from 'react-router-dom'
import { isAuthenticated, getOperatorEmail, clearAuth } from '../lib/auth'
import DisputesPage from './DisputesPage'
import DisputeDetailPage from './DisputeDetailPage'

function UsersPage() {
  return <h2>Users</h2>
}

function BillingPage() {
  return <h2>Billing</h2>
}

function MonitoringPage() {
  return <h2>Monitoring</h2>
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

// ── Dashboard shell ───────────────────────────────────────────────────────────

export default function DashboardShell() {
  const navigate = useNavigate()
  const operatorEmail = getOperatorEmail()

  useEffect(() => {
    if (!isAuthenticated()) {
      navigate('/login', { replace: true })
    }
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
            <Route path="/billing" element={<BillingPage />} />
            <Route path="/monitoring" element={<MonitoringPage />} />
            <Route path="/" element={<DisputesPage />} />
          </Routes>
        </main>
      </div>
    </div>
  )
}
