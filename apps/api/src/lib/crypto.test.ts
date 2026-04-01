import { describe, it, expect } from 'vitest'
import { encryptToken, decryptToken } from './crypto.js'

// ── AES-256-GCM token encryption helper tests ─────────────────────────────────
// These tests exercise the pure crypto functions using the Web Crypto API available
// in the Vitest environment.

const TEST_KEY = 'test-key-for-unit-testing-only!!'

describe('encryptToken / decryptToken', () => {
  it('encrypts and decrypts a token round-trip', async () => {
    const plaintext = 'ya29.google-access-token-example'

    const ciphertext = await encryptToken(plaintext, TEST_KEY)
    const decrypted = await decryptToken(ciphertext, TEST_KEY)

    expect(decrypted).toBe(plaintext)
  })

  it('produces a base64(iv):base64(ciphertext) format', async () => {
    const ciphertext = await encryptToken('some-token', TEST_KEY)

    // Must contain exactly one colon separator
    const parts = ciphertext.split(':')
    expect(parts).toHaveLength(2)

    // Both parts must be valid base64
    const [ivBase64, dataBase64] = parts
    expect(() => atob(ivBase64)).not.toThrow()
    expect(() => atob(dataBase64)).not.toThrow()
  })

  it('produces a different ciphertext each time (random IV)', async () => {
    const plaintext = 'same-token'

    const ciphertext1 = await encryptToken(plaintext, TEST_KEY)
    const ciphertext2 = await encryptToken(plaintext, TEST_KEY)

    // IVs are random — ciphertexts should differ
    expect(ciphertext1).not.toBe(ciphertext2)

    // But both should decrypt to the same value
    const decrypted1 = await decryptToken(ciphertext1, TEST_KEY)
    const decrypted2 = await decryptToken(ciphertext2, TEST_KEY)
    expect(decrypted1).toBe(plaintext)
    expect(decrypted2).toBe(plaintext)
  })

  it('encrypts and decrypts a long token (refresh token)', async () => {
    const longToken =
      '1//0g-long-refresh-token-example-that-is-quite-lengthy-and-contains-special-chars-like-_-and-/'

    const ciphertext = await encryptToken(longToken, TEST_KEY)
    const decrypted = await decryptToken(ciphertext, TEST_KEY)

    expect(decrypted).toBe(longToken)
  })

  it('handles key shorter than 32 bytes (pads with null bytes)', async () => {
    const shortKey = 'short'
    const plaintext = 'test-token'

    const ciphertext = await encryptToken(plaintext, shortKey)
    const decrypted = await decryptToken(ciphertext, shortKey)

    expect(decrypted).toBe(plaintext)
  })

  it('handles key longer than 32 bytes (truncates to 32)', async () => {
    const longKey = 'this-key-is-longer-than-32-bytes-so-it-will-be-truncated'
    const plaintext = 'test-token'

    const ciphertext = await encryptToken(plaintext, longKey)
    const decrypted = await decryptToken(ciphertext, longKey)

    expect(decrypted).toBe(plaintext)
  })

  it('decryptToken throws on invalid ciphertext format (no colon)', async () => {
    await expect(decryptToken('nocolarformat', TEST_KEY)).rejects.toThrow(
      'Invalid ciphertext format',
    )
  })

  it('decryptToken throws when decrypting with wrong key', async () => {
    const ciphertext = await encryptToken('token', TEST_KEY)

    await expect(decryptToken(ciphertext, 'wrong-key-xxxxxxxxxxxxxxxxxxxxxxxx')).rejects.toThrow()
  })
})
