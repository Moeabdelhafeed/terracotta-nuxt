/**
 * Shop orders: the paginated history, one order, and cancelling it (`DELETE`, only while
 * `can_cancel`). An order is paid the moment it is placed, so cancelling credits the whole
 * `total_price` back to the wallet — goods, delivery and VAT — and reports it in
 * `refunded_amount`.
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

  const cancel = async () => {
    const res = await api(`/api/shop/orders/${toValue(id)}`, { method: 'DELETE' })
    data.value = res?.data ?? data.value
    return res
  }

  return { order: computed(() => data.value), pending, error, status, refresh, cancel }
}
