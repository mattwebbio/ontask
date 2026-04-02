import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── Dispute detail page ────────────────────────────────────────────────────────
// Fetches GET /admin/v1/disputes/:id and displays full dispute detail.
// Shows proof media inline, AI verification result, and resolution form.
// Resolution form is only shown when status === 'pending'.

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

interface DisputeDetail {
  id: string
  taskId: string
  taskTitle: string
  userId: string
  proofSubmissionId: string | null
  proofMediaUrl: string | null
  aiVerificationResult: {
    verified: boolean
    reason: string | null
  } | null
  status: 'pending' | 'approved' | 'rejected'
  operatorNote: string | null
  filedAt: string
  resolvedAt: string | null
  resolvedByUserId: string | null
  hoursElapsed: number
  slaStatus: 'ok' | 'amber' | 'red'
}

function getSlaColour(slaStatus: DisputeDetail['slaStatus']): string {
  if (slaStatus === 'amber') return '#f39c12'
  if (slaStatus === 'red') return '#e74c3c'
  return '#27ae60'
}

export default function DisputeDetailPage() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()
  const [dispute, setDispute] = useState<DisputeDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Resolution form state
  const [decision, setDecision] = useState<'approved' | 'rejected' | ''>('')
  const [operatorNote, setOperatorNote] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [resolved, setResolved] = useState(false)

  useEffect(() => {
    if (!id) return
    async function fetchDispute() {
      try {
        const token = getToken()
        const res = await fetch(`${API_BASE}/admin/v1/disputes/${id}`, {
          headers: { 'Authorization': `Bearer ${token}` },
        })
        if (res.status === 401) {
          clearAuth()
          navigate('/login')
          return
        }
        if (res.status === 404) {
          setError('Dispute not found')
          return
        }
        if (!res.ok) {
          setError(`Failed to load dispute (${res.status})`)
          return
        }
        const body = await res.json() as { data: DisputeDetail }
        setDispute(body.data)
      } catch {
        setError('Network error loading dispute')
      } finally {
        setLoading(false)
      }
    }
    void fetchDispute()
  }, [id, navigate])

  async function handleResolve(e: React.FormEvent) {
    e.preventDefault()
    setSubmitError(null)

    if (!decision) {
      setSubmitError('Please select a decision.')
      return
    }
    if (!operatorNote.trim()) {
      setSubmitError('Decision note is required')
      return
    }

    setSubmitting(true)
    try {
      const token = getToken()
      const res = await fetch(`${API_BASE}/admin/v1/disputes/${id}/resolve`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ decision, operatorNote }),
      })
      if (res.status === 401) {
        clearAuth()
        navigate('/login')
        return
      }
      if (res.status === 400) {
        setSubmitError('Decision note is required')
        return
      }
      if (res.status === 404) {
        setSubmitError('Dispute not found')
        return
      }
      if (res.status === 409) {
        setSubmitError('Dispute has already been resolved')
        return
      }
      if (!res.ok) {
        setSubmitError(`Unexpected error (${res.status})`)
        return
      }
      setResolved(true)
      // Update local state to reflect resolved status
      if (dispute) {
        setDispute({ ...dispute, status: decision as 'approved' | 'rejected' })
      }
    } catch {
      setSubmitError('Network error submitting resolution')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
        Loading dispute…
      </div>
    )
  }

  if (error) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif' }}>
        <div style={{ color: '#e74c3c', marginBottom: '1rem' }}>{error}</div>
        <button
          onClick={() => navigate('/disputes')}
          style={{
            background: 'transparent',
            border: '1px solid #2c3e50',
            color: '#2c3e50',
            padding: '0.4rem 0.9rem',
            borderRadius: '4px',
            cursor: 'pointer',
            fontSize: '0.9rem',
          }}
        >
          ← Back to Disputes
        </button>
      </div>
    )
  }

  if (!dispute) return null

  const slaColour = getSlaColour(dispute.slaStatus)

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50', maxWidth: '800px' }}>
      {/* Back link */}
      <button
        onClick={() => navigate('/disputes')}
        style={{
          background: 'transparent',
          border: 'none',
          color: '#2980b9',
          cursor: 'pointer',
          fontSize: '0.9rem',
          padding: 0,
          marginBottom: '1.25rem',
          textDecoration: 'underline',
        }}
      >
        ← Back to Disputes
      </button>

      <h2 style={{ marginTop: 0, marginBottom: '1.5rem', fontSize: '1.4rem' }}>
        Dispute Review
      </h2>

      {/* Task info */}
      <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#ecf0f1', borderRadius: '6px' }}>
        <h3 style={{ marginTop: 0, marginBottom: '0.75rem', fontSize: '1.1rem' }}>Task</h3>
        <div style={{ marginBottom: '0.5rem' }}>
          <strong>Title:</strong> {dispute.taskTitle}
        </div>
        <div style={{ marginBottom: '0.5rem' }}>
          <strong>Task ID:</strong> {dispute.taskId}
        </div>
        <div>
          <strong>User ID:</strong> {dispute.userId}
        </div>
      </section>

      {/* SLA / timing */}
      <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#ecf0f1', borderRadius: '6px' }}>
        <h3 style={{ marginTop: 0, marginBottom: '0.75rem', fontSize: '1.1rem' }}>SLA Status</h3>
        <div style={{ marginBottom: '0.5rem' }}>
          <strong>Filed:</strong> {new Date(dispute.filedAt).toLocaleString()}
        </div>
        <div style={{ marginBottom: '0.5rem' }}>
          <strong>Hours Elapsed:</strong>{' '}
          <span style={{ color: slaColour, fontWeight: 'bold' }}>
            {Math.floor(dispute.hoursElapsed)}h
          </span>
        </div>
        <div>
          <strong>SLA Status:</strong>{' '}
          <span style={{ color: slaColour, fontWeight: 'bold', textTransform: 'uppercase' }}>
            {dispute.slaStatus}
          </span>
        </div>
      </section>

      {/* Proof media */}
      <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#ecf0f1', borderRadius: '6px' }}>
        <h3 style={{ marginTop: 0, marginBottom: '0.75rem', fontSize: '1.1rem' }}>Submitted Proof</h3>
        {dispute.proofMediaUrl ? (
          <img
            src={dispute.proofMediaUrl}
            alt="Submitted proof media"
            style={{ maxWidth: '100%', maxHeight: '400px', borderRadius: '4px', display: 'block' }}
          />
        ) : (
          <p style={{ color: '#7f8c8d', margin: 0 }}>No media submitted</p>
        )}
      </section>

      {/* AI verification result */}
      <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#ecf0f1', borderRadius: '6px' }}>
        <h3 style={{ marginTop: 0, marginBottom: '0.75rem', fontSize: '1.1rem' }}>AI Verification Result</h3>
        {dispute.aiVerificationResult ? (
          <>
            <div style={{ marginBottom: '0.5rem' }}>
              <strong>Verified:</strong>{' '}
              <span style={{ color: dispute.aiVerificationResult.verified ? '#27ae60' : '#e74c3c', fontWeight: 'bold' }}>
                {dispute.aiVerificationResult.verified ? 'Yes' : 'No'}
              </span>
            </div>
            {dispute.aiVerificationResult.reason && (
              <div>
                <strong>Reason:</strong> {dispute.aiVerificationResult.reason}
              </div>
            )}
          </>
        ) : (
          <p style={{ color: '#7f8c8d', margin: 0 }}>No AI verification result available</p>
        )}
      </section>

      {/* Resolution form — only shown when pending */}
      {dispute.status === 'pending' && !resolved && (
        <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#fff', border: '1px solid #bdc3c7', borderRadius: '6px' }}>
          <h3 style={{ marginTop: 0, marginBottom: '1rem', fontSize: '1.1rem' }}>Operator Decision</h3>
          <form onSubmit={(e) => void handleResolve(e)}>
            <div style={{ marginBottom: '1rem' }}>
              <strong style={{ display: 'block', marginBottom: '0.5rem' }}>Decision:</strong>
              <label style={{ marginRight: '1.5rem', cursor: 'pointer' }}>
                <input
                  type="radio"
                  name="decision"
                  value="approved"
                  checked={decision === 'approved'}
                  onChange={() => setDecision('approved')}
                  style={{ marginRight: '0.4rem' }}
                />
                Approve (cancel stake charge, mark task verified complete)
              </label>
              <label style={{ cursor: 'pointer' }}>
                <input
                  type="radio"
                  name="decision"
                  value="rejected"
                  checked={decision === 'rejected'}
                  onChange={() => setDecision('rejected')}
                  style={{ marginRight: '0.4rem' }}
                />
                Reject (process Stripe charge)
              </label>
            </div>

            <div style={{ marginBottom: '1rem' }}>
              <label style={{ display: 'block', fontWeight: 'bold', marginBottom: '0.5rem' }}>
                Decision Note <span style={{ color: '#e74c3c' }}>*</span>{' '}
                <span style={{ fontWeight: 'normal', fontSize: '0.85rem', color: '#7f8c8d' }}>(internal — not user-visible)</span>
              </label>
              <textarea
                value={operatorNote}
                onChange={(e) => setOperatorNote(e.target.value)}
                placeholder="Required. Summarise your reasoning for this decision."
                rows={4}
                style={{
                  width: '100%',
                  padding: '0.6rem',
                  borderRadius: '4px',
                  border: '1px solid #bdc3c7',
                  fontSize: '0.95rem',
                  fontFamily: 'Arial, Helvetica, sans-serif',
                  resize: 'vertical',
                  boxSizing: 'border-box',
                }}
              />
            </div>

            {submitError && (
              <div style={{ color: '#e74c3c', marginBottom: '1rem', fontSize: '0.9rem' }}>
                {submitError}
              </div>
            )}

            <button
              type="submit"
              disabled={submitting}
              style={{
                background: '#2c3e50',
                color: '#ecf0f1',
                border: 'none',
                padding: '0.6rem 1.4rem',
                borderRadius: '4px',
                cursor: submitting ? 'not-allowed' : 'pointer',
                fontSize: '0.95rem',
                opacity: submitting ? 0.7 : 1,
              }}
            >
              {submitting ? 'Submitting…' : 'Submit Decision'}
            </button>
          </form>
        </section>
      )}

      {/* Resolved confirmation */}
      {(resolved || dispute.status !== 'pending') && (
        <section style={{ marginBottom: '1.5rem', padding: '1rem', background: '#eafaf1', border: '1px solid #27ae60', borderRadius: '6px' }}>
          {resolved ? (
            <p style={{ margin: 0, color: '#27ae60', fontWeight: 'bold' }}>Dispute resolved.</p>
          ) : (
            <>
              <p style={{ margin: 0, fontWeight: 'bold', marginBottom: '0.5rem' }}>
                Dispute already resolved: <span style={{ textTransform: 'uppercase' }}>{dispute.status}</span>
              </p>
              {dispute.operatorNote && (
                <p style={{ margin: 0, color: '#2c3e50' }}>
                  <strong>Operator Note:</strong> {dispute.operatorNote}
                </p>
              )}
              {dispute.resolvedAt && (
                <p style={{ margin: 0, color: '#7f8c8d', fontSize: '0.85rem', marginTop: '0.5rem' }}>
                  Resolved at: {new Date(dispute.resolvedAt).toLocaleString()}
                </p>
              )}
            </>
          )}
        </section>
      )}
    </div>
  )
}
