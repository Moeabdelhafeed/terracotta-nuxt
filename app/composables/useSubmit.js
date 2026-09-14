/**
 * The API answers every call with the same envelope — `{ success, message, errors, data }` —
 * except that Laravel's own validation (and a few `/pay` refusals) come back bare:
 * `{ message, errors }` with no `success`/`data`, and a 429 carries only `{ success, message }`.
 * Everything below reads both shapes so a page never has to know which one it got.
 */

/** `{ message, errors, status, data }` from any thrown ofetch error, with `errors` always an object. */
export const normalizeApiError = (err) => {
  const body = err?.data ?? {}
  const errors = body.errors && typeof body.errors === 'object' ? body.errors : {}
  return {
    status: err?.status ?? err?.statusCode ?? err?.response?.status ?? 0,
    message: body.message ?? err?.message ?? '',
    errors,
    data: body.data ?? null,
    raw: err,
  }
}

/** First message for a field, or `''`. Accepts the raw `errors` map or a normalized error. */
export const fieldError = (errors, field) => {
  const map = errors?.errors ?? errors ?? {}
  const value = map[field]
  return Array.isArray(value) ? (value[0] ?? '') : (value ?? '')
}

/**
 * `data` for a list endpoint is either a plain array (`per_page` absent or `all`) or a
 * Laravel paginator (`{ data, current_page, last_page, total }`). One normaliser for both.
 */
export const unwrapList = (payload) => {
  const items = Array.isArray(payload) ? payload : (payload?.data ?? [])
  return {
    items,
    page: payload?.current_page ?? 1,
    lastPage: payload?.last_page ?? 1,
    total: payload?.total ?? items.length,
  }
}

/**
 * Imperative call wrapper. Resolves `{ data, message }` from the envelope, rejects with
 * the normalized `{ message, errors, status }` above.
 *
 *   const { submit, pending, errors, error } = useSubmit()
 *   const res = await submit(() => api('/api/shop/cart', { method: 'POST', body }))
 *
 * `errors`/`error` are reset on every call, so a form can bind straight to them.
 */
export const useSubmit = () => {
  const pending = ref(false)
  const errors = ref({})
  const error = ref('')
  const message = ref('')

  const submit = async (call) => {
    pending.value = true
    errors.value = {}
    error.value = ''
    message.value = ''
    try {
      const res = await call()
      message.value = res?.message ?? ''
      return { data: res?.data ?? res ?? null, message: message.value }
    } catch (err) {
      const normalized = normalizeApiError(err)
      errors.value = normalized.errors
      error.value = normalized.message
      throw normalized
    } finally {
      pending.value = false
    }
  }

  return { submit, pending, errors, error, message, fieldError: (field) => fieldError(errors.value, field) }
}

/**
 * SSR-friendly paginated list on top of `useApiFetch`. `query` may hold refs
 * (`page`, `per_page`, filters…); the list refetches as they change.
 *
 *   const { items, page, lastPage, total, pending, refresh } = useApiList('/api/shop/orders', { key: 'orders', query: { page, per_page: 10 } })
 */
export const useApiList = (url, { key, query = {}, watch: extraWatch = [], ...rest } = {}) => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh, status } = useApiFetch(url, {
    key,
    query,
    transform: (res) => ({ ...unwrapList(res?.data), meta: res?.meta ?? null }),
    default: () => ({ items: [], page: 1, lastPage: 1, total: 0, meta: null }),
    watch: [lang, i18nLocale, ...extraWatch],
    ...rest,
  })

  return {
    items: computed(() => data.value?.items ?? []),
    page: computed(() => data.value?.page ?? 1),
    lastPage: computed(() => data.value?.lastPage ?? 1),
    total: computed(() => data.value?.total ?? 0),
    // Facts about the whole result set that belong to no single row — the bookings list
    // puts its per-status counts here so tabs can be labelled before one is opened.
    meta: computed(() => data.value?.meta ?? null),
    pending,
    error,
    status,
    refresh,
  }
}
