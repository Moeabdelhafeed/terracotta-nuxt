import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { openApp } from '../../app/utils/openApp.js'

/** The only signal a page gets that an app opened is losing the page to it. */
const setVisibility = (state) => {
  Object.defineProperty(document, 'visibilityState', { value: state, configurable: true })
  document.dispatchEvent(new Event('visibilitychange'))
}

describe('openApp', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
  })
  afterEach(() => vi.useRealTimers())

  it('sends the deep link, and answers true once the app takes the page', async () => {
    const go = vi.fn()
    const result = openApp('terracotta://gift/abc', { go })
    expect(go).toHaveBeenCalledWith('terracotta://gift/abc')

    setVisibility('hidden')
    await expect(result).resolves.toBe(true)
  })

  it('answers false when nothing happens — no app installed', async () => {
    const result = openApp('terracotta://gift/abc', { go: () => {} })
    vi.advanceTimersByTime(2500)
    await expect(result).resolves.toBe(false)
  })

  it('waits while an iOS dialog is up, then follows what she chose', async () => {
    // "Open in Terracotta?" → Open.
    const opened = openApp('terracotta://gift/abc', { go: () => {} })
    window.dispatchEvent(new Event('blur'))
    vi.advanceTimersByTime(5000) // well past `wait`: the dialog is still up
    setVisibility('hidden')
    await expect(opened).resolves.toBe(true)

    // → Cancel (or "address is invalid"): back on the page without having left it.
    setVisibility('visible')
    const cancelled = openApp('terracotta://gift/abc', { go: () => {} })
    window.dispatchEvent(new Event('blur'))
    vi.advanceTimersByTime(5000)
    window.dispatchEvent(new Event('focus'))
    vi.advanceTimersByTime(600)
    await expect(cancelled).resolves.toBe(false)
  })

  it('never holds the button for ever on a dialog left open', async () => {
    const result = openApp('terracotta://gift/abc', { go: () => {} })
    window.dispatchEvent(new Event('blur'))
    vi.advanceTimersByTime(15000)
    await expect(result).resolves.toBe(false)
  })
})
