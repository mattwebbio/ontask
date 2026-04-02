import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── User charges page ─────────────────────────────────────────────────────────
// Fetches GET /admin/v1/users/:userId/charges and displays charge table.
// Inline refund form opens per-row for charges not yet fully refunded.
// refundStatus badge: none=grey, partial=amber, full=green.

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

interface ChargeItem {
  id: string
  taskId: string
  taskTitle: string
  amountCents: number
  charityAmountCents: number
  platformAmountCents: number
  charityName: string
  status: string
  refundStatus: 'none' | 'partial' | 'full'
  refundedAmountCents: number | null
  stripePaymentIntentId: string | null
  chargedAt: string | null
  createdAt: string
}

function formatAmount(cents: number): string {
  return `$${(cents / 100).toFixed(2)}`
}

function getRefundBadgeStyle(refundStatus: ChargeItem['refundStatus']): React.CSSProperties {
  const base: React.CSSProperties = {
    display: 'inline-block',
    padding: '0.2rem 0.6rem',
    borderRadius: '12px',
    fontSize: '0.8rem',
    fontWeight: 'bold',
    textTransform: 'uppercase',
  }
  if (refundStatus === 'full') {
    return { ...base, background: '#eafaf1', color: '#27ae60', border: '1px solid #27ae60' }
  }
  if (refundStatus === 'partial') {
    return { ...base, background: '#fef9f0', color: '#f39c12', border: '1px solid #f39c12' }
  }
  // none
  return { ...base, background: '#f4f4f4', color: '#95a5a6', border: '1px solid #bdc3c7' }
}

interface RefundFormState {
  amountCents: string
  reason: string
  submitting: boolean
  error: string | null
  success: string | null
}

