/**
 * Gift credit: one fixed-amount package the buyer pays for and hands on as a link.
 * The recipient is a note, not an account — `share_url` is the whole delivery mechanism,
 * so it is always used verbatim and never rebuilt from the token.
 *
 * There is no `GET /api/gifts/{id}`: the buyer's view of a single gift comes out of
 * `GET /api/gifts`, which is why `list()` is what `/gifts/[id]` reads too.
 */
export const useGifts = () => {
  const api = useApi()

  /** `{ amount, is_active }` — public, so the page can say "gifting is off" before a login. */
  const {
    data: giftPackage,
    pending: packagePending,
    status: packageStatus,
    refresh: refreshPackage,
  } = useApiFetch('/api/gifts/package', {
    key: 'gift-package',
    transform: (res) => res?.data ?? null,
    default: () => null,
  })

  const packageAmount = computed(() => giftPackage.value?.amount ?? null)
  // Unknown until the call lands: `false` before then would flash the "gifting is off" state.
  const packageActive = computed(() => giftPackage.value?.is_active !== false)

  /** Buyer's own gifts, newest first. Paginated only when `per_page` is sent. */
  const list = (query = {}) => useApiList('/api/gifts', { key: 'gifts', query })

  const quote = (body) => api('/api/gifts/quote', { method: 'POST', body })
  const create = (body) => api('/api/gifts', { method: 'POST', body })
  const pay = (id) => api(`/api/gifts/${id}/pay`, { method: 'POST' })
  const redeem = (token) => api(`/api/gifts/${encodeURIComponent(token)}/redeem`, { method: 'POST' })

  return {
    package: giftPackage,
    packageAmount,
    packageActive,
    packagePending,
    packageStatus,
    refreshPackage,
    list,
    quote,
    create,
    pay,
    redeem,
  }
}

/**
 * The recipient asked to sign in from a gift link. Login lands on the home page (it has
 * no `redirect` support), so the intent is parked here and picked up the next time that
 * same link is opened with a session — one shot, matched on the token so a stale key can
 * never redeem a different gift.
 */
const PENDING_KEY = 'gift:pending'

export const rememberPendingGift = (token) => {
  if (!import.meta.client) return
  try { sessionStorage.setItem(PENDING_KEY, token) } catch { /* private mode */ }
}

export const takePendingGift = (token) => {
  if (!import.meta.client) return false
  try {
    const stored = sessionStorage.getItem(PENDING_KEY)
    if (stored !== token) return false
    sessionStorage.removeItem(PENDING_KEY)
    return true
  } catch {
    return false
  }
}
