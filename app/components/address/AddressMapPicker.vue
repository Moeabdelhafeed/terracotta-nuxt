<template>
  <div class="overflow-hidden rounded-2xl border bg-brand-mist">
    <div v-show="state === 'ready'" ref="container" class="h-64 w-full" data-test="address-map" />

    <div v-if="state === 'loading'" class="flex h-64 items-center justify-center" aria-busy="true">
      <AppSkeleton class="size-full !rounded-none" />
    </div>

    <div
      v-else-if="state === 'failed'"
      class="flex h-64 flex-col items-center justify-center gap-2 px-6 text-center text-sm text-muted-foreground"
      data-test="address-map-unavailable"
    >
      <LucideMapPinOff class="size-5" />
      {{ t('address_map_unavailable', 'The map could not load — type the coordinates below instead.', 'تعذّر تحميل الخريطة — اكتب الإحداثيات بالأسفل بدلًا من ذلك.') }}
    </div>
  </div>
  <p v-if="state === 'ready'" class="text-xs text-muted-foreground">
    {{ t('address_map_hint', 'Tap the map or drag the pin to where the courier should come.', 'اضغط على الخريطة أو اسحب الدبوس إلى المكان الذي يصل إليه المندوب.') }}
  </p>
</template>

<script setup>
/**
 * The delivery pin, on Google Maps (QA GEN-01 — this was a read-only OpenStreetMap embed,
 * so the customer could only type coordinates). Tap the map or drag the pin to set it; the
 * coordinates typed below, "use my location" and the short-address lookup move it in turn.
 * The CMS shows the same pin on the same provider.
 */
const props = defineProps({
  lat: { type: [String, Number], default: null },
  lng: { type: [String, Number], default: null },
})

const emit = defineEmits(['pick'])

const { t, code } = useLang('web', 'addresses')
const { load, onAuthFailure } = useGoogleMaps()

// Riyadh, when there is no pin yet — every address is in Saudi Arabia.
const FALLBACK_CENTRE = { lat: 24.7136, lng: 46.6753 }

const container = ref(null)
const state = ref('loading')

let map = null
let marker = null

// Refused for this address (www., localhost): fall back to typing, not Google's grey box.
const stopListening = onAuthFailure(() => {
  state.value = 'failed'
})

const pin = computed(() => {
  const lat = Number(props.lat)
  const lng = Number(props.lng)
  if (props.lat === null || props.lat === '' || props.lng === null || props.lng === '') return null
  return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null
})

const place = (position) => {
  if (!map) return
  if (!marker) {
    marker = new window.google.maps.Marker({ position, map, draggable: true })
    marker.addListener('dragend', (event) => pick(event.latLng))
  } else {
    marker.setPosition(position)
  }
}

const pick = (latLng) => {
  const position = { lat: latLng.lat(), lng: latLng.lng() }
  place(position)
  emit('pick', { lat: position.lat.toFixed(6), lng: position.lng.toFixed(6) })
}

onMounted(async () => {
  let maps
  try {
    maps = await load(code.value || 'ar')
  } catch {
    state.value = 'failed'
    return
  }

  state.value = 'ready'
  await nextTick()
  if (!container.value) return

  map = new maps.Map(container.value, {
    center: pin.value ?? FALLBACK_CENTRE,
    zoom: pin.value ? 16 : 11,
    gestureHandling: 'cooperative',
    mapTypeControl: false,
    streetViewControl: false,
    fullscreenControl: true,
    clickableIcons: false,
  })
  map.addListener('click', (event) => pick(event.latLng))

  if (pin.value) place(pin.value)
})

// Coordinates changed from outside the map (typed, located, looked up): follow them.
watch(pin, (position) => {
  if (!map || !position) return
  place(position)
  map.panTo(position)
})

onBeforeUnmount(() => {
  stopListening()
  marker?.setMap(null)
  map = marker = null
})
</script>