export default function UserChargesPage() {
  const navigate = useNavigate()
  const { userId } = useParams<{ userId: string }>()
  const [charges, setCharges] = useState<ChargeItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  // Track which charge has its refund form open
  const [openRefundId, setOpenRefundId] = useState<string | null>(null)
  const [refundForms, setRefundForms] = useState<Record<string, RefundFormState>>({})

  async function fetchCharges() {
    if (!userId) {
      setLoading(false)
      return
    }
    try {
      const token = getToken()
      const res = await fetch(`${API_BASE}/admin/v1/users/${userId}/charges`, {
        headers: { 'Authorization': `Bearer ${token}` },
      })
      if (res.status === 401) {
        clearAuth()
        navigate('/login')
        return
      }
      if (!res.ok) {
        setError(`Failed to load charges (${res.status})`)
        return
      }
      const body = await res.json() as { data: ChargeItem[] }
      setCharges(body.data)
    } catch {
      setError('Network error loading charges')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    void fetchCharges()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId, navigate])

  function openRefundForm(chargeId: string) {
    setOpenRefundId(chargeId)
    if (!refundForms[chargeId]) {
      setRefundForms((prev) => ({
        ...prev,
        [chargeId]: { amountCents: '', reason: '', submitting: false, error: null, success: null },
      }))
    }
  }

  function closeRefundForm() {
    setOpenRefundId(null)
  }

  function updateRefundForm(chargeId: string, patch: Partial<RefundFormState>) {
    setRefundForms((prev) => ({
      ...prev,
      [chargeId]: { ...prev[chargeId], ...patch },
    }))
  }

  async function handleRefundSubmit(e: React.FormEvent, charge: ChargeItem) {
    e.preventDefault()
    const form = refundForms[charge.id]
    if (!form) return

    const alreadyRefunded = charge.refundedAmountCents ?? 0
    const maxRefundable = charge.amountCents - alreadyRefunded
    const parsedAmount = parseInt(form.amountCents, 10)

    if (!form.reason.trim()) {
      updateRefundForm(charge.id, { error: 'Reason is required' })
      return
    }
    if (!parsedAmount || parsedAmount <= 0) {
      updateRefundForm(charge.id, { error: 'Refund amount must be greater than 0' })
      return
    }
    if (parsedAmount > maxRefundable) {
      updateRefundForm(charge.id, { error: `Refund amount exceeds charge amount ($${(maxRefundable / 100).toFixed(2)} remaining)` })
      return
    }

    updateRefundForm(charge.id, { submitting: true, error: null })

    try {
      const token = getToken()
      const res = await fetch(`${API_BASE}/admin/v1/charges/${charge.id}/refund`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ amountCents: parsedAmount, reason: form.reason.trim() }),
      })

      if (res.status === 401) {
        clearAuth()
        navigate('/login')
        return
      }
      if (res.status === 400) {
        const body = await res.json() as { error?: { message?: string } }
        const msg = body?.error?.message ?? 'Refund amount exceeds charge amount'
        updateRefundForm(charge.id, { error: msg, submitting: false })
        return
      }
      if (res.status === 409) {
        updateRefundForm(charge.id, { error: 'Charge already fully refunded', submitting: false })
        return
      }
      if (!res.ok) {
        updateRefundForm(charge.id, { error: `Unexpected error (${res.status})`, submitting: false })
        return
      }

      // Success — refresh charge list and show confirmation
      updateRefundForm(charge.id, { submitting: false, success: 'Refund processed', amountCents: '', reason: '' })
      setOpenRefundId(null)
      // Re-fetch to get updated refund status
      setLoading(true)
      void fetchCharges()
    } catch {
      updateRefundForm(charge.id, { error: 'Network error submitting refund', submitting: false })
    }
  }

  if (loading) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
        Loading charges…
      </div>
    )
  }

  if (error) {
    return (
      <div style={{ padding: '1rem', fontFamily: 'Arial, Helvetica, sans-serif' }}>
        <div style={{ color: '#e74c3c', marginBottom: '1rem' }}>{error}</div>
        <button
          onClick={() => navigate('/users')}
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
          Back to Users
        </button>
      </div>
    )
  }

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
      {/* Back link */}
      <button
        onClick={() => navigate('/users')}
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
        Back to Users
      </button>

      <h2 style={{ marginTop: 0, marginBottom: '0.5rem', fontSize: '1.4rem' }}>Charge History</h2>
      <p style={{ margin: '0 0 1.25rem', fontSize: '0.9rem', color: '#7f8c8d' }}>
        User ID: {userId}
      </p>

      {charges.length === 0 ? (
        <p style={{ color: '#7f8c8d' }}>No charges found for this user.</p>
      ) : (
        <div>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '0.9rem' }}>
            <thead>
              <tr style={{ background: '#ecf0f1', textAlign: 'left' }}>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Date</th>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Task</th>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Amount</th>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Charity</th>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Refund Status</th>
                <th style={{ padding: '0.6rem 0.75rem', fontWeight: 'bold', borderBottom: '2px solid #bdc3c7' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {charges.map((charge) => {
                const form = refundForms[charge.id]
                const isOpen = openRefundId === charge.id
                const dateStr = new Date(charge.chargedAt ?? charge.createdAt).toLocaleString()
                const alreadyRefunded = charge.refundedAmountCents ?? 0
                const maxRefundable = charge.amountCents - alreadyRefunded

                return (
                  <>
                    <tr
                      key={charge.id}
                      style={{ borderBottom: isOpen ? 'none' : '1px solid #ecf0f1' }}
                    >
                      <td style={{ padding: '0.65rem 0.75rem', color: '#34495e' }}>{dateStr}</td>
                      <td style={{ padding: '0.65rem 0.75rem', fontWeight: 'bold' }}>{charge.taskTitle}</td>
                      <td style={{ padding: '0.65rem 0.75rem' }}>{formatAmount(charge.amountCents)}</td>
                      <td style={{ padding: '0.65rem 0.75rem', color: '#34495e' }}>{charge.charityName}</td>
                      <td style={{ padding: '0.65rem 0.75rem' }}>
                        <span style={getRefundBadgeStyle(charge.refundStatus)}>
                          {charge.refundStatus}
                        </span>
                        {charge.refundedAmountCents != null && (
                          <span style={{ marginLeft: '0.5rem', fontSize: '0.8rem', color: '#7f8c8d' }}>
                            ({formatAmount(charge.refundedAmountCents)} refunded)
                          </span>
                        )}
                      </td>
                      <td style={{ padding: '0.65rem 0.75rem' }}>
                        {form?.success && !isOpen && (
                          <span style={{ color: '#27ae60', fontSize: '0.85rem', marginRight: '0.75rem' }}>
                            {form.success}
                          </span>
                        )}
                        {charge.refundStatus !== 'full' && (
                          <button
                            onClick={() => isOpen ? closeRefundForm() : openRefundForm(charge.id)}
                            style={{
                              background: isOpen ? '#ecf0f1' : '#2c3e50',
                              color: isOpen ? '#2c3e50' : '#ecf0f1',
                              border: isOpen ? '1px solid #bdc3c7' : 'none',
                              padding: '0.3rem 0.75rem',
                              borderRadius: '4px',
                              cursor: 'pointer',
                              fontSize: '0.85rem',
                            }}
                          >
                            {isOpen ? 'Cancel' : 'Refund'}
                          </button>
                        )}
                      </td>
                    </tr>

                    {/* Inline refund form */}
                    {isOpen && form && (
                      <tr key={`${charge.id}-refund`} style={{ borderBottom: '1px solid #ecf0f1' }}>
                        <td
                          colSpan={6}
                          style={{ padding: '0.75rem 0.75rem 1rem', background: '#fafafa', borderTop: '1px solid #ecf0f1' }}
                        >
                          <form onSubmit={(e) => void handleRefundSubmit(e, charge)}>
                            <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap', alignItems: 'flex-start' }}>
                              <div style={{ flex: '0 0 180px' }}>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '0.3rem' }}>
                                  Amount (cents) <span style={{ color: '#e74c3c' }}>*</span>
                                  <span style={{ fontWeight: 'normal', color: '#7f8c8d' }}> (max: {maxRefundable})</span>
                                </label>
                                <input
                                  type="number"
                                  min={1}
                                  max={maxRefundable}
                                  value={form.amountCents}
                                  onChange={(e) => updateRefundForm(charge.id, { amountCents: e.target.value })}
                                  placeholder={`1–${maxRefundable}`}
                                  style={{
                                    width: '100%',
                                    padding: '0.4rem 0.6rem',
                                    borderRadius: '4px',
                                    border: '1px solid #bdc3c7',
                                    fontSize: '0.9rem',
                                    fontFamily: 'Arial, Helvetica, sans-serif',
                                    boxSizing: 'border-box',
                                  }}
                                />
                              </div>

                              <div style={{ flex: '1 1 280px' }}>
                                <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: 'bold', marginBottom: '0.3rem' }}>
                                  Reason <span style={{ color: '#e74c3c' }}>*</span>{' '}
                                  <span style={{ fontWeight: 'normal', color: '#7f8c8d' }}>(internal — not user-visible)</span>
                                </label>
                                <textarea
                                  value={form.reason}
                                  onChange={(e) => updateRefundForm(charge.id, { reason: e.target.value })}
                                  placeholder="Required. Explain the reason for this refund."
                                  rows={2}
                                  style={{
                                    width: '100%',
                                    padding: '0.4rem 0.6rem',
                                    borderRadius: '4px',
                                    border: '1px solid #bdc3c7',
                                    fontSize: '0.9rem',
                                    fontFamily: 'Arial, Helvetica, sans-serif',
                                    resize: 'vertical',
                                    boxSizing: 'border-box',
                                  }}
                                />
                              </div>

                              <div style={{ flex: '0 0 auto', paddingTop: '1.4rem' }}>
                                <button
                                  type="submit"
                                  disabled={form.submitting}
                                  style={{
                                    background: '#27ae60',
                                    color: '#fff',
                                    border: 'none',
                                    padding: '0.5rem 1.1rem',
                                    borderRadius: '4px',
                                    cursor: form.submitting ? 'not-allowed' : 'pointer',
                                    fontSize: '0.9rem',
                                    opacity: form.submitting ? 0.7 : 1,
                                  }}
                                >
                                  {form.submitting ? 'Processing…' : 'Submit Refund'}
                                </button>
                              </div>
                            </div>

                            {form.error && (
                              <div style={{ color: '#e74c3c', fontSize: '0.85rem', marginTop: '0.5rem' }}>
                                {form.error}
                              </div>
                            )}
                          </form>
                        </td>
                      </tr>
                    )}
                  </>
                )
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
