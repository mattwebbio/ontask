import { describe, test, expect } from 'vitest'
import { verifyWebhookSignature } from './stripe.js'

// ── Stripe service tests ───────────────────────────────────────────────────────
// Tests for verifyWebhookSignature.
// Story 13.1: Real HMAC-SHA256 implementation using Web Crypto API.

describe('verifyWebhookSignature', () => {
  const mockEnv = {
    STRIPE_WEBHOOK_SECRET: 'whsec_test_secret_key',
  } as unknown as CloudflareBindings

  test('returns false for tampered payload (invalid HMAC)', async () => {
    const tamperedPayload = '{"id":"evt_tampered","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const invalidSig = `t=${timestamp},v1=invalid_signature_hex_that_wont_match`

    const result = await verifyWebhookSignature(tamperedPayload, invalidSig, mockEnv)
    expect(result).toBe(false)
  })

  test('returns false for missing signature header (empty string)', async () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const result = await verifyWebhookSignature(payload, '', mockEnv)
    expect(result).toBe(false)
  })

  test('returns false for malformed signature format', async () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const malformedSig = 'not-a-valid-stripe-signature'
    const result = await verifyWebhookSignature(payload, malformedSig, mockEnv)
    expect(result).toBe(false)
  })

  test('returns false when STRIPE_WEBHOOK_SECRET is not set', async () => {
    const emptyEnv = { STRIPE_WEBHOOK_SECRET: '' } as unknown as CloudflareBindings
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const sig = `t=${timestamp},v1=somehex`
    const result = await verifyWebhookSignature(payload, sig, emptyEnv)
    expect(result).toBe(false)
  })

  test('returns false for expired timestamp (more than 300 seconds old)', async () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const oldTimestamp = Math.floor(Date.now() / 1000) - 400 // 400 seconds ago = expired
    const sig = `t=${oldTimestamp},v1=somehex`
    const result = await verifyWebhookSignature(payload, sig, mockEnv)
    expect(result).toBe(false)
  })

  test('returns false for signature with no v1 component', async () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const sig = `t=${timestamp}` // no v1=... component
    const result = await verifyWebhookSignature(payload, sig, mockEnv)
    expect(result).toBe(false)
  })

  test('verifyWebhookSignature returns a Promise<boolean>', async () => {
    // Verify the function is async and returns a Promise<boolean>.
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const sig = `t=${timestamp},v1=placeholder`

    const result = verifyWebhookSignature(payload, sig, mockEnv)
    expect(result).toBeInstanceOf(Promise)
    const resolved = await result
    expect(typeof resolved).toBe('boolean')
  })

  test('returns true for correctly signed payload', async () => {
    // Compute a real HMAC-SHA256 signature using the Web Crypto API.
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    const secret = 'whsec_test_secret_key'
    const signedPayload = `${timestamp}.${payload}`

    const encoder = new TextEncoder()
    const key = await crypto.subtle.importKey(
      'raw',
      encoder.encode(secret),
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )
    const sigBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(signedPayload))
    const computedHex = Array.from(new Uint8Array(sigBuffer))
      .map((b) => b.toString(16).padStart(2, '0'))
      .join('')

    const sig = `t=${timestamp},v1=${computedHex}`
    const result = await verifyWebhookSignature(payload, sig, mockEnv)
    expect(result).toBe(true)
  })
})
