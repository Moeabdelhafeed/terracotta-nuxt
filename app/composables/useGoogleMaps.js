/**
 * Loads the Google Maps JavaScript API once, for every map on the site.
 *
 * Google Maps replaced the OpenStreetMap embed so the customer and the studio see the same
 * map, pin and address (QA GEN-01) — the CMS draws its delivery maps from the same API. The
 * key is `runtimeConfig.public.googleMapsKey`; without one, or if the script is blocked,
 * `load()` rejects and the caller falls back to the typed coordinates.
 */
let loading = null

/*
 * The key is restricted by HTTP referrer (terracotta-ksa.com and the CMS hosts). Anywhere
 * else — www., localhost — Google still loads the script, then paints its own grey "can't
 * load Google Maps" box without rejecting anything. `gm_authFailure` is how it says so, and
 * the picker listens to fall back to the typed coordinates.
 */
let authFailed = false
const authListeners = new Set()

export const useGoogleMaps = () => {
  const key = useRuntimeConfig().public.googleMapsKey || ''

  const load = (language = 'ar') => {
    if (!import.meta.client) return Promise.reject(new Error('Google Maps needs a browser.'))
    if (window.google?.maps?.Map) return Promise.resolve(window.google.maps)
    if (!key) return Promise.reject(new Error('No Google Maps key is configured.'))

    loading ??= new Promise((resolve, reject) => {
      window.__terracottaMapsReady = () => resolve(window.google.maps)
      window.gm_authFailure = () => {
        authFailed = true
        authListeners.forEach((callback) => callback())
      }

      const script = document.createElement('script')
      const params = new URLSearchParams({ key, v: 'weekly', callback: '__terracottaMapsReady', language, region: 'SA' })
      script.src = `https://maps.googleapis.com/maps/api/js?${params.toString()}`
      script.async = true
      script.onerror = () => {
        loading = null
        reject(new Error('Google Maps failed to load.'))
      }
      document.head.appendChild(script)
    })

    return loading
  }

  const onAuthFailure = (callback) => {
    if (authFailed) {
      callback()
      return () => {}
    }
    authListeners.add(callback)
    return () => authListeners.delete(callback)
  }

  return { available: !!key, load, onAuthFailure }
}
