import { describe, expect, it } from 'vitest'
import { arabicPluralForm } from '../app/composables/useBookings.js'

/**
 * The website used to print "1 أيام" — a form Arabic does not have — and rounded a session
 * 30 hours away down to "1 day". The app's own ARB messages split six ways; these are the
 * boundaries the website now follows.
 */
describe('arabicPluralForm', () => {
  it('names the form CLDR gives each count', () => {
    expect(arabicPluralForm(1)).toBe('one')
    expect(arabicPluralForm(2)).toBe('two')
    expect(arabicPluralForm(3)).toBe('few')
    expect(arabicPluralForm(10)).toBe('few')
    expect(arabicPluralForm(11)).toBe('many')
    expect(arabicPluralForm(99)).toBe('many')
    expect(arabicPluralForm(100)).toBe('other')
    expect(arabicPluralForm(101)).toBe('other')
  })

  it('treats zero as its own thing rather than a singular', () => {
    expect(arabicPluralForm(0)).toBe('other')
  })
})
