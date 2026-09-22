/**
 * The colour a workshop is drawn in.
 *
 * The studio sets one per workshop in the CMS — per workshop, not per type, since two
 * `make_your_piece` sessions can come back different. Without one the family has its own,
 * which is the app's fallback. White type sits on all of them, by the studio's own call.
 */
const FAMILY_COLOURS = {
  make_your_piece: '#3A7F6A',
  paint_your_piece: '#A85724',
  make_your_candle: '#AE9353',
}

export const workshopColour = (workshop) =>
  workshop?.color ?? FAMILY_COLOURS[workshop?.type] ?? 'var(--brand-terracotta)'

/**
 * The line drawing a workshop falls back to when the CMS has no photograph of it.
 *
 * Per FAMILY, not per workshop — two sessions of the same kind share one, which is how the
 * app draws them. The files are the app's own art, black line work meant to be recoloured
 * to the card's ink rather than shown as-is.
 */
const FAMILY_ART = {
  make_your_piece: { key: 'art_make_your_piece', path: '/make-your-cup-workshop-illustration.png' },
  paint_your_piece: { key: 'art_paint_your_piece', path: '/color-your-cup-workshop-illustration.png' },
  make_your_candle: { key: 'art_make_your_candle', path: '/make-your-wax-workshop-illustration.png' },
}

/** The `/public` file a family's drawing seeds itself from, and falls back to. */
export const workshopArt = (workshop) => FAMILY_ART[workshop?.type]?.path ?? null

/** Its key in dynamic storage (group `web`, sub-group `workshops`). */
export const workshopArtKey = (workshop) => FAMILY_ART[workshop?.type]?.key ?? null
