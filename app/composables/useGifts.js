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

  /**
   * Buyer's own gifts, newest first. Paginated only when `per_page` is sent.
   *
   * The key carries the page: the list screen asks for one page and the detail screen
   * asks for all of them, and a shared key would hand whichever mounted first — data and
   * refresh handler alike — to the other. That is how buying a gift from page two ended
   * on "gift not found".
   */
  const list = (query = {}) => useApiList('/api/gifts', {
    key: () => `gifts-${toValue(query.per_page) ?? 'all'}-${toValue(query.page) ?? 1}`,
    query,
  })

  /**
   * Both sides of the reader's gifting — `GET /api/gifts/history`. A `sent` row is the
   * buyer's own receipt, byte for byte what `GET /api/gifts` returns; a `received` row is
   * narrower (`amount`, `from`, `message`, `redeemed_at`) because the token, the share
   * link and what was paid belong to whoever bought it.
   *
   * `per_page` is left off on purpose: omitted, the server sends the whole list, which is
   * what lets the direction filter run on the client. `totals` covers the whole history
   * whatever is filtered, so both sides can be labelled before either is opened.
   */
  const history = () => {
    const { data, pending, error, refresh } = useApiFetch('/api/gifts/history', {
      key: 'gifts-history',
      transform: (res) => ({
        entries: unwrapList(res?.data?.gifts).items,
        totals: res?.data?.totals ?? null,
      }),
      default: () => ({ entries: [], totals: null }),
    })

    return {
      entries: computed(() => asList(data.value?.entries)),
      sentCount: computed(() => data.value?.totals?.sent_count ?? 0),
      receivedCount: computed(() => data.value?.totals?.received_count ?? 0),
      pending,
      error,
      refresh,
    }
  }

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
    history,
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
