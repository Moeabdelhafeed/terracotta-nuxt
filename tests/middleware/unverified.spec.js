// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, sanctumState } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  sanctumState: { user: { value: null } },
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useSanctumAuth', () => () => sanctumState)

const middleware = (await import('~/middleware/unverified')).default

beforeEach(() => {
  navigateTo.mockReset()
  sanctumState.user.value = null
})

describe('unverified', () => {
  it('anon → pass', () => {
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('guest → pass (no verified_at)', () => {
    sanctumState.user.value = { data: { is_guest: true } }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('registered + unverified → pass', () => {
    sanctumState.user.value = { data: { is_guest: false, verified_at: null } }
    middleware()
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('registered + verified → redirect home', () => {
    sanctumState.user.value = { data: { is_guest: false, verified_at: '2024-01-01' } }
    middleware()
    expect(navigateTo).toHaveBeenCalledWith({ name: 'home' })
  })
})
