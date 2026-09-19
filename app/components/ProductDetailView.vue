<!--
  One product, both shelves. The shop and the raw materials catalogue sell the same
  shape of thing through the same basket, so they show it the same way — only the
  breadcrumb says which shelf you came from.
-->
<template>
  <!-- A client-side navigation lands here before the fetch resolves; the skeleton keeps
       the page's shape instead of flashing an empty screen. -->
  <main v-if="status !== 'success' && !product" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <div class="grid gap-10 lg:grid-cols-2 lg:items-start">
      <div>
        <AppSkeleton class="aspect-square w-full !rounded-card" />
        <div class="mt-3 flex gap-3">
          <AppSkeleton v-for="n in 4" :key="n" class="size-20 !rounded-field" />
        </div>
      </div>

      <div class="rounded-card border bg-card p-6 sm:p-8">
        <AppSkeleton class="h-4 w-32" />
        <AppSkeleton class="mt-3 h-9 w-3/4" />
        <AppSkeleton class="mt-5 h-8 w-32" />
        <AppSkeleton class="mt-6 h-4 w-full" />
        <AppSkeleton class="mt-2 h-4 w-5/6" />
        <AppSkeleton class="mt-2 h-4 w-2/3" />
        <div class="mt-8 grid gap-4 sm:grid-cols-3">
          <AppSkeleton v-for="n in 3" :key="n" class="h-16 !rounded-card" />
        </div>
      </div>
    </div>
  </main>

  <main v-else-if="product">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="grid gap-10 lg:grid-cols-2 lg:items-start">
        <div ref="content">
          <div class="overflow-hidden rounded-card border bg-brand-container">
            <AppImage v-if="active" :src="active" :alt="product.title" class="aspect-square w-full object-cover" />
          </div>

          <ul v-if="shots.length > 1" class="mt-3 flex gap-3 overflow-x-auto pb-1">
            <li v-for="(shot, index) in shots" :key="index">
              <button
                type="button"
                class="size-20 shrink-0 overflow-hidden rounded-field border transition-opacity"
                :class="active === shot ? 'border-primary' : 'opacity-70 hover:opacity-100'"
                @click="chosen = shot"
              >
                <AppImage :src="shot" :alt="product.title" class="size-full object-cover" />
              </button>
            </li>
          </ul>
        </div>

        <!-- Pinned rather than `position: sticky`: ScrollSmoother transforms
             #smooth-content, and a transformed ancestor makes sticky behave like static. -->
        <aside ref="aside">
          <div class="rounded-card border bg-card p-6 sm:p-8">
            <!-- The API sends these as plain localized strings, not objects. -->
            <p v-if="product.category" class="text-sm uppercase tracking-[0.18em] text-muted-foreground">
              {{ product.category }}<template v-if="product.sub_category"> · {{ product.sub_category }}</template>
            </p>

            <div class="mt-2 flex items-start gap-3">
              <h1 class="min-w-0 flex-1 font-display text-3xl font-bold sm:text-4xl">{{ product.title }}</h1>
              <ShopFavoriteButton class="mt-1 shrink-0" size="lg" :product="product" />
            </div>

            <p class="mt-4 flex flex-wrap items-baseline gap-x-3">
              <span v-if="product.sale_price" class="text-lg text-muted-foreground line-through">{{ format(product.price) }}</span>
              <span class="font-display text-3xl font-black text-primary">{{ format(product.sale_price ?? product.price) }}</span>
            </p>

            <div
              v-if="product.description"
              class="prose prose-sm mt-6 max-w-none break-words dark:prose-invert [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
              v-html="product.description"
            />

            <div v-if="colours.length" class="mt-6">
              <p class="text-xs uppercase tracking-[0.2em] text-muted-foreground">
                {{ t('colour', 'Colour', 'اللون') }}<template v-if="selectedName"> · {{ selectedName }}</template>
              </p>

              <!-- The hex IS the variant id the cart takes, so picking one here is what
                   keeps the glaze on the line the customer ends up paying for. -->
              <ul class="mt-2 flex flex-wrap items-center gap-2">
                <li v-for="colour in colours" :key="colour.hex">
                  <button
                    type="button"
                    class="block size-7 rounded-[6px] border transition-transform hover:scale-110"
                    :class="colour.hex === selectedColour ? 'ring-2 ring-primary ring-offset-2 ring-offset-card' : ''"
                    :style="{ backgroundColor: colour.hex }"
                    :title="colour.name"
                    :aria-label="colour.name"
                    :aria-pressed="colour.hex === selectedColour"
                    @click="pickedColour = colour.hex"
                  />
                </li>
              </ul>
            </div>

            <dl v-if="dimensions.length" class="mt-8 grid gap-px overflow-hidden rounded-card bg-border sm:grid-cols-3">
              <div v-for="dimension in dimensions" :key="dimension.label" class="bg-card px-5 py-4">
                <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ dimension.label }}</dt>
                <dd class="mt-1 font-display text-lg font-semibold">{{ dimension.value }}</dd>
              </div>
            </dl>

            <ShopAddToCart class="mt-8" :product="product" :colour="selectedColour" />
          </div>
        </aside>
      </div>

      <section v-if="product.related_products?.length" class="mt-16">
        <h2 class="font-display text-2xl font-bold">{{ t('related', 'You might also like', 'قد يعجبك أيضًا') }}</h2>
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
const props = defineProps({
  /** Null until the fetch resolves; the page above owns the loading and 404 paths. */
  product: { type: Object, default: null },
  status: { type: String, default: 'idle' },
  /** Which shelf this piece came from — the shop, or raw materials and tools. */
  sectionTo: { type: String, default: '/shop' },
  sectionLabel: { type: String, default: '' },
})

