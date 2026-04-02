import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, clearAuth } from '../lib/auth'

// ── Monitoring page ────────────────────────────────────────────────────────────
// Fetches GET /admin/v1/monitoring/metrics for a date range and displays
// business event time-series data as tables.
// Default date range: last 30 days.
// (Story 11.5, AC: 2, NFR-B1)

const API_BASE = import.meta.env.VITE_ADMIN_API_URL ?? 'http://localhost:8787'

interface MetricSeries {
  date: string    // 'YYYY-MM-DD'
  count: number
}

interface MetricsData {
  trialStarts: MetricSeries[]
  trialToSubscriptionConversions: MetricSeries[]
  subscriptionActivations: MetricSeries[]
  subscriptionCancellations: MetricSeries[]
  totalChargesFired: MetricSeries[]
  totalDisbursedToCharity: MetricSeries[]
  dateRange: { from: string; to: string }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10)
}

function defaultFrom(): string {
  const d = new Date()
  d.setDate(d.getDate() - 30)
  return formatDate(d)
}

function defaultTo(): string {
  return formatDate(new Date())
}

// ── Styles ─────────────────────────────────────────────────────────────────────

const tableStyle: React.CSSProperties = {
  width: '100%',
  borderCollapse: 'collapse',
  fontSize: '0.9rem',
  marginBottom: '1.5rem',
}

const tableHeaderCellStyle: React.CSSProperties = {
  background: '#34495e',
  color: '#ecf0f1',
  padding: '0.5rem 0.75rem',
  textAlign: 'left',
  fontWeight: 'bold',
}

function rowStyle(index: number): React.CSSProperties {
  return {
    background: index % 2 === 0 ? '#f9f9f9' : '#fff',
  }
}

const tableCellStyle: React.CSSProperties = {
  padding: '0.45rem 0.75rem',
  borderBottom: '1px solid #ecf0f1',
}

const sectionHeadingStyle: React.CSSProperties = {
  fontSize: '1rem',
  fontWeight: 'bold',
  color: '#2c3e50',
  marginTop: '1.5rem',
  marginBottom: '0.5rem',
}

// ── MetricTable component ──────────────────────────────────────────────────────

function MetricTable({ title, data, formatCount }: { title: string; data: MetricSeries[]; formatCount?: (count: number) => string }) {
  const format = formatCount ?? ((n: number) => String(n))
  return (
    <div>
      <div style={sectionHeadingStyle}>{title}</div>
      {data.length === 0 ? (
        <p style={{ color: '#7f8c8d', fontSize: '0.9rem' }}>No data for this period.</p>
      ) : (
        <table style={tableStyle}>
          <thead>
            <tr>
              <th style={tableHeaderCellStyle}>Date</th>
              <th style={tableHeaderCellStyle}>Count</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr key={row.date} style={rowStyle(i)}>
                <td style={tableCellStyle}>{row.date}</td>
                <td style={tableCellStyle}>{format(row.count)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}

// ── Main component ─────────────────────────────────────────────────────────────

export default function MonitoringPage() {
  const navigate = useNavigate()
  const [from, setFrom] = useState<string>(defaultFrom())
  const [to, setTo] = useState<string>(defaultTo())
  const [metrics, setMetrics] = useState<MetricsData | null>(null)
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    void fetchMetrics(from, to)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [from, to])

  async function fetchMetrics(fromDate: string, toDate: string) {
    setLoading(true)
    setError(null)

    const token = getToken()
    try {
      const res = await fetch(
        `${API_BASE}/admin/v1/monitoring/metrics?from=${encodeURIComponent(fromDate)}&to=${encodeURIComponent(toDate)}`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      )

      if (res.status === 401) {
        setLoading(false)
        clearAuth()
        navigate('/login')
        return
      }

      if (!res.ok) {
        const body = await res.json().catch(() => null) as { error?: { message?: string } } | null
        setError(body?.error?.message ?? `Failed to load metrics (status ${res.status})`)
        setLoading(false)
        return
      }

      const body = await res.json() as { data: MetricsData }
      setMetrics(body.data)
      setLoading(false)
    } catch {
      setError('Failed to load metrics. Please try again.')
      setLoading(false)
    }
  }

  return (
    <div style={{ fontFamily: 'Arial, Helvetica, sans-serif', color: '#2c3e50' }}>
      <h2 style={{ marginTop: 0, marginBottom: '1.25rem', fontSize: '1.4rem' }}>
        Business Event Monitoring
      </h2>

      {/* Date range controls */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1.5rem' }}>
        <label style={{ fontSize: '0.9rem', fontWeight: 'bold' }}>
          From:
          <input
            type="date"
            value={from}
            onChange={(e) => setFrom(e.target.value)}
            style={{ marginLeft: '0.5rem', fontSize: '0.9rem', padding: '0.25rem 0.5rem', borderRadius: '4px', border: '1px solid #bdc3c7' }}
          />
        </label>
        <label style={{ fontSize: '0.9rem', fontWeight: 'bold' }}>
          To:
          <input
            type="date"
            value={to}
            onChange={(e) => setTo(e.target.value)}
            style={{ marginLeft: '0.5rem', fontSize: '0.9rem', padding: '0.25rem 0.5rem', borderRadius: '4px', border: '1px solid #bdc3c7' }}
          />
        </label>
      </div>

      {/* Loading state */}
      {loading && (
        <p style={{ color: '#7f8c8d' }}>Loading metrics...</p>
      )}

      {/* Error state */}
      {!loading && error && (
        <p style={{ color: '#e74c3c', fontWeight: 'bold' }}>{error}</p>
      )}

      {/* Metrics display */}
      {!loading && !error && metrics && (
        <div>
          <MetricTable title="Trial Starts" data={metrics.trialStarts} />
          <MetricTable title="Trial-to-Subscription Conversions" data={metrics.trialToSubscriptionConversions} />
          <MetricTable title="Subscription Activations" data={metrics.subscriptionActivations} />
          <MetricTable title="Subscription Cancellations" data={metrics.subscriptionCancellations} />
          <MetricTable title="Total Charges Fired" data={metrics.totalChargesFired} />
          <MetricTable
            title="Total Disbursed to Charity"
            data={metrics.totalDisbursedToCharity}
            formatCount={(cents) => `$${(cents / 100).toFixed(2)}`}
          />
        </div>
      )}
    </div>
  )
}
