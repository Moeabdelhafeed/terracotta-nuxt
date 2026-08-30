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
      <NuxtLink to="/shop" class="text-sm font-medium text-primary underline-offset-4 hover:underline">
        {{ t('view_all', 'View all', 'عرض الكل') }}
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
defineProps({
  products: { type: Array, default: () => [] },
  title: { type: String, default: '' },
  anchor: { type: String, default: undefined },
})

const { t } = useLang('web', 'home')
</script>
