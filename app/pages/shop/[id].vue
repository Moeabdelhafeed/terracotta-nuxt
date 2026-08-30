<template>
  <main v-if="product">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="grid gap-10 lg:grid-cols-2 lg:items-start">
        <div>
          <div class="overflow-hidden rounded-3xl border bg-card">
            <AppImage v-if="active" :src="active" :alt="product.title" class="aspect-square w-full object-cover" />
          </div>

          <ul v-if="shots.length > 1" class="mt-3 flex gap-3 overflow-x-auto pb-1">
            <li v-for="(shot, index) in shots" :key="index">
              <button
                type="button"
                class="size-20 shrink-0 overflow-hidden rounded-xl border transition-opacity"
                :class="active === shot ? 'border-primary' : 'opacity-70 hover:opacity-100'"
                @click="active = shot"
              >
                <AppImage :src="shot" :alt="product.title" class="size-full object-cover" />
              </button>
            </li>
          </ul>
        </div>

        <div>
          <!-- The API sends these as plain localized strings, not objects. -->
          <p v-if="product.category" class="text-sm uppercase tracking-[0.18em] text-muted-foreground">
            {{ product.category }}<template v-if="product.sub_category"> · {{ product.sub_category }}</template>
          </p>

          <h1 class="mt-2 font-display text-3xl font-semibold sm:text-4xl">{{ product.title }}</h1>

          <p class="mt-4 flex items-baseline gap-3">
            <span class="font-display text-3xl font-black text-primary">{{ format(product.sale_price ?? product.price) }}</span>
            <span v-if="product.sale_price" class="text-lg text-muted-foreground line-through">{{ format(product.price) }}</span>
          </p>

          <div
            v-if="product.description"
            class="prose prose-sm mt-6 max-w-none dark:prose-invert [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
            v-html="product.description"
          />

          <ul v-if="colours.length" class="mt-6 flex items-center gap-2">
            <li v-for="colour in colours" :key="colour.hex" class="group/colour relative">
              <span
                class="block size-7 rounded-full border transition-transform group-hover/colour:scale-110"
                :style="{ backgroundColor: colour.hex }"
                :aria-label="colour.name"
              />
              <span
                class="pointer-events-none absolute bottom-full left-1/2 z-10 mb-2 -translate-x-1/2 whitespace-nowrap rounded-md bg-brand-ink px-2 py-1 text-xs font-medium text-white opacity-0 shadow-lg transition-opacity group-hover/colour:opacity-100"
              >{{ colour.name }}</span>
            </li>
          </ul>

          <dl v-if="dimensions.length" class="mt-8 grid gap-px overflow-hidden rounded-2xl bg-border sm:grid-cols-3">
            <div v-for="dimension in dimensions" :key="dimension.label" class="bg-card px-5 py-4">
              <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ dimension.label }}</dt>
              <dd class="mt-1 font-display text-lg font-semibold">{{ dimension.value }}</dd>
            </div>
          </dl>

          <p class="mt-8 text-sm text-muted-foreground">
            {{ t('visit_to_buy', 'Pieces are sold in the studio — come and see them in person.', 'تُباع القطع في الاستوديو — تعال وشاهدها على الطبيعة.') }}
          </p>
        </div>
      </div>

      <section v-if="product.related_products?.length" class="mt-16">
        <h2 class="font-display text-2xl font-semibold">{{ t('related', 'You might also like', 'قد يعجبك أيضًا') }}</h2>
        <ul class="mt-5 grid grid-cols-2 gap-5 lg:grid-cols-4">
          <li v-for="item in product.related_products" :key="item.id">
            <ProductCard :product="item" />
          </li>
        </ul>
      </section>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const { product } = useProduct(() => route.params.id)
const { t } = useLang('web', 'home')
const { format } = usePrice()

const crumbs = computed(() => [
  { to: '/shop', label: t('nav_shop', 'Shop', 'المتجر') },
  ...(product.value?.category ? [{ label: product.value.category }] : []),
  { label: product.value?.title ?? '' },
])

