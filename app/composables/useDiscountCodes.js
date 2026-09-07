/**
 * The codes the studio advertises: `GET /api/discount-codes` returns only the ones that
 * are active, public, inside their window, and still have room for THIS customer.
 *
 * An empty list means "nothing to advertise", not "no coupons exist" — private codes are
 * never listed and are typed in by hand — so the manual input always stays. `min_order_total`
 * is not filtered against the basket either, so a listed code may still be out of reach;
 * that is what `requirementFor` is for.
 */
export const useDiscountCodes = () => {
  const { isRegistered } = useIsRegistered()

  const { data, pending, error, refresh } = useApiFetch('/api/discount-codes', {
    key: 'discount-codes',
    transform: (res) => unwrapList(res?.data).items,
    default: () => [],
    // Guests have no per-user usage history for the API to filter against, and the route
    // is authenticated — asking would only collect a 401.
    immediate: isRegistered.value,
    watch: [isRegistered],
  })

  return {
    codes: computed(() => data.value ?? []),
    hasCodes: computed(() => (data.value ?? []).length > 0),
    pending,
    error,
    refresh,
  }
}

/** The human line under an advertised code: what it gives, and what it asks for first. */
export const discountCodeSummary = (code, t, format) => {
  const value = code?.type === 'percent'
    ? t('discount_percent_off', ':value% off', 'خصم :value%', { value: String(code.value ?? '').replace(/\.00$/, '') })
    : t('discount_amount_off', ':value off', 'خصم :value', { value: format(code?.value) })

  if (!code?.min_order_total || Number(code.min_order_total) <= 0) return value

  return `${value} · ${t('discount_min_total', 'on orders over :amount', 'للطلبات فوق :amount', { amount: format(code.min_order_total) })}`
}
