/**
 * Shop orders: the paginated history, one order, and the two things a customer can do
 * to it — pay the hold (`POST …/pay`, idempotent) and cancel (`DELETE`, only while
 * `can_cancel`). Cancelling a **paid** order credits the whole `total_price` back to the
 * wallet — goods, delivery and VAT — and reports it in `refunded_amount`. Cancelling an
 * unpaid hold returns only the `wallet_applied` slice that was actually taken and leaves
 * `refunded_amount` null, because nothing was ever charged.
 */
export const ORDER_STEPS = ['pending', 'preparing', 'out_for_delivery', 'completed']

export const useOrders = ({ page = ref(1), perPage = 10 } = {}) =>
  useApiList('/api/shop/orders', { key: 'orders', query: { page, per_page: perPage } })

export const useOrder = (id) => {
  const localeKeys = [useCookie('lang'), useCookie('i18n_locale')]
  const { data, pending, error, status, refresh } = useApiFetch(() => `/api/shop/orders/${toValue(id)}`, {
    key: () => `order-${toValue(id)}`,
    lazy: import.meta.client,
    transform: (res) => res?.data ?? null,
    default: () => null,
    watch: [() => toValue(id), ...localeKeys],
  })

  const api = useApi()

  const pay = async () => {
    const res = await api(`/api/shop/orders/${toValue(id)}/pay`, { method: 'POST' })
    data.value = res?.data ?? data.value
    return res
  }

  const cancel = async () => {
    const res = await api(`/api/shop/orders/${toValue(id)}`, { method: 'DELETE' })
    data.value = res?.data ?? data.value
    return res
  }

  return { order: computed(() => data.value), pending, error, status, refresh, pay, cancel }
}
