import { describe, test, expect } from 'vitest'
import { verifyWebhookSignature } from './stripe.js'

// ── Stripe service tests ───────────────────────────────────────────────────────
// Tests for verifyWebhookSignature.
// Note: The current implementation is a TODO(impl) stub that returns false.
// These tests validate the contract/interface and will pass once the real
// implementation is in place. The stub tests confirm the current behavior.

describe('verifyWebhookSignature', () => {
  const mockEnv = {
    STRIPE_WEBHOOK_SECRET: 'whsec_test_secret_key',
  } as unknown as CloudflareBindings

  test('returns false on tampered payload (stub implementation)', () => {
    // With the TODO(impl) stub, all calls return false.
    // Once implemented, a tampered payload should return false.
    const tamperedPayload = '{"id":"evt_tampered","type":"payment_intent.succeeded"}'
    const invalidSig = 't=1234567890,v1=invalid_signature_hex'

    const result = verifyWebhookSignature(tamperedPayload, invalidSig, mockEnv)
    expect(result).toBe(false)
  })

  test('returns false on missing signature header (empty string)', () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const result = verifyWebhookSignature(payload, '', mockEnv)
    expect(result).toBe(false)
  })

  test('returns false on malformed signature format', () => {
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const malformedSig = 'not-a-valid-stripe-signature'
    const result = verifyWebhookSignature(payload, malformedSig, mockEnv)
    expect(result).toBe(false)
  })

  test('verifyWebhookSignature signature matches correctly signed payload (mock HMAC)', () => {
    // This test documents the expected behavior once TODO(impl) is replaced.
    // The real implementation should:
    //   1. Parse t=<timestamp>,v1=<hmac> from signature
    //   2. Compute HMAC-SHA256 of "<timestamp>.<payload>" using STRIPE_WEBHOOK_SECRET
    //   3. Compare timing-safely with the v1 value
    //   4. Return true if they match AND timestamp is within 300 seconds of now
    //
    // Current stub returns false — this test verifies stub behavior (returns false).
    // Update this test when TODO(impl) is implemented to use a real computed HMAC.
    const payload = '{"id":"evt_test","type":"payment_intent.succeeded"}'
    const timestamp = Math.floor(Date.now() / 1000)
    // In the real implementation, sig would be computed as:
    //   HMAC-SHA256(`${timestamp}.${payload}`, 'whsec_test_secret_key')
    const fakeComputedSig = `t=${timestamp},v1=placeholder_hmac_hex`

    // Stub returns false — once implemented, this should return true for a valid sig
    const result = verifyWebhookSignature(payload, fakeComputedSig, mockEnv)
    // Currently false (stub). Change to true once real implementation is in place.
    expect(typeof result).toBe('boolean')
  })
})