const shots = computed(() => {
  const gallery = product.value?.images ?? []
  return gallery.length ? gallery : [product.value?.image].filter(Boolean)
})

const active = ref(null)
watch(shots, (list) => { active.value = list[0] ?? null }, { immediate: true })

/**
 * Swatch names, since the API sends bare hex strings. The value is matched to the nearest
 * of these in RGB — close enough to label a glaze, and the studio palette is small.
 */
const NAMED_COLOURS = [
  { hex: '#000000', en: 'Black', ar: 'أسود' },
  { hex: '#2b2b2b', en: 'Charcoal', ar: 'فحمي' },
  { hex: '#808080', en: 'Grey', ar: 'رمادي' },
  { hex: '#ffffff', en: 'White', ar: 'أبيض' },
  { hex: '#f5efe6', en: 'Cream', ar: 'كريمي' },
  { hex: '#e0cfae', en: 'Sand', ar: 'رملي' },
  { hex: '#c96f4a', en: 'Terracotta', ar: 'تراكوتا' },
  { hex: '#8b4513', en: 'Rust', ar: 'صدئي' },
  { hex: '#5b3a29', en: 'Brown', ar: 'بني' },
  { hex: '#d64545', en: 'Red', ar: 'أحمر' },
  { hex: '#e08a3c', en: 'Orange', ar: 'برتقالي' },
  { hex: '#e6c34a', en: 'Yellow', ar: 'أصفر' },
  { hex: '#7a8b3a', en: 'Olive', ar: 'زيتي' },
  { hex: '#345a4a', en: 'Forest', ar: 'أخضر داكن' },
  { hex: '#4aa37a', en: 'Green', ar: 'أخضر' },
  { hex: '#3a7d8b', en: 'Teal', ar: 'أزرق مخضر' },
  { hex: '#3a5a8b', en: 'Blue', ar: 'أزرق' },
  { hex: '#1e2a44', en: 'Navy', ar: 'كحلي' },
  { hex: '#6b4a8b', en: 'Purple', ar: 'بنفسجي' },
  { hex: '#d98ba5', en: 'Pink', ar: 'وردي' },
]

const rgb = (hex) => {
  const value = hex.replace('#', '')
  const full = value.length === 3 ? value.split('').map((c) => c + c).join('') : value
  const number = parseInt(full, 16)
  return [(number >> 16) & 255, (number >> 8) & 255, number & 255]
}

const nameFor = (hex) => {
  const [r, g, b] = rgb(hex)
  const nearest = NAMED_COLOURS.reduce((best, entry) => {
    const [er, eg, eb] = rgb(entry.hex)
    const distance = (r - er) ** 2 + (g - eg) ** 2 + (b - eb) ** 2
    return distance < best.distance ? { entry, distance } : best
  }, { entry: NAMED_COLOURS[0], distance: Infinity }).entry

  return t(`colour_${nearest.en.toLowerCase()}`, nearest.en, nearest.ar)
}

const colours = computed(() =>
  (product.value?.colors ?? []).map((colour) => {
    const hex = colour.hex ?? colour.color ?? colour
    return { hex, name: colour.name ?? nameFor(hex) }
  }),
)

const dimensions = computed(() => {
  const p = product.value
  if (!p) return []

  // Decimals arrive as strings ("8.00"); the unit is always centimetres.
  const cm = (value) => (value ? `${Number(value)} ${t('cm', 'cm', 'سم')}` : null)

  return [
    { label: t('height', 'Height', 'الارتفاع'), value: cm(p.height) },
    { label: t('width', 'Width', 'العرض'), value: cm(p.width) },
    { label: t('length', 'Length', 'الطول') , value: cm(p.length) },
  ].filter((row) => row.value)
})

useSeoMeta({ title: () => product.value?.title ?? '' })
</script>
