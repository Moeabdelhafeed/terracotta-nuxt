<template>
  <!--
    Motion note: the fade lives in the binding value (opacity: 0), not in the
    `fromInvisible` modifier. That modifier ships `opacity: 0` as plain SSR CSS, so a
    failed trigger — no JS, an error, a crawler — would leave the section invisible for
    good. Passing it to GSAP instead means the content renders visible and only animates
    when the script actually runs.
  -->
  <section :id="anchor" v-if="products.length" class="mx-auto max-w-6xl px-6 py-20">
    <header class="mb-8 flex items-end justify-between gap-4">
      <h2 class="font-display text-3xl font-semibold sm:text-4xl">{{ title }}</h2>
      <NuxtLink :to="to" class="text-sm font-medium text-primary underline-offset-4 hover:underline">
        {{ t('view_all', 'View all', 'عرض الكل') }}
        <span v-if="total > products.length" class="tabular-nums" dir="ltr" data-test="grid-count">({{ total }})</span>
      </NuxtLink>
    </header>

    <ul
      v-gsap.whenVisible.once.from.stagger="{ opacity: 0, y: 36, duration: 0.6 }"
      class="grid grid-cols-2 gap-5 lg:grid-cols-4"
    >
      <li v-for="product in products" :key="product.id">
        <ProductCard :product="product" />
      </li>
    </ul>
  </section>
</template>

<script setup>
/** Featured pieces and offers are the same card, so they share one component. */
const props = defineProps({
  products: { type: Array, default: () => [] },
  title: { type: String, default: '' },
  anchor: { type: String, default: undefined },
  /** Where "View all" lands — the shop, filtered the way this row is. */
  to: { type: String, default: '/shop' },
  /** The filter this row shows a slice of, so the link can say how many it leads to. */
  countQuery: { type: Object, default: () => ({}) },
})

const { t } = useLang('web', 'home')

// How many pieces are behind the link, not how many are on screen. One row of a
// paginator, after hydration only: the front door must not wait on a number.
const { total } = useApiList('/api/shop/products', {
  key: `home-count-${props.anchor}`,
  query: { ...props.countQuery, per_page: 1 },
  server: false,
  lazy: true,
  // A row with nothing in it is not rendered, so it has no link to label.
  immediate: props.products.length > 0,
})
</script>
