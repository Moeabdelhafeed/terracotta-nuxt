// @vitest-environment nuxt
import { describe, it, expect } from 'vitest'

const {
  catalogueBounds, bookingState, hasDeliveryStep, productsQuery, productsBody,
  formatSlotTime, formatBookingDate, dateRange, daysUntil, isCatalogueType,
  canChooseHandover, hoursUntil, pieceUnavailableReason,
} = await import('~/composables/useBookings')

describe('booking helpers', () => {
  it('catalogue bounds scale with the party size', () => {
    const workshop = { min_products_per_person: 1, max_products_per_person: 3 }
    expect(catalogueBounds(workshop, 1)).toEqual({ min: 1, max: 3 })
    expect(catalogueBounds(workshop, 2)).toEqual({ min: 2, max: 6 })
    expect(catalogueBounds({}, 2)).toEqual({ min: 2, max: Infinity })
  })

  it('reads the display state from status plus the delivery stage', () => {
    expect(bookingState({ status: 'confirmed' })).toBe('confirmed')
    expect(bookingState({ status: 'completed', pickup_deadline: '2026-07-11T00:00:00+00:00', delivery_status: null })).toBe('ready')
    expect(bookingState({ status: 'completed', delivery_status: 'on_the_way' })).toBe('on_the_way')
    expect(bookingState({ status: 'completed', delivery_status: 'completed' })).toBe('delivered')
    // A candle never gets a pickup deadline — it goes home the same day.
    expect(bookingState({ status: 'completed', pickup_deadline: null, delivery_status: null })).toBe('delivered')
  })

  it('offers the delivery step only after completion, and never without a deadline', () => {
    expect(hasDeliveryStep({ status: 'preparing', pickup_deadline: null })).toBe(false)
    expect(hasDeliveryStep({ status: 'completed', pickup_deadline: null, delivery_method: null })).toBe(false)
    expect(hasDeliveryStep({ status: 'completed', pickup_deadline: '2026-07-11T00:00:00+00:00' })).toBe(true)
  })

  it('serialises products as bracketed query keys and as a clean create body', () => {
    const lines = [
      { workshop_product_id: 5, quantity: 2, title: 'Mug', price: '15.00' },
      { workshop_booking_piece_id: 2, quantity: 1, title: 'My cup', price: '20.00' },
    ]
    expect(productsQuery(lines)).toEqual({
      'products[0][workshop_product_id]': 5,
      'products[0][quantity]': 2,
      'products[1][workshop_booking_piece_id]': 2,
      'products[1][quantity]': 1,
    })
    expect(productsBody(lines)).toEqual([
      { workshop_product_id: 5, quantity: 2 },
      { workshop_booking_piece_id: 2 },
    ])
  })

  it('reads studio wall-clock times back in 12 hours, never shifted by a zone', () => {
    expect(formatSlotTime('13:00', '15:00', 'en')).toBe('1:00 PM – 3:00 PM')
    // Latin digits in Arabic too — the app prints «2:30 م», not «٢:٣٠ م».
    expect(formatSlotTime('14:30', '15:30', 'ar')).toBe('2:30 م – 3:30 م')
    // A date string is a calendar date: the same labels whatever the viewer's timezone.
    expect(formatBookingDate('2026-07-04', 'en')).toBe('Saturday, July 4')
  })

  it('walks the calendar without leaving the studio day', () => {
    expect(dateRange('2026-07-04', 3)).toEqual(['2026-07-04', '2026-07-05', '2026-07-06'])
    expect(daysUntil('2026-07-07', '2026-07-04')).toBe(3)
    expect(daysUntil('2026-07-01', '2026-07-04')).toBe(-3)
  })

  it('knows which types pick from a catalogue', () => {
    expect(isCatalogueType('paint_your_piece')).toBe(true)
    expect(isCatalogueType('make_your_candle')).toBe(true)
    expect(isCatalogueType('make_your_piece')).toBe(false)
  })

  it('keeps the handover re-choosable until the piece is handed over', () => {
    const ready = { status: 'completed', pickup_deadline: '2099-07-11T00:00:00+00:00' }
    expect(canChooseHandover({ ...ready, delivery_method: null, delivery_status: null })).toBe(true)
    // Switching back to pickup credits the delivery fee, so it has to stay reachable.
    expect(canChooseHandover({ ...ready, delivery_method: 'delivery', delivery_status: 'getting_ready' })).toBe(true)
    expect(canChooseHandover({ ...ready, delivery_method: 'delivery', delivery_status: 'on_the_way' })).toBe(true)
    expect(canChooseHandover({ ...ready, delivery_method: 'pickup', delivery_status: 'awaiting_pickup' })).toBe(true)
    expect(canChooseHandover({ ...ready, delivery_method: 'pickup', delivery_status: 'completed' })).toBe(false)
    // A candle has no handover leg to choose from at all.
    expect(canChooseHandover({ status: 'completed', pickup_deadline: null, delivery_method: null })).toBe(false)
    expect(canChooseHandover({ status: 'preparing', pickup_deadline: null })).toBe(false)
  })

  it('floors the collection countdown at zero, and answers null without a deadline', () => {
    expect(hoursUntil(null)).toBe(null)
    expect(hoursUntil('2020-01-01T00:00:00+00:00')).toBe(0)
    expect(hoursUntil(new Date(Date.now() + 3 * 3600000 + 60000).toISOString())).toBe(3)
  })

  it('separates a piece booked in to be painted from one already painted', () => {
    expect(pieceUnavailableReason({ id: 1 })).toBe(null)
    expect(pieceUnavailableReason({ id: 1, is_available_to_paint: true })).toBe(null)
    expect(pieceUnavailableReason({ id: 1, is_available_to_paint: false, painting_session: { is_upcoming: true } })).toBe('booked')
    expect(pieceUnavailableReason({ id: 1, is_available_to_paint: false, painting_session: { is_upcoming: false } })).toBe('painted')
    expect(pieceUnavailableReason({ id: 1, is_available_to_paint: false, painting_session: null })).toBe('painted')
  })
})
