/**
 * Shared stubs for composable/component specs. Pure factories — `mockNuxtImport` is a
 * compile-time macro that must appear in the spec file itself, so wire them like this:
 *
 *   // @vitest-environment nuxt
 *   import { mockNuxtImport } from '@nuxt/test-utils/runtime'
 *   const api = await vi.hoisted(async () => {
 *     const { createApiMock, envelope, apiError } = await import('../helpers/mockApi')
 *     return createApiMock({
 *       'GET /api/addresses': envelope([{ id: 1, is_default: true }]),
 *       'POST /api/addresses': apiError(422, { lat: ['This address must be inside Saudi Arabia.'] }),
 *     })
 *   })
 *   mockNuxtImport('useApi', () => api.useApi)
 *   mockNuxtImport('useApiFetch', () => api.useApiFetch)
 *
 * A table entry can be a value (becomes the envelope `data`), a full envelope
 * `{ success, message, data }`, a function `(opts) => …`, or `apiError(...)` /
 * `bareError(...)` to reject the way ofetch does (`err.status`, `err.data`).
 * Keys accept `{id}` templates: `'DELETE /api/addresses/{id}'`.
 */
import { vi } from 'vitest'
import { ref, computed, isRef, unref } from 'vue'

export const envelope = (data, message = 'ok') => ({ success: true, message, errors: null, data })

export const apiError = (status, errors = {}, message = 'The given data was invalid.') => ({
  error: { status, body: { success: false, message, errors, data: null } },
})

/** Laravel's bare validation shape (no `success`/`data`) — what `/pay` and `validate()` produce. */
export const bareError = (status, errors = {}, message = 'The given data was invalid.') => ({
  error: { status, body: { message, errors } },
})

const makeError = ({ status, body }) => {
  const err = new Error(body?.message ?? `HTTP ${status}`)
  err.status = status
  err.statusCode = status
  err.data = body
  err.response = { status, _data: body }
  return err
}

const resolveEntry = async (entry, opts) => {
  const value = typeof entry === 'function' ? await entry(opts) : entry
  if (value && typeof value === 'object' && 'error' in value) throw makeError(value.error)
  if (value && typeof value === 'object' && 'success' in value && 'data' in value) return value
  return envelope(value)
}

const unwrapQuery = (query) => {
  const source = unref(query)
  if (!source || typeof source !== 'object') return undefined
  return Object.fromEntries(Object.entries(source).map(([k, v]) => [k, isRef(v) ? v.value : v]))
}

export const createApiMock = (table = {}) => {
  const calls = []

  const find = (method, url) => {
    const path = url.split('?')[0]
    const key = `${method} ${path}`
    if (key in table) return table[key]
    const match = Object.keys(table).find((candidate) => {
      const [m, pattern] = candidate.split(' ')
      if (m !== method) return false
      const re = new RegExp('^' + pattern.replace(/\{[^}]+\}/g, '[^/]+') + '$')
      return re.test(path)
    })
    return match ? table[match] : undefined
  }

  const $fetch = vi.fn(async (url, opts = {}) => {
    const method = String(opts.method ?? 'GET').toUpperCase()
    calls.push({ method, url, body: opts.body, query: opts.query })
    const entry = find(method, url)
    if (entry === undefined) throw makeError({ status: 404, body: { message: `No mock for ${method} ${url}` } })
    return await resolveEntry(entry, opts)
  })

  const useApi = () => $fetch

  const useApiFetch = (url, options = {}) => {
    const resolvedUrl = typeof url === 'function' ? url() : url
    const data = ref(options.default ? options.default() : null)
    const pending = ref(false)
    const error = ref(null)
    const status = ref('idle')
    const refresh = async () => {
      pending.value = true
      status.value = 'pending'
      try {
        const res = await $fetch(resolvedUrl, { method: 'GET', query: unwrapQuery(options.query) })
        data.value = options.transform ? options.transform(res) : res
        error.value = null
        status.value = 'success'
      } catch (err) {
        error.value = err
        status.value = 'error'
      } finally {
        pending.value = false
      }
    }
    if (options.immediate !== false) refresh()
    return { data, pending, error, status, refresh, execute: refresh }
  }

  const useApiLazyFetch = (url, options = {}) => useApiFetch(url, { ...options, lazy: true })

  return { $fetch, calls, table, useApi, useApiFetch, useApiLazyFetch }
}

/** A Sanctum auth state for `mockNuxtImport('useSanctumAuth', () => () => state)`. */
export const createSanctumState = (user = { id: 1, name: 'Test', is_guest: false, wallet_balance: '100.00' }) => {
  const state = {
    user: ref(user ? { data: user } : null),
    login: vi.fn(),
    logout: vi.fn(),
    refreshIdentity: vi.fn(),
  }
  state.isAuthenticated = computed(() => !!state.user.value)
  return state
}

/** A `useLang()` stand-in whose `t` returns the English (or Arabic) default with `:param`s filled. */
export const createLang = (code = 'en') => {
  const t = (key, en, ar, params) => {
    let text
    if (typeof en === 'string') text = code === 'ar' && typeof ar === 'string' ? ar : en
    else if (en && typeof en === 'object') text = en[code] ?? en.en ?? key
    else text = key
    const vars = params ?? (ar && typeof ar === 'object' ? ar : {})
    Object.entries(vars).forEach(([k, v]) => { text = text.split(`:${k}`).join(String(v)) })
    return text
  }
  return { t, code: ref(code), dir: ref(code === 'ar' ? 'rtl' : 'ltr'), lang: ref({ code }) }
}
