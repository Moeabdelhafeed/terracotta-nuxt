/**
 * «قطعي» — everything the customer has made at the studio, and what it would cost to
 * book one back in to be painted.
 *
 * Two calls answering two different questions, fired together:
 *
 *   GET /api/workshops/images   — WHAT EXISTS. Every photograph this customer has ever
 *                                 had uploaded, across every booking, newest first.
 *   GET /api/workshops/{id}     — WHAT IT COSTS, for each `paint_your_piece` workshop,
 *       → own_pieces              via its `own_pieces` block.
 *
 * `own_pieces` is a PICKER, never the collection: the server puts a piece in it only
 * while it can be booked today and drops it the moment it is painted, is out for
 * delivery, or was made at a workshop that does not qualify. Reading it as the shelf
 * told customers with a cupboard of cups that they had made nothing.
 *
 * So the photo route is the collection and `own_pieces` only decorates it. A failed
 * catalogue costs the prices; a failed photo list costs the page.
 */

/** A piece nobody will paint draws no badge at all — a wrong badge is worse than none. */
export const PIECE_STATUSES = ['ready_to_paint', 'awaiting_painting', 'painted', 'not_paintable']

export const pieceStatusLabel = (status, t) => ({
  ready_to_paint: t('piece_ready_to_paint', 'Ready to paint', 'جاهزة للتلوين'),
  awaiting_painting: t('piece_awaiting_painting', 'Booked to paint', 'محجوزة للتلوين'),
  painted: t('piece_painted', 'Painted', 'ملوّنة'),
  not_paintable: t('piece_not_paintable', 'Not ready yet', 'ليست جاهزة بعد'),
}[status] ?? '')

/**
 * Cheapest first, but `"0.00"` sorts LAST rather than first: it is what an untouched CMS
 * field holds, so it means "no rate set", not "free". Sorting it numerically printed
 * "Paint from 0 SAR" against a session that charges.
 */
export const sortOffers = (offers) => [...offers].sort((a, b) => {
  const az = isZeroMoney(a.price)
  const bz = isZeroMoney(b.price)
  if (az !== bz) return az ? 1 : -1
  return toHalalas(a.price) - toHalalas(b.price)
})

export const useMyPieces = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')
  const api = useApi()

  // The collection. The per-booking cap is 4 photos x people, so the whole list is small
  // enough to take unpaged — the app does not page it either.
  const photosQuery = useApiFetch('/api/workshops/images', {
    key: 'my-workshop-photos',
    watch: [lang, i18nLocale],
  })

  // The offers. One request for the catalogue, then every paint workshop's detail in
  // parallel — `own_pieces` only rides on the detail, never on the list.
  const offersQuery = useApiFetch('/api/workshops', {
    key: 'paint-workshops',
    watch: [lang, i18nLocale],
    transform: (res) => asList(res?.data?.data ?? res?.data)
      .filter((workshop) => workshop.type === 'paint_your_piece'),
    default: () => [],
  })

  const paintWorkshops = computed(() => asList(offersQuery.data.value))

  const { data: details } = useAsyncData(
    'paint-workshop-details',
    async () => {
      const ids = paintWorkshops.value.map((workshop) => workshop.id)
      if (!ids.length) return []
      const settled = await Promise.all(
        // One bad workshop must not cost the others their price.
        ids.map((id) => api(`/api/workshops/${id}`).catch(() => null)),
      )
      return settled.map((res) => res?.data).filter(Boolean)
    },
    { default: () => [], watch: [paintWorkshops] },
  )

  /** `{ workshop, price, entries: Map(pieceId → own_pieces entry) }`, one per workshop. */
  const offers = computed(() => asList(details.value)
    .map((workshop) => {
      const block = workshop.own_pieces
      const entries = new Map(asList(block?.pieces).map((piece) => [piece.id, piece]))
      return entries.size ? { workshop, price: block?.price ?? '0.00', entries } : null
    })
    .filter(Boolean))

  const photos = computed(() => {
    const payload = photosQuery.data.value?.data
    return asList(Array.isArray(payload) ? payload : payload?.data)
  })

  /**
   * Photographs into pieces. Four angles of one mug are one piece: rows sharing a
   * `workshop_booking_piece_id` group together. A row with none was never tagged — still
   * the customer's work, so it is shown as a piece of its own under a synthetic negative
   * id that no offer can ever match, which is right, because the server has nothing to
   * book. The server's order (newest first) is kept.
   */
  const pieces = computed(() => {
    const byPiece = new Map()

    for (const row of photos.value) {
      const id = row.workshop_booking_piece_id ?? -row.id
      const existing = byPiece.get(id)
      if (existing) {
        existing.images.push(row)
        continue
      }
      byPiece.set(id, {
        id,
        label: row.piece_label ?? null,
        madeOn: row.booking_date ?? null,
        workshopTitle: row.workshop_title ?? null,
        bookingId: row.workshop_booking_id ?? null,
        images: [row],
        status: 'unknown',
        canBook: false,
        offers: [],
      })
    }

    // The label and the photographs stay the history's — `own_pieces` carries fewer.
    for (const piece of byPiece.values()) {
      const matched = offers.value.filter((offer) => offer.entries.has(piece.id))
      if (!matched.length) continue

      const entry = matched[0].entries.get(piece.id)
      piece.status = entry.status ?? 'unknown'
      piece.canBook = entry.is_paintable ?? entry.is_available_to_paint ?? false
      piece.offers = piece.canBook
        ? sortOffers(matched.map(({ workshop, price }) => ({ workshop, price })))
        : []
    }

    return [...byPiece.values()]
  })

  const refresh = () => Promise.all([photosQuery.refresh(), offersQuery.refresh()])

  return {
    pieces,
    // Only the photo list can empty the page; the prices are decoration.
    pending: photosQuery.pending,
    error: photosQuery.error,
    refresh,
  }
}
