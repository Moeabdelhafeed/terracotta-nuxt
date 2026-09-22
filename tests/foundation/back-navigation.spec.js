// @vitest-environment nuxt
import { describe, it, expect } from 'vitest'
import { shouldStepBack } from '~/composables/useBackNavigation'

const click = (over = {}) => ({ button: 0, ...over })

/**
 * A back arrow's declared route is where to go when there is nowhere to go BACK to.
 * These pages are reached from several places — /orders is linked from the profile and
 * from the shop, a workshop from the home page, the workshops list and «قطعي» — and
 * always following the declared route sent the customer who arrived from their profile
 * out into the catalogue instead of back to where they were.
 */
describe('the back arrow', () => {
  it('steps back to the page the customer actually came from', () => {
    expect(shouldStepBack('/profile', '/orders', click())).toBe(true)
  })

  it('follows the fallback when the page was opened cold', () => {
    expect(shouldStepBack(undefined, '/orders', click())).toBe(false)
    expect(shouldStepBack(null, '/orders', click())).toBe(false)
  })

  it('follows the fallback when the previous entry is another site', () => {
    expect(shouldStepBack('https://example.com/', '/orders', click())).toBe(false)
  })

  /** A `replace` can leave the current route sitting in the back slot. */
  it('does not step back onto the page it is already on', () => {
    expect(shouldStepBack('/orders', '/orders', click())).toBe(false)
  })

  it('tells a query-string apart from the bare path', () => {
    expect(shouldStepBack('/orders?page=2', '/orders', click())).toBe(true)
  })

  it.each([
    ['ctrl', { ctrlKey: true }],
    ['meta', { metaKey: true }],
    ['shift', { shiftKey: true }],
    ['alt', { altKey: true }],
    ['middle button', { button: 1 }],
  ])('leaves a %s click to the browser, so the fallback still opens in a tab', (_name, over) => {
    expect(shouldStepBack('/profile', '/orders', click(over))).toBe(false)
  })

  it('stays out of the way once something else has handled the click', () => {
    expect(shouldStepBack('/profile', '/orders', click({ defaultPrevented: true }))).toBe(false)
  })
})
