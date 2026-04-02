import { describe, expect, it, vi } from 'vitest'
import { createContract } from '../../src/tools/create-contract.js'
import { getCommitmentStatus } from '../../src/tools/get-commitment-status.js'

// ── MCP Tools Test Suite (Story 10.5) ─────────────────────────────────────────
//
// Tests cover: create_contract tool (all paths) and get_commitment_status
// (confirming userId third-param pattern from Story 10.4).
//
// Mock pattern: apiBinding.fetch is a vi.fn() that returns a fetch-compatible
// Response-like object. Tools are pure functions — no Cloudflare runtime needed.

const STUB_USER_ID = '00000000-0000-4000-a000-000000000001'
const STUB_TASK_ID = 'a0000000-0000-4000-8000-000000000001'
const STUB_CONTRACT_ID = 'c0000000-0000-4000-8000-000000000001'

const stubContract = {
  id: STUB_CONTRACT_ID,
  taskId: STUB_TASK_ID,
  stakeAmountCents: 2500,
  charityId: 'american-red-cross',
  deadline: '2026-05-01T00:00:00.000Z',
  status: 'active',
  createdAt: '2026-04-02T00:00:00.000Z',
}

function makeMockApiBinding(overrides: {
  ok?: boolean
  status?: number
  json?: () => Promise<unknown>
  text?: () => Promise<string>
} = {}) {
  const status = overrides.status ?? 200
  const ok = overrides.ok ?? (status >= 200 && status < 300)
  const response = {
    ok,
    status,
    json: overrides.json ?? (async () => ({ data: stubContract })),
    text: overrides.text ?? (async () => ''),
  }
  return {
    fetch: vi.fn().mockResolvedValue(response),
  }
}

const validInput = {
  taskId: STUB_TASK_ID,
  stakeAmountCents: 2500,
  charityId: 'american-red-cross',
  deadline: '2026-05-01T00:00:00.000Z',
}

