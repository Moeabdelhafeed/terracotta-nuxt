/**
 * Saudi National Address book: `GET/POST/PUT/DELETE /api/addresses`, delivery zones
 * (`GET /api/delivery-zones`) as the "city" list, and the short-address lookup
 * (`POST /api/addresses/lookup`).
 *
 * The server keeps exactly one default: the first saved address becomes default, saving
 * another with `is_default: true` demotes the old one, deleting the default promotes the
 * newest remaining. So every write is followed by a refetch rather than a local patch.
 */

/** Saudi bounding box the API enforces on `lat` (`api.address_outside_saudi_arabia`). */
export const SAUDI_BOUNDS = { minLat: 16.0, maxLat: 32.5, minLng: 34.0, maxLng: 52.0 }

export const isWithinSaudi = (lat, lng) => {
  const la = Number(lat)
  const ln = Number(lng)
  return Number.isFinite(la) && Number.isFinite(ln)
    && la >= SAUDI_BOUNDS.minLat && la <= SAUDI_BOUNDS.maxLat
    && ln >= SAUDI_BOUNDS.minLng && ln <= SAUDI_BOUNDS.maxLng
}

export const ADDRESS_RULES = {
  building_number: /^\d{4}$/,
  postal_code: /^\d{5}$/,
  additional_number: /^\d{4}$/,
  short_address: /^[A-Za-z]{4}\d{4}$/,
}

/**
 * Mirrors the server's rules for instant feedback; the server's own field errors still win.
 * Returns `{ field: [message] }` in the same shape as `errors` so one renderer serves both.
 */
export const validateAddress = (form, t) => {
  const errors = {}
  const req = (field, message) => { if (!String(form[field] ?? '').trim()) errors[field] = [message] }

  req('building_number', t('address_building_required', 'Building number is required.', 'رقم المبنى مطلوب.'))
  req('street', t('address_street_required', 'Street is required.', 'اسم الشارع مطلوب.'))
  req('district', t('address_district_required', 'District is required.', 'الحي مطلوب.'))
  req('postal_code', t('address_postal_required', 'Postal code is required.', 'الرمز البريدي مطلوب.'))
  req('additional_number', t('address_additional_required', 'Additional number is required.', 'الرقم الإضافي مطلوب.'))
  req('phone', t('address_phone_required', 'Phone is required.', 'رقم الهاتف مطلوب.'))

  if (form.building_number && !ADDRESS_RULES.building_number.test(form.building_number)) {
    errors.building_number = [t('address_building_format', 'Building number must be exactly 4 digits.', 'رقم المبنى يجب أن يكون 4 أرقام.')]
  }
  if (form.postal_code && !ADDRESS_RULES.postal_code.test(form.postal_code)) {
    errors.postal_code = [t('address_postal_format', 'Postal code must be exactly 5 digits.', 'الرمز البريدي يجب أن يكون 5 أرقام.')]
  }
  if (form.additional_number && !ADDRESS_RULES.additional_number.test(form.additional_number)) {
    errors.additional_number = [t('address_additional_format', 'Additional number must be exactly 4 digits.', 'الرقم الإضافي يجب أن يكون 4 أرقام.')]
  }
  if (form.short_address && !ADDRESS_RULES.short_address.test(form.short_address)) {
    errors.short_address = [t('address_short_format', 'Short address looks like RRRD2929 — 4 letters then 4 digits.', 'العنوان المختصر بصيغة RRRD2929 — 4 أحرف ثم 4 أرقام.')]
  }
  if (form.lat === '' || form.lat === null || form.lng === '' || form.lng === null) {
    errors.lat = [t('address_pin_required', 'Drop the pin on your location.', 'حدّد موقعك على الخريطة.')]
  } else if (!isWithinSaudi(form.lat, form.lng)) {
    errors.lat = [t('address_outside_saudi', 'This address must be inside Saudi Arabia.', 'يجب أن يكون العنوان داخل المملكة العربية السعودية.')]
  }
  return errors
}

export const emptyAddressForm = () => ({
  label: '',
  building_number: '',
  street: '',
  district: '',
  postal_code: '',
  additional_number: '',
  unit_number: '',
  short_address: '',
  lat: '',
  lng: '',
  delivery_zone_id: null,
  phone: '',
  notes: '',
  is_default: false,
})

export const useDeliveryZones = () => {
  const lang = useCookie('lang')
  const i18nLocale = useCookie('i18n_locale')

  const { data, pending, error, refresh } = useApiFetch('/api/delivery-zones', {
    key: 'delivery-zones',
    transform: (res) => res?.data ?? { zones: [], default_fee: null, free_delivery_over: null },
    default: () => ({ zones: [], default_fee: null, free_delivery_over: null }),
    watch: [lang, i18nLocale],
  })

  return {
    zones: computed(() => data.value?.zones ?? []),
    defaultFee: computed(() => data.value?.default_fee ?? null),
    freeDeliveryOver: computed(() => data.value?.free_delivery_over ?? null),
    zoneById: (id) => (data.value?.zones ?? []).find((zone) => zone.id === Number(id)) ?? null,
    pending,
    error,
    refresh,
  }
}

export const useAddresses = () => {
  const api = useApi()
  const { user } = useSanctumAuth()
  const isRegistered = computed(() => !!user.value && !(user.value?.data?.is_guest ?? user.value?.is_guest))

  const { data, pending, error, refresh } = useApiFetch('/api/addresses', {
    key: 'addresses',
    transform: (res) => unwrapList(res?.data).items,
    default: () => [],
    // A guest has no address book and would only collect a 401.
    immediate: isRegistered.value,
    watch: [isRegistered],
  })

  const addresses = computed(() => data.value ?? [])
  const defaultAddress = computed(() => addresses.value.find((address) => address.is_default) ?? addresses.value[0] ?? null)

  const save = async (form, id = null) => {
    const body = { ...form }
    if (body.short_address) body.short_address = body.short_address.toUpperCase()
    if (!body.delivery_zone_id) delete body.delivery_zone_id
    const res = id
      ? await api(`/api/addresses/${id}`, { method: 'PUT', body })
      : await api('/api/addresses', { method: 'POST', body })
    await refresh()
    return res?.data ?? null
  }

  const remove = async (id) => {
    await api(`/api/addresses/${id}`, { method: 'DELETE' })
    await refresh()
  }

  /**
   * `POST /api/addresses/lookup`. Resolves the prefill, or throws the normalized error;
   * a 503 means the feature is switched off server-side — `unavailable: true` on the error.
   */
  const lookup = async (shortAddress) => {
    try {
      const res = await api('/api/addresses/lookup', { method: 'POST', body: { short_address: shortAddress } })
      return res?.data ?? null
    } catch (err) {
      const normalized = normalizeApiError(err)
      normalized.unavailable = normalized.status === 503
      throw normalized
    }
  }

  return { addresses, defaultAddress, pending, error, refresh, save, remove, lookup }
}
