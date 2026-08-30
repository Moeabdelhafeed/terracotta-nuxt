const browserTimezone = () => {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC'
  } catch {
    return 'UTC'
  }
}

/** Full IANA zone list for a timezone picker. Falls back to ['UTC'] on old runtimes. */
export const timezoneOptions = () => {
  try {
    return Intl.supportedValuesOf('timeZone')
  } catch {
    return ['UTC']
  }
}

/**
 * Viewer-side datetime formatting, mirroring the backend `HasUserTimezone` trait.
 * The DB stores UTC; the backend shifts user-entered datetimes to UTC on save using
 * the `X-Timezone` request header (injected by the API plugins from the same cookie
 * this composable owns). Here we convert those UTC values back to the viewer's zone
 * for display.
 *
 * The `timezone` cookie is shared by SSR (header) and client (display), so it holds a
 * concrete IANA zone, not 'auto' — 'auto' is only a transient input to `setTimezone`.
 * On the client an unset/'auto' cookie is materialized to the browser zone so SSR and
 * CSR agree (no hydration drift) and the header carries a real value.
 */
export const useDateFormat = () => {
  const timezone = useCookie('timezone', {
    default: () => 'auto',
    maxAge: 60 * 60 * 24 * 365,
    sameSite: 'lax',
  })
  const lang = useCookie('lang')

  if (import.meta.client && (!timezone.value || timezone.value === 'auto')) {
    timezone.value = browserTimezone()
  }

  const resolvedTimezone = () => {
    const tz = timezone.value
    if (!tz || tz === 'auto') return import.meta.client ? browserTimezone() : 'UTC'
    return tz
  }

  const setTimezone = (tz) => {
    timezone.value = !tz || tz === 'auto' ? browserTimezone() : tz
  }

  const locale = () => lang.value?.code || 'en'

  const formatDate = (value, opts = {}) => {
    if (!value) return ''
    const date = new Date(value)
    if (isNaN(date.getTime())) return ''
    return new Intl.DateTimeFormat(locale(), {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      timeZone: resolvedTimezone(),
      ...opts,
    }).format(date)
  }

  const formatDateOnly = (value) =>
    formatDate(value, { hour: undefined, minute: undefined })

  return { timezone, resolvedTimezone, setTimezone, formatDate, formatDateOnly }
}
