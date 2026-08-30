const FIVE_YEARS = 60 * 60 * 24 * 365 * 5

const detectPlatform = (ua = '') => {
  if (/iPhone|iPad|iPod/i.test(ua)) return 'ios'
  if (/Android/i.test(ua)) return 'android'
  return 'web'
}

/**
 * Server-side, `useCookie` re-parses the incoming request header on every call, so a
 * value written by one caller is invisible to the next — on a first visit each
 * `useDevice()` would mint its own UUID and overwrite the previous one, and the API
 * calls in that same render would go out under different devices. Writing the value
 * back onto the request makes every later read in this render agree.
 */
const remember = (name, value) => {
  if (!import.meta.server) return
  const headers = useRequestEvent()?.node?.req?.headers
  if (!headers) return
  const entry = `${name}=${encodeURIComponent(value)}`
  headers.cookie = headers.cookie ? `${headers.cookie}; ${entry}` : entry
}

export const useDevice = () => {
  const deviceId = useCookie('device_id', { maxAge: FIVE_YEARS, sameSite: 'lax' })
  const platform = useCookie('device_platform', { maxAge: FIVE_YEARS, sameSite: 'lax' })
  const fcmToken = useCookie('fcm_token', { maxAge: FIVE_YEARS, sameSite: 'lax' })

  // Generated during SSR too, not client-only: Laravel's IdentifyDevice middleware
  // 422s any request missing X-Device-Id, so a first visit with no cookie would
  // fail every server-rendered fetch (config, pages, app-settings, translations).
  if (!deviceId.value) {
    deviceId.value = useState('device-id', () => crypto.randomUUID()).value
    remember('device_id', deviceId.value)
  }
  if (!platform.value) {
    platform.value = detectPlatform(
      import.meta.client
        ? navigator.userAgent
        : useRequestHeaders(['user-agent'])['user-agent'],
    )
    remember('device_platform', platform.value)
  }

  return { deviceId, platform, fcmToken }
}
