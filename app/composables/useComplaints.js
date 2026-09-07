/**
 * Complaints: `POST /api/complaints` works signed in or out (signed out needs `name` +
 * `contact`; signed in, the account is used and those two are ignored), and
 * `GET /api/complaints` lists the signed-in user's own, newest first. Customers can
 * neither edit nor delete one.
 */
export const COMPLAINT_TYPES = ['order', 'workshop', 'delivery', 'payment', 'other']
export const COMPLAINT_STATUSES = ['new', 'in_progress', 'resolved', 'closed']

export const complaintTypeLabel = (type, t) => ({
  order: t('complaint_type_order', 'Shop order', 'طلب من المتجر'),
  workshop: t('complaint_type_workshop', 'Workshop', 'ورشة'),
  delivery: t('complaint_type_delivery', 'Delivery', 'التوصيل'),
  payment: t('complaint_type_payment', 'Payment', 'الدفع'),
  other: t('complaint_type_other', 'Other', 'أخرى'),
}[type] ?? String(type ?? ''))

export const complaintStatusLabel = (status, t) => ({
  new: t('complaint_status_new', 'New', 'جديدة'),
  in_progress: t('complaint_status_in_progress', 'In progress', 'قيد المعالجة'),
  resolved: t('complaint_status_resolved', 'Resolved', 'تم الحل'),
  closed: t('complaint_status_closed', 'Closed', 'مغلقة'),
}[status] ?? String(status ?? ''))

export const useComplaints = () => {
  const api = useApi()
  const { user } = useSanctumAuth()
  const isRegistered = computed(() => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest))

  const { data, pending, error, refresh } = useApiFetch('/api/complaints', {
    key: 'complaints',
    transform: (res) => unwrapList(res?.data).items,
    default: () => [],
    // Signed out there is nothing to list — the endpoint would only 401.
    immediate: isRegistered.value,
    watch: [isRegistered],
  })

  const { submit, pending: submitting, errors, error: submitError, message } = useSubmit()

  const send = async (form) => {
    const body = { type: form.type, message: form.message }
    if (form.reference) body.reference = form.reference
    if (!isRegistered.value) {
      body.name = form.name
      body.contact = form.contact
    }
    const res = await submit(() => api('/api/complaints', { method: 'POST', body }))
    if (isRegistered.value) await refresh()
    return res
  }

  return {
    complaints: computed(() => data.value ?? []),
    pending,
    error,
    refresh,
    send,
    submitting,
    errors,
    submitError,
    message,
    isRegistered,
  }
}
