/**
 * AES-256-GCM token encryption helpers for Cloudflare Workers runtime.
 *
 * Uses the globally available `crypto.subtle` Web Crypto API — no Node.js
 * `crypto` module, no external npm packages.
 *
 * Storage format: `base64(iv):base64(ciphertext)`
 * The 12-byte IV is randomly generated per encryption and prepended so it can
 * be recovered at decryption time.
 *
 * Key derivation: the raw `CALENDAR_TOKEN_KEY` Workers Secret string is
 * imported as a 256-bit AES-GCM key (padded / truncated to 32 bytes).
 */

/**
 * Encrypts a plaintext token using AES-256-GCM.
 *
 * @param plaintext - The token string to encrypt (e.g. Google access token)
 * @param key - Raw `CALENDAR_TOKEN_KEY` Workers Secret string
 * @returns Encrypted value as `base64(iv):base64(ciphertext)`
 */
export async function encryptToken(plaintext: string, key: string): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(12))

  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(key.padEnd(32, '\0').slice(0, 32)), // 256-bit key
    { name: 'AES-GCM' },
    false,
    ['encrypt'],
  )

  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    keyMaterial,
    new TextEncoder().encode(plaintext),
  )

  const ivBase64 = btoa(String.fromCharCode(...iv))
  const ciphertextBase64 = btoa(String.fromCharCode(...new Uint8Array(encrypted)))

  return `${ivBase64}:${ciphertextBase64}`
}

/**
 * Decrypts a token encrypted by `encryptToken`.
 *
 * @param ciphertext - Encrypted value in `base64(iv):base64(ciphertext)` format
 * @param key - Raw `CALENDAR_TOKEN_KEY` Workers Secret string (must match the one used to encrypt)
 * @returns The original plaintext token string
 */
export async function decryptToken(ciphertext: string, key: string): Promise<string> {
  const separatorIndex = ciphertext.indexOf(':')
  if (separatorIndex === -1) {
    throw new Error('Invalid ciphertext format — expected base64(iv):base64(ciphertext)')
  }

  const ivBase64 = ciphertext.slice(0, separatorIndex)
  const dataBase64 = ciphertext.slice(separatorIndex + 1)

  const iv = Uint8Array.from(atob(ivBase64), (c) => c.charCodeAt(0))
  const data = Uint8Array.from(atob(dataBase64), (c) => c.charCodeAt(0))

  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(key.padEnd(32, '\0').slice(0, 32)), // 256-bit key
    { name: 'AES-GCM' },
    false,
    ['decrypt'],
  )

  const decrypted = await crypto.subtle.decrypt({ name: 'AES-GCM', iv }, keyMaterial, data)

  return new TextDecoder().decode(decrypted)
}