describe('create_contract', () => {
  it('with all required fields returns MCP content format on success (201)', async () => {
    const mockApi = makeMockApiBinding({
      ok: true,
      status: 201,
      json: async () => ({ data: stubContract }),
    })

    const result = await createContract(validInput, mockApi, STUB_USER_ID)

    expect(result.isError).toBeUndefined()
    expect(result.content).toHaveLength(1)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data).toMatchObject({ id: STUB_CONTRACT_ID, taskId: STUB_TASK_ID, stakeAmountCents: 2500 })
  })

  it('with missing payment method returns NO_PAYMENT_METHOD error with setupUrl', async () => {
    const mockApi = makeMockApiBinding({
      ok: false,
      status: 422,
      json: async () => ({
        error: {
          code: 'NO_PAYMENT_METHOD',
          message: 'Payment method required. Visit the URL to set up.',
          setupUrl: 'https://ontaskhq.com/setup',
        },
      }),
    })

    const result = await createContract(validInput, mockApi, STUB_USER_ID)

    expect(result.isError).toBe(true)
    expect(result.content).toHaveLength(1)
    expect(result.content[0].type).toBe('text')
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('NO_PAYMENT_METHOD')
    // CRITICAL: setupUrl must be preserved in the MCP result
    expect(data.error.setupUrl).toBe('https://ontaskhq.com/setup')
  })

  it('with missing required fields returns MISSING_REQUIRED_FIELD error without calling API', async () => {
    const mockApi = makeMockApiBinding()

    // Missing taskId
    const result = await createContract(
      { taskId: '', stakeAmountCents: 2500, charityId: 'american-red-cross', deadline: '2026-05-01T00:00:00.000Z' },
      mockApi,
      STUB_USER_ID,
    )

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('MISSING_REQUIRED_FIELD')
    expect(mockApi.fetch).not.toHaveBeenCalled()
  })

  it('with negative stakeAmountCents returns MISSING_REQUIRED_FIELD without calling API', async () => {
    const mockApi = makeMockApiBinding()

    const result = await createContract(
      { taskId: STUB_TASK_ID, stakeAmountCents: -100, charityId: 'american-red-cross', deadline: '2026-05-01T00:00:00.000Z' },
      mockApi,
      STUB_USER_ID,
    )

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('MISSING_REQUIRED_FIELD')
    expect(mockApi.fetch).not.toHaveBeenCalled()
  })

  it('with zero stakeAmountCents returns MISSING_REQUIRED_FIELD without calling API', async () => {
    const mockApi = makeMockApiBinding()

    const result = await createContract(
      { taskId: STUB_TASK_ID, stakeAmountCents: 0, charityId: 'american-red-cross', deadline: '2026-05-01T00:00:00.000Z' },
      mockApi,
      STUB_USER_ID,
    )

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('MISSING_REQUIRED_FIELD')
    expect(mockApi.fetch).not.toHaveBeenCalled()
  })

  it('when API is unavailable returns UPSTREAM_ERROR', async () => {
    const unavailableApi = {
      fetch: vi.fn().mockRejectedValue(new Error('Service binding unavailable')),
    }

    const result = await createContract(validInput, unavailableApi, STUB_USER_ID)

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('UPSTREAM_ERROR')
  })

  it('when API returns unexpected non-2xx returns UPSTREAM_ERROR', async () => {
    const mockApi = makeMockApiBinding({
      ok: false,
      status: 500,
      text: async () => 'Internal Server Error',
      json: async () => { throw new Error('not json') },
    })

    const result = await createContract(validInput, mockApi, STUB_USER_ID)

    expect(result.isError).toBe(true)
    const data = JSON.parse(result.content[0].text)
    expect(data.error.code).toBe('UPSTREAM_ERROR')
  })

  it('calls POST /v1/contracts with correct body and x-user-id header', async () => {
    const mockApi = makeMockApiBinding({
      ok: true,
      status: 201,
      json: async () => ({ data: stubContract }),
    })

    await createContract(validInput, mockApi, STUB_USER_ID)

    expect(mockApi.fetch).toHaveBeenCalledWith(
      'https://ontask-api-internal/v1/contracts',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({ 'x-user-id': STUB_USER_ID }),
      }),
    )

    const callBody = JSON.parse(mockApi.fetch.mock.calls[0][1].body as string)
    expect(callBody.taskId).toBe(STUB_TASK_ID)
    expect(callBody.stakeAmountCents).toBe(2500)
    expect(callBody.charityId).toBe('american-red-cross')
    expect(callBody.deadline).toBe('2026-05-01T00:00:00.000Z')
  })
})

describe('get_commitment_status', () => {
  const STUB_CONTRACT_STATUS = {
    id: STUB_CONTRACT_ID,
    status: 'active' as const,
    stakeAmountCents: 2500,
    chargeTimestamp: null,
  }

  it('calls GET /v1/contracts/:id/status with correct userId header', async () => {
    const mockApi = makeMockApiBinding({
      ok: true,
      status: 200,
      json: async () => ({ data: STUB_CONTRACT_STATUS }),
    })

    await getCommitmentStatus({ id: STUB_CONTRACT_ID }, mockApi, STUB_USER_ID)

    expect(mockApi.fetch).toHaveBeenCalledWith(
      `https://ontask-api-internal/v1/contracts/${STUB_CONTRACT_ID}/status`,
      expect.objectContaining({
        method: 'GET',
        headers: expect.objectContaining({ 'x-user-id': STUB_USER_ID }),
      }),
    )
  })

  it('returns contract status data on success', async () => {
    const mockApi = makeMockApiBinding({
      ok: true,
      status: 200,
      json: async () => ({ data: STUB_CONTRACT_STATUS }),
    })

    const result = await getCommitmentStatus({ id: STUB_CONTRACT_ID }, mockApi, STUB_USER_ID)

    expect(result.id).toBe(STUB_CONTRACT_ID)
    expect(result.status).toBe('active')
    expect(result.stakeAmountCents).toBe(2500)
    expect(result.chargeTimestamp).toBeNull()
  })

  it('throws on non-2xx API response', async () => {
    const mockApi = makeMockApiBinding({
      ok: false,
      status: 404,
      text: async () => 'Not Found',
    })

    await expect(
      getCommitmentStatus({ id: STUB_CONTRACT_ID }, mockApi, STUB_USER_ID),
    ).rejects.toThrow(/get_commitment_status/)
  })
})
