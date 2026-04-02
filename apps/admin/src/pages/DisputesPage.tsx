import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── Dispute queue page ────────────────────────────────────────────────────────
// Fetches GET /admin/v1/disputes and displays dispute queue in FIFO order.
// SLA colouring: amber (#f39c12) at 18–22h, red (#e74c3c) at ≥22h.
// Navigates to /disputes/:id on row click.

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

interface DisputeItem {
  id: string
  taskId: string
  userId: string
  proofSubmissionId: string | null
  status: 'pending' | 'approved' | 'rejected'
  filedAt: string
  hoursElapsed: number
  slaStatus: 'ok' | 'amber' | 'red'
}

function getSlaStyle(slaStatus: DisputeItem['slaStatus']): React.CSSProperties {
  if (slaStatus === 'amber') {
    return { backgroundColor: '#fef9f0', borderLeft: '4px solid #f39c12' }
  }
  if (slaStatus === 'red') {
    return { backgroundColor: '#fdf0f0', borderLeft: '4px solid #e74c3c' }
  }
  return { borderLeft: '4px solid #2ecc71' }
}

function getSlaLabel(slaStatus: DisputeItem['slaStatus'], hoursElapsed: number): React.ReactElement {
  const hours = Math.floor(hoursElapsed)
  const label = `${hours}h elapsed`
  if (slaStatus === 'amber') {
    return (
      <span style={{ color: '#f39c12', fontWeight: 'bold', fontSize: '0.85rem' }}>
        {label} — approaching SLA
      </span>
    )
  }
  if (slaStatus === 'red') {
    return (
      <span style={{ color: '#e74c3c', fontWeight: 'bold', fontSize: '0.85rem' }}>
        {label} — SLA exceeded
      </span>
    )
  }
  return (
    <span style={{ color: '#27ae60', fontSize: '0.85rem' }}>
      {label}
    </span>
  )
}

export default function DisputesPage() {
  const navigate = useNavigate()
  const [disputes, setDisputes] = useState<DisputeItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function fetchDisputes() {
      try {
        const token = getToken()
        const res = await fetch(`${API_BASE}/admin/v1/disputes`, {
          headers: { 'Authorization': `Bearer ${token}` },
        })
        if (res.status === 401) {
          clearAuth()
          navigate('/login')
          return
        }
        if (!res.ok) {
          setError(`Failed to load disputes (${res.status})`)
          return
        }
        const body = await res.json() as { data: DisputeItem[] }
        setDisputes(body.data)
      } catch {
        setError('Network error loading disputes')
      } finally {
        setLoading(false)
      }
    }
    void fetchDisputes()
  }, [navigate])

  if (loading) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
        Loading disputes…
      </div>
    )
  }

  if (error) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif', color: '#e74c3c' }}>
        {error}
      </div>
    )
  }

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
      <h2 style={{ marginTop: 0, marginBottom: '1.25rem', fontSize: '1.4rem' }}>Dispute Queue</h2>

      {disputes.length === 0 ? (
        <p style={{ color: '#7f8c8d' }}>No pending disputes.</p>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
          {disputes.map((dispute) => (
            <div
              key={dispute.id}
              onClick={() => navigate(`/disputes/${dispute.id}`)}
              style={{
                padding: '1rem 1.25rem',
                background: '#fff',
                borderRadius: '6px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
                cursor: 'pointer',
                ...getSlaStyle(dispute.slaStatus),
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontWeight: 'bold', marginBottom: '0.25rem' }}>
                    Task ID: {dispute.taskId}
                  </div>
                  <div style={{ fontSize: '0.9rem', color: '#34495e', marginBottom: '0.25rem' }}>
                    User: {dispute.userId}
                  </div>
                  <div style={{ fontSize: '0.85rem', color: '#7f8c8d' }}>
                    Filed: {new Date(dispute.filedAt).toLocaleString()}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  {getSlaLabel(dispute.slaStatus, dispute.hoursElapsed)}
                  <div style={{ marginTop: '0.5rem' }}>
                    <span style={{
                      display: 'inline-block',
                      padding: '0.2rem 0.6rem',
                      borderRadius: '12px',
                      fontSize: '0.8rem',
                      background: '#ecf0f1',
                      color: '#2c3e50',
                      textTransform: 'uppercase',
                    }}>
                      {dispute.status}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
