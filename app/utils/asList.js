/**
 * A list from whatever the API actually sent.
 *
 * `?? []` only catches null and undefined. A failing Laravel, a gateway error page or a
 * CDN interstitial answers a list endpoint with an envelope whose `data` is an object or
 * a string, and the first `.find`/`.filter` on it throws inside a server render — a 500
 * on the cold visit that a client-side navigation then hides, because it never re-renders
 * on the server. Narrow at the boundary instead of trusting the shape.
 */
export const asList = (value) => (Array.isArray(value) ? value : [])
