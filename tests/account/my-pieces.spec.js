// @vitest-environment nuxt
import { describe, it, expect } from 'vitest'

/**
 * A piece is not a photograph. Three angles of one mug share a
 * `workshop_booking_piece_id` and are ONE piece; a row that was never tagged is still the
 * customer's work and stands on its own, under a synthetic negative id that no server
 * piece list can ever match — so nothing can offer to book it.
 */
const group = (photos) => {
  const byPiece = new Map()
  for (const row of photos) {
    const id = row.workshop_booking_piece_id ?? -row.id
    const existing = byPiece.get(id)
    if (existing) {
      existing.images.push(row)
      continue
    }
    byPiece.set(id, {
      id,
      label: row.piece_label ?? null,
      workshop_title: row.workshop_title ?? null,
      images: [row],
    })
  }
  return [...byPiece.values()]
}

const photo = (id, over = {}) => ({ id, image_api: `https://x.test/${id}.webp`, ...over })

describe('my pieces — photographs into pieces', () => {
  it('folds every angle of one mug into a single piece', () => {
    const pieces = group([
      photo(1, { workshop_booking_piece_id: 7, piece_label: 'Mug' }),
      photo(2, { workshop_booking_piece_id: 7, piece_label: 'Mug' }),
      photo(3, { workshop_booking_piece_id: 7, piece_label: 'Mug' }),
    ])

    expect(pieces).toHaveLength(1)
    expect(pieces[0].label).toBe('Mug')
    expect(pieces[0].images).toHaveLength(3)
  })

  it('keeps two different pieces apart, newest first', () => {
    const pieces = group([
      photo(9, { workshop_booking_piece_id: 2, piece_label: 'Bowl' }),
      photo(8, { workshop_booking_piece_id: 1, piece_label: 'Cup' }),
    ])

    expect(pieces.map((p) => p.label)).toEqual(['Bowl', 'Cup'])
  })

  it('still shows an untagged photograph, under an id nothing can book', () => {
    const pieces = group([photo(5, { workshop_booking_piece_id: null })])

    expect(pieces).toHaveLength(1)
    expect(pieces[0].id).toBe(-5)
    expect(pieces[0].label).toBeNull()
  })

  it('never merges two untagged photographs into one piece', () => {
    const pieces = group([
      photo(5, { workshop_booking_piece_id: null }),
      photo(6, { workshop_booking_piece_id: null }),
    ])

    expect(pieces).toHaveLength(2)
    expect(pieces.map((p) => p.id)).toEqual([-5, -6])
  })
})
