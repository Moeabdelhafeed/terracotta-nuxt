// @vitest-environment nuxt
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mockNuxtImport } from '@nuxt/test-utils/runtime'

const { navigateTo, ask, sanctumState } = vi.hoisted(() => ({
  navigateTo: vi.fn(),
  ask: vi.fn(),
  sanctumState: { user: { value: null }, isAuthenticated: { value: false } },
}))

mockNuxtImport('navigateTo', () => navigateTo)
mockNuxtImport('useSanctumAuth', () => () => sanctumState)
mockNuxtImport('useLoginPrompt', () => () => ({ ask }))

const middleware = (await import('~/middleware/require-registered')).default
const to = { fullPath: '/wallet' }

beforeEach(() => {
  navigateTo.mockReset()
  ask.mockReset()
  sanctumState.user.value = null
  sanctumState.isAuthenticated.value = false
})

describe('require-registered', () => {
  // In the browser the reader is already on a page: asking there and cancelling the
  // navigation leaves them where they were, instead of replacing it with /login.
  it('anon → asks in place, navigation cancelled', () => {
    expect(middleware(to)).toBe(false)
    expect(ask).toHaveBeenCalledWith('/wallet')
    expect(navigateTo).not.toHaveBeenCalled()
  })

  it('guest → asks in place too', () => {
    sanctumState.user.value = { data: { is_guest: true } }
    sanctumState.isAuthenticated.value = true
    expect(middleware(to)).toBe(false)
    expect(ask).toHaveBeenCalledWith('/wallet')
  })

  it('registered → pass', () => {
    sanctumState.user.value = { data: { is_guest: false } }
    sanctumState.isAuthenticated.value = true
    middleware(to)
    expect(ask).not.toHaveBeenCalled()
    expect(navigateTo).not.toHaveBeenCalled()
  })
})
