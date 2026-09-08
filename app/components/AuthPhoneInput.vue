<template>
  <div ref="root" class="relative flex gap-2" dir="ltr">
    <button
      type="button"
      class="group flex h-12 shrink-0 items-center gap-1.5 rounded-xl border border-input bg-transparent px-3 text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
      @click="open = !open"
    >
      <span class="text-base leading-none">{{ flag(country.iso2) }}</span>
      <span class="text-muted-foreground group-hover:text-accent-foreground">+{{ country.dial }}</span>
      <LucideChevronDown class="size-3.5 text-muted-foreground group-hover:text-accent-foreground" />
    </button>

    <input
      :id="id"
      v-model="digits"
      type="tel"
      inputmode="numeric"
      :placeholder="placeholder"
      class="h-12 min-w-0 flex-1 rounded-xl border border-input bg-transparent px-4 text-base shadow-xs outline-none transition-[color,box-shadow] placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
      v-bind="$attrs"
      @input="digits = $event.target.value.replace(/\D/g, '')"
    >

    <div
      v-if="open"
      class="absolute start-0 top-full z-50 mt-2 w-full min-w-0 overflow-hidden rounded-xl border bg-popover text-popover-foreground shadow-lg sm:w-72"
    >
      <input
        v-model="search"
        type="text"
        :placeholder="t('search_country', 'Search country', 'ابحث عن دولة')"
        class="w-full border-b bg-transparent px-3 py-2.5 text-sm outline-none"
        @keydown.stop
      >
      <ul class="max-h-64 overflow-y-auto py-1">
        <li v-for="c in filtered" :key="c.iso2">
          <button
            type="button"
            class="group flex w-full items-center gap-2.5 px-3 py-2 text-start text-sm transition-colors hover:bg-accent hover:text-accent-foreground"
            @click="select(c)"
          >
            <span class="text-base leading-none">{{ flag(c.iso2) }}</span>
            <span class="min-w-0 flex-1 truncate">{{ code === 'ar' ? c.ar : c.en }}</span>
            <span class="text-muted-foreground group-hover:text-accent-foreground">+{{ c.dial }}</span>
          </button>
        </li>
        <li v-if="!filtered.length" class="px-3 py-4 text-center text-sm text-muted-foreground">
          {{ t('no_results', 'No matches', 'لا نتائج') }}
        </li>
      </ul>
    </div>
  </div>
</template>

<script setup>
/**
 * A phone number as the app actually sends it: a country (flag + dial code, defaulted
 * to the visitor's own) and the local digits, joined into one E.164 string on `v-model`
 * — the API never sees a bare local number with no country attached.
 */
const props = defineProps({
  id: { type: String, required: true },
  placeholder: { type: String, default: '5XXXXXXXX' },
  /** `"all"` or an array of ISO codes — mirrors `useAuthConfig().allowedPhoneCountries`. */
  allowed: { type: [String, Array], default: 'all' },
})

const modelValue = defineModel({ type: String, default: '' })
const { t, code } = useLang('web', 'general')

const root = ref(null)
const open = ref(false)
const search = ref('')

const options = computed(() => {
  if (props.allowed === 'all' || !Array.isArray(props.allowed) || !props.allowed.length) return COUNTRIES
  const allow = props.allowed.map((c) => String(c).toUpperCase())
  return COUNTRIES.filter((c) => allow.includes(c.iso2))
})

// The regional-indicator pair a flag emoji is made of — two letters, no image asset.
const flag = (iso2) => String.fromCodePoint(...[...iso2.toUpperCase()].map((c) => 127397 + c.charCodeAt(0)))

// Starts on the same default on server and client — hydration compares text nodes,
// so guessing the visitor's country here would mismatch whatever SSR rendered.
// Detection happens after mount instead, once there's no SSR output left to disagree with.
const country = ref(options.value[0]) // Saudi Arabia when unrestricted — the business's own country.
const digits = ref('')

onMounted(() => {
  if (digits.value) return // a restored value already picked a country — don't override it.
  // Timezone reflects where the device actually is; `navigator.language` only reflects
  // UI language, so a Jordanian visitor with an English phone would otherwise resolve
  // to whatever country "en" defaults to (typically GB or US) instead of JO.
  try {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone
    const region = TIMEZONE_COUNTRIES[tz]
    const match = region && options.value.find((c) => c.iso2 === region)
    if (match) { country.value = match; return }
  } catch {
    // Fall through to the language-based guess below.
  }
  try {
    const region = new Intl.Locale(navigator.language).maximize().region
    const match = options.value.find((c) => c.iso2 === region)
    if (match) country.value = match
  } catch {
    // Detection is a convenience default, not a requirement.
  }
})

// Parses an incoming value (e.g. a value restored from a previous step) back into a
// country + local digits, so the picker reflects what the field actually holds.
const applyModelValue = (value) => {
  const trimmed = String(value ?? '').replace(/^\+/, '')
  if (!trimmed) return
  const match = options.value
    .filter((c) => trimmed.startsWith(c.dial))
    .sort((a, b) => b.dial.length - a.dial.length)[0]
  if (match) {
    country.value = match
    digits.value = trimmed.slice(match.dial.length)
  }
}
applyModelValue(modelValue.value)

watch([country, digits], () => {
  modelValue.value = digits.value ? `+${country.value.dial}${digits.value}` : ''
})

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return options.value
  return options.value.filter((c) =>
    c.en.toLowerCase().includes(q) || c.ar.includes(q) || c.dial.includes(q))
})

const select = (c) => {
  country.value = c
  open.value = false
  search.value = ''
}

onClickOutside(root, () => { open.value = false })
</script>
