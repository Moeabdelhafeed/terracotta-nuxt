<template>
  <form class="flex flex-col gap-4" @submit.prevent="onSubmit">
    <!-- Short-address lookup: prefills the form from the national address registry. -->
    <div v-if="lookupEnabled" class="rounded-2xl bg-brand-mist/40 p-4">
      <Label for="lookup_short_address">{{ t('address_short_lookup', 'Have a short address? Look it up', 'لديك عنوان مختصر؟ ابحث عنه') }}</Label>
      <div class="mt-2 flex gap-2">
        <Input
          id="lookup_short_address"
          v-model="lookupCode"
          type="text"
          maxlength="8"
          autocapitalize="characters"
          class="h-12 flex-1 rounded-xl text-base uppercase"
          placeholder="RRRD2929"
          dir="ltr"
        />
        <Button type="button" variant="outline" class="h-12 rounded-xl px-5" :disabled="looking || !ADDRESS_RULES.short_address.test(lookupCode)" @click="onLookup">
          {{ looking ? t('searching', 'Searching...', 'جارٍ البحث...') : t('lookup', 'Look up', 'بحث') }}
        </Button>
      </div>
      <span v-if="lookupError" class="mt-2 block text-xs text-destructive">{{ lookupError }}</span>
    </div>

    <div class="grid gap-2">
      <Label for="address_label">{{ t('address_label', 'Label', 'اسم العنوان') }} <span class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span></Label>
      <Input id="address_label" v-model="form.label" type="text" maxlength="64" class="h-12 rounded-xl text-base" :placeholder="t('address_label_placeholder', 'Home, Office…', 'المنزل، العمل…')" />
      <span v-if="err('label')" class="text-xs text-destructive">{{ err('label') }}</span>
    </div>

    <div class="grid gap-2">
      <Label for="delivery_zone_id">{{ t('address_city', 'City', 'المدينة') }}</Label>
      <select
        id="delivery_zone_id"
        v-model="form.delivery_zone_id"
        class="h-12 w-full rounded-xl border border-input bg-transparent px-4 text-base outline-none focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
      >
        <option :value="null">{{ t('address_city_other', 'Other city', 'مدينة أخرى') }}</option>
        <option v-for="zone in zones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
      </select>
      <p class="text-xs text-muted-foreground">{{ feeHint }}</p>
      <span v-if="err('delivery_zone_id')" class="text-xs text-destructive">{{ err('delivery_zone_id') }}</span>
    </div>

    <div class="grid grid-cols-2 gap-3">
      <div class="grid gap-2">
        <Label for="building_number">{{ t('address_building', 'Building no.', 'رقم المبنى') }}</Label>
        <Input id="building_number" v-model="form.building_number" type="text" inputmode="numeric" maxlength="4" class="h-12 rounded-xl text-base" placeholder="1234" dir="ltr" />
        <span v-if="err('building_number')" class="text-xs text-destructive">{{ err('building_number') }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="additional_number">{{ t('address_additional', 'Additional no.', 'الرقم الإضافي') }}</Label>
        <Input id="additional_number" v-model="form.additional_number" type="text" inputmode="numeric" maxlength="4" class="h-12 rounded-xl text-base" placeholder="5678" dir="ltr" />
        <span v-if="err('additional_number')" class="text-xs text-destructive">{{ err('additional_number') }}</span>
      </div>
    </div>

    <div class="grid gap-2">
      <Label for="street">{{ t('address_street', 'Street', 'الشارع') }}</Label>
      <Input id="street" v-model="form.street" type="text" maxlength="160" class="h-12 rounded-xl text-base" />
      <span v-if="err('street')" class="text-xs text-destructive">{{ err('street') }}</span>
    </div>

    <div class="grid grid-cols-2 gap-3">
      <div class="grid gap-2">
        <Label for="district">{{ t('address_district', 'District', 'الحي') }}</Label>
        <Input id="district" v-model="form.district" type="text" maxlength="160" class="h-12 rounded-xl text-base" />
        <span v-if="err('district')" class="text-xs text-destructive">{{ err('district') }}</span>
      </div>
      <div class="grid gap-2">
        <Label for="postal_code">{{ t('address_postal', 'Postal code', 'الرمز البريدي') }}</Label>
        <Input id="postal_code" v-model="form.postal_code" type="text" inputmode="numeric" maxlength="5" class="h-12 rounded-xl text-base" placeholder="12345" dir="ltr" />
        <span v-if="err('postal_code')" class="text-xs text-destructive">{{ err('postal_code') }}</span>
      </div>
    </div>

    <div class="grid grid-cols-2 gap-3">
      <div class="grid gap-2">
        <Label for="unit_number">{{ t('address_unit', 'Unit', 'الوحدة') }} <span class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span></Label>
        <Input id="unit_number" v-model="form.unit_number" type="text" maxlength="16" class="h-12 rounded-xl text-base" dir="ltr" />
      </div>
      <div class="grid gap-2">
        <Label for="short_address">{{ t('address_short', 'Short address', 'العنوان المختصر') }} <span class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span></Label>
        <Input id="short_address" v-model="form.short_address" type="text" maxlength="8" autocapitalize="characters" class="h-12 rounded-xl text-base uppercase" placeholder="RRRD2929" dir="ltr" />
        <span v-if="err('short_address')" class="text-xs text-destructive">{{ err('short_address') }}</span>
      </div>
    </div>

    <div class="grid gap-2">
      <Label for="address_phone">{{ t('address_phone', 'Phone for delivery', 'رقم الهاتف للتوصيل') }}</Label>
      <AuthPhoneInput id="address_phone" v-model="form.phone" :allowed="allowedPhoneCountries" />
      <span v-if="err('phone')" class="text-xs text-destructive">{{ err('phone') }}</span>
    </div>

    <!-- Pin: preview map + coordinates, kept inside the Saudi box the API enforces. -->
    <div class="grid gap-2">
      <Label>{{ t('address_pin', 'Location pin', 'موقعك على الخريطة') }}</Label>
      <div class="overflow-hidden rounded-2xl border bg-brand-mist">
        <iframe
          v-if="hasPin"
          :src="mapSrc"
          class="h-48 w-full"
          loading="lazy"
          referrerpolicy="no-referrer"
          :title="t('address_map', 'Map', 'الخريطة')"
        />
        <div v-else class="flex h-48 items-center justify-center text-sm text-muted-foreground">
          {{ t('address_pin_empty', 'No location yet', 'لم يتم تحديد الموقع بعد') }}
        </div>
      </div>
      <div class="grid grid-cols-[1fr_1fr_auto] gap-2">
        <Input v-model="form.lat" type="text" inputmode="decimal" class="h-12 rounded-xl text-base" :placeholder="t('address_lat', 'Latitude', 'خط العرض')" dir="ltr" :aria-label="t('address_lat', 'Latitude', 'خط العرض')" />
        <Input v-model="form.lng" type="text" inputmode="decimal" class="h-12 rounded-xl text-base" :placeholder="t('address_lng', 'Longitude', 'خط الطول')" dir="ltr" :aria-label="t('address_lng', 'Longitude', 'خط الطول')" />
        <Button type="button" variant="outline" class="h-12 rounded-xl px-3" :disabled="locating" :aria-label="t('address_use_location', 'Use my location', 'استخدم موقعي')" @click="locate">
          <LucideLocateFixed class="size-4" />
        </Button>
      </div>
      <span v-if="err('lat') || err('lng')" class="text-xs text-destructive">{{ err('lat') || err('lng') }}</span>
    </div>

    <div class="grid gap-2">
      <Label for="address_notes">{{ t('address_notes', 'Delivery notes', 'ملاحظات التوصيل') }} <span class="text-xs text-muted-foreground">{{ t('optional', '(optional)', '(اختياري)') }}</span></Label>
      <Input id="address_notes" v-model="form.notes" type="text" maxlength="255" class="h-12 rounded-xl text-base" />
      <span v-if="err('notes')" class="text-xs text-destructive">{{ err('notes') }}</span>
    </div>

    <label class="flex items-center gap-2 text-sm">
      <Checkbox v-model="form.is_default" />
      {{ t('address_make_default', 'Make this my default address', 'اجعله عنواني الافتراضي') }}
    </label>

    <span v-if="submitError" class="text-xs text-destructive">{{ submitError }}</span>

    <div class="mt-2 flex gap-3">
      <Button v-if="showCancel" type="button" variant="outline" class="h-12 flex-1 rounded-xl text-base" :disabled="pending" @click="emit('cancel')">
        {{ t('cancel', 'Cancel', 'إلغاء') }}
      </Button>
      <Button type="submit" class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90" :disabled="pending">
        {{ pending ? t('saving', 'Saving...', 'جارٍ الحفظ...') : t('save_address', 'Save address', 'حفظ العنوان') }}
      </Button>
    </div>
  </form>
</template>

<script setup>
/**
 * Saudi National Address form. Client-side checks mirror the server rules for instant
 * feedback (4-digit building, 5-digit postal, Saudi bounding box…), but whatever the
 * server sends back in `errors.<field>` replaces them — it is the only truth.
 *
 * Emits `saved` with the stored address. Pass `address` to edit an existing one.
 */
const props = defineProps({
  address: { type: Object, default: null },
  showCancel: { type: Boolean, default: true },
})
const emit = defineEmits(['saved', 'cancel'])

const { t } = useLang('web', 'addresses')
const { allowedPhoneCountries } = useAuthConfig()
const { zones, defaultFee, freeDeliveryOver, zoneById } = useDeliveryZones()
const { save, lookup } = useAddresses()
const { format } = usePrice()
const { submit, pending, errors, error: submitError } = useSubmit()

const form = ref({ ...emptyAddressForm(), ...(props.address ?? {}) })
watch(() => props.address, (address) => { form.value = { ...emptyAddressForm(), ...(address ?? {}) } })

const localErrors = ref({})
const err = (field) => fieldError(errors.value, field) || fieldError(localErrors.value, field)

const hasPin = computed(() => isWithinSaudi(form.value.lat, form.value.lng))
// OpenStreetMap's embed needs no key and no script — a read-only preview of the pin.
const mapSrc = computed(() => {
  const lat = Number(form.value.lat)
  const lng = Number(form.value.lng)
  const d = 0.01
  return `https://www.openstreetmap.org/export/embed.html?bbox=${lng - d},${lat - d},${lng + d},${lat + d}&layer=mapnik&marker=${lat},${lng}`
})

const feeHint = computed(() => {
  const zone = zoneById(form.value.delivery_zone_id)
  if (zone) {
    if (zone.never_free) return t('address_zone_fee', 'Delivery :fee', 'التوصيل :fee', { fee: format(zone.fee) })
    const over = zone.free_over ?? freeDeliveryOver.value
    return over
      ? t('address_zone_fee_free_over', 'Delivery :fee — free over :over', 'التوصيل :fee — مجاني للطلبات فوق :over', { fee: format(zone.fee), over: format(over) })
      : t('address_zone_fee', 'Delivery :fee', 'التوصيل :fee', { fee: format(zone.fee) })
  }
  if (defaultFee.value === null) return ''
  return freeDeliveryOver.value
    ? t('address_default_fee_free_over', 'Delivery :fee — free over :over', 'التوصيل :fee — مجاني للطلبات فوق :over', { fee: format(defaultFee.value), over: format(freeDeliveryOver.value) })
    : t('address_zone_fee', 'Delivery :fee', 'التوصيل :fee', { fee: format(defaultFee.value) })
})

const locating = ref(false)
const locate = () => {
  if (!import.meta.client || !navigator.geolocation) return
  locating.value = true
  navigator.geolocation.getCurrentPosition(
    ({ coords }) => {
      form.value.lat = coords.latitude.toFixed(6)
      form.value.lng = coords.longitude.toFixed(6)
      locating.value = false
    },
    () => { locating.value = false },
    { enableHighAccuracy: true, timeout: 10000 },
  )
}

const lookupEnabled = ref(true)
const lookupCode = ref('')
const looking = ref(false)
const lookupError = ref('')

const onLookup = async () => {
  looking.value = true
  lookupError.value = ''
  try {
    const found = await lookup(lookupCode.value.toUpperCase())
    if (!found) return
    form.value = {
      ...form.value,
      building_number: found.building_number ?? form.value.building_number,
      street: found.street ?? form.value.street,
      district: found.district ?? form.value.district,
      postal_code: found.postal_code ?? form.value.postal_code,
      additional_number: found.additional_number ?? form.value.additional_number,
      short_address: lookupCode.value.toUpperCase(),
      lat: found.lat != null ? String(found.lat) : form.value.lat,
      lng: found.lng != null ? String(found.lng) : form.value.lng,
    }
    // The registry returns a city name, not a zone id — match it to the zone list.
    const zone = zones.value.find((z) => z.name?.toLowerCase() === String(found.city ?? '').toLowerCase())
    if (zone) form.value.delivery_zone_id = zone.id
  } catch (e) {
    if (e.unavailable) {
      // Feature switched off server-side (no API key) — not something to retry.
      lookupEnabled.value = false
    } else {
      lookupError.value = fieldError(e, 'short_address') || e.message
    }
  } finally {
    looking.value = false
  }
}

const onSubmit = async () => {
  localErrors.value = validateAddress(form.value, t)
  if (Object.keys(localErrors.value).length) return
  try {
    const saved = await submit(() => save(form.value, props.address?.id ?? null).then((data) => ({ data })))
    emit('saved', saved.data)
  } catch {
    // errors/submitError are bound above
  }
}
</script>
