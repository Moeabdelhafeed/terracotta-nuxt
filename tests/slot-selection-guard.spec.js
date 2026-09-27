import { describe, expect, it } from 'vitest'
import { slotStillBookable } from '../app/composables/useBookings.js'

/**
 * Raising the party size can make an already-chosen session too small for it. The slot
 * stays in the list when that happens — disabled, greyed, with its reason on it — so "is
 * it still listed" was never the right question, and a session picked for one person
 * survived being changed to four all the way into checkout.
 */
describe('slotStillBookable', () => {
  const slot = { workshop_slot_id: 7, remaining: 3, is_full: false, has_conflict: false }

  it('keeps a session that can still take the party', () => {
    expect(slotStillBookable(slot)).toBe(true)
  })

  it('drops one the party has outgrown', () => {
    // Same session, re-answered for a party of four.
    expect(slotStillBookable({ ...slot, is_full: true })).toBe(false)
  })

  it('drops one the customer has since double-booked', () => {
    expect(slotStillBookable({ ...slot, has_conflict: true })).toBe(false)
  })

  it('drops one that stopped being offered at all', () => {
    expect(slotStillBookable(undefined)).toBe(false)
  })

  it('keeps the booking being rescheduled, which reads as full against its own seats', () => {
    expect(slotStillBookable({ ...slot, is_full: true, has_conflict: true }, true)).toBe(true)
  })
})