const product = computed(() => props.product)
const status = computed(() => props.status)

const { t } = useLang('web', 'home')
const { format } = usePrice()

const content = ref(null)
const aside = ref(null)

useStickyAside(aside, content, product)

const crumbs = computed(() =>
  productCrumbs({
    product: product.value,
    sectionTo: props.sectionTo,
    sectionLabel: props.sectionLabel,
    t,
  }),
)

const shots = computed(() => {
  const gallery = asList(product.value?.images)
  return gallery.length ? gallery : [product.value?.image].filter(Boolean)
})

/**
 * Derived, not synced. An `immediate` watcher would set this during setup — while the
 * SSR fetch is still in flight and `shots` is empty — and Vue does not flush watchers
 * again before the server render, so the main photo was missing from the SSR HTML
 * entirely and only appeared after hydration (a mismatch, and a late LCP).
 * `chosen` holds a thumbnail the visitor picked; until then the first shot wins.
 */
const chosen = ref(null)
const active = computed(() =>
  chosen.value && shots.value.includes(chosen.value) ? chosen.value : (shots.value[0] ?? null),
)

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
  const value = String(hex).replace('#', '')
  const full = value.length === 3 ? value.split('').map((c) => c + c).join('') : value
  const number = parseInt(full, 16)
  return [(number >> 16) & 255, (number >> 8) & 255, number & 255]
}

const nameFor = (hex) => {
  const [r, g, b] = rgb(hex)
  const nearest = NAMED_COLOURS.reduce(
    (best, entry) => {
      const [er, eg, eb] = rgb(entry.hex)
      const distance = (r - er) ** 2 + (g - eg) ** 2 + (b - eb) ** 2
      return distance < best.distance ? { entry, distance } : best
    },
    { entry: NAMED_COLOURS[0], distance: Infinity },
  ).entry

  return t(`colour_${nearest.en.toLowerCase()}`, nearest.en, nearest.ar)
}

const colours = computed(() =>
  asList(product.value?.colors).map((colour) => {
    const hex = colour.hex ?? colour.color ?? colour
    return { hex, name: colour.name ?? nameFor(hex) }
  }),
)

/**
 * Derived rather than synced, for the same reason `active` is: a watcher would not reset
 * when the product changes under a client-side navigation. The first glaze is the default
 * the app already sends, so a customer who never touches a swatch still buys a glazed piece.
 */
const pickedColour = ref(null)
const selectedColour = computed(() =>
  colours.value.some((colour) => colour.hex === pickedColour.value)
    ? pickedColour.value
    : (colours.value[0]?.hex ?? null),
)
const selectedName = computed(
  () => colours.value.find((colour) => colour.hex === selectedColour.value)?.name ?? '',
)

const dimensions = computed(() => {
  const p = product.value
  if (!p) return []

  // Decimals arrive as strings ("8.00"); the unit is always centimetres.
  const cm = (value) => (value ? `${Number(value)} ${t('cm', 'cm', 'سم')}` : null)

  return [
    { label: t('height', 'Height', 'ارتفاع'), value: cm(p.height) },
    { label: t('width', 'Width', 'عرض'), value: cm(p.width) },
    { label: t('length', 'Length', 'طول'), value: cm(p.length) },
  ].filter((row) => row.value)
})
</script>
