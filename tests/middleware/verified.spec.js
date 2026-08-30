// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, sanctumState } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  sanctumState: { user: { value: null } },
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useSanctumAuth', () => () => sanctumState)

const middleware = (await import('~/middleware/verified')).default

beforeEach(() => {
  navigateTo.mockReset()
  sanctumState.user.value = null
})

describe('verified', () => {
  it('anon → pass', () => {
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('guest (no verified_at) → pass (guest skipped)', () => {
    sanctumState.user.value = { data: { is_guest: true } }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('registered + verified → pass', () => {
    sanctumState.user.value = { data: { is_guest: false, verified_at: '2024-01-01' } }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('registered + unverified → redirect /verify', () => {
    sanctumState.user.value = { data: { is_guest: false, verified_at: null } }
    middleware()
    expect(navigateTo).toHaveBeenCalledWith({ name: 'verify' })
  })
})
