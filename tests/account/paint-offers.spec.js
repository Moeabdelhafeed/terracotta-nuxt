// @vitest-environment nuxt
import { describe, it, expect } from 'vitest'
import { sortOffers, pieceStatusLabel } from '~/composables/useMyPieces'
import { displayMoney, localeDigits } from '~/composables/useMoney'

/** `t(key, en, ar)` — the English default is what these assert against. */
const t = (_key, en) => en

const offer = (id, price) => ({ workshop: { id }, price })

describe('paint offers — what a piece costs to bring back', () => {
  /**
   * The studio runs several paint workshops and they do not agree: 60.00, 0.00, 99.99
   * are all live. `"0.00"` is what an untouched CMS field holds, so it means "no rate
   * set" — sorting it numerically put it first and printed "from 0 SAR" against a
   * session that charges.
   */
  it('puts the workshops that quote a rate first, cheapest of those first', () => {
    const sorted = sortOffers([offer(1, '99.99'), offer(2, '0.00'), offer(3, '60.00')])

    expect(sorted.map((o) => o.workshop.id)).toEqual([3, 1, 2])
  })

  it('keeps every unset rate at the end rather than collapsing them', () => {
    const sorted = sortOffers([offer(1, '0.00'), offer(2, '60.00'), offer(3, '0.00')])

    expect(sorted.map((o) => o.workshop.id)).toEqual([2, 1, 3])
  })

  it('compares in halalas, so a longer string is not read as a bigger number', () => {
    const sorted = sortOffers([offer(1, '9.99'), offer(2, '100.00')])

    expect(sorted.map((o) => o.workshop.id)).toEqual([1, 2])
  })
})

describe('piece status badges', () => {
  it.each([
    ['ready_to_paint', 'Ready to paint'],
    ['awaiting_painting', 'Booked to paint'],
    ['painted', 'Painted'],
    ['not_paintable', 'Not ready yet'],
  ])('words %s as "%s"', (status, expected) => {
    expect(pieceStatusLabel(status, t)).toBe(expected)
  })

  /**
   * A piece no workshop lists keeps `status: unknown`, and a wrong badge on somebody's
   * own work is worse than none — so an unrecognised status draws nothing at all rather
   * than printing the raw wire key.
   */
  it.each(['unknown', undefined, null, 'something_new'])('draws nothing for %s', (status) => {
    expect(pieceStatusLabel(status, t)).toBe('')
  })
})

describe('money on the page', () => {
  it('prints the digits it was given, never a float', () => {
    expect(displayMoney('60.00')).toBe('60')
    expect(displayMoney('99.99')).toBe('99.99')
    expect(displayMoney('0.00')).toBe('0')
    expect(displayMoney('1234.50')).toBe('1234.50')
  })

  it('renders Arabic-Indic digits in Arabic and leaves English alone', () => {
    expect(localeDigits('99.99', 'ar')).toBe('٩٩.٩٩')
    expect(localeDigits(4, 'ar')).toBe('٤')
    expect(localeDigits(4, 'en')).toBe('4')
  })
})
