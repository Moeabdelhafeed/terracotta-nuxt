<template>
  <!--
    Motion note: the fade lives in the binding value (opacity: 0), not in the
    `fromInvisible` modifier. That modifier ships `opacity: 0` as plain SSR CSS, so a
    failed trigger — no JS, an error, a crawler — would leave the section invisible for
    good. Passing it to GSAP instead means the content renders visible and only animates
    when the script actually runs.
  -->
  <section id="categories" v-if="categories.length" class="bg-brand-mist/40 py-24">
    <div class="mx-auto max-w-6xl px-6">
      <h2 class="mb-10 font-display text-3xl font-semibold sm:text-4xl">
        {{ t('browse_categories', 'Browse categories', 'تصفح الفئات') }}
      </h2>

      <ul
        v-gsap.whenVisible.once.from.stagger="{ opacity: 0, y: 32, duration: 0.6 }"
        class="grid grid-cols-2 gap-4 sm:grid-cols-4"
      >
        <li v-for="category in categories" :key="category.id">
          <NuxtLink :to="`/shop?category=${category.id}`" class="group block text-center">
            <!-- Category cut-outs arrive as transparent PNGs, so the disc is the colour
                 and the piece sits centred inside it rather than filling it. -->
            <div class="flex aspect-square items-center justify-center overflow-hidden rounded-full bg-brand-terracotta p-6">
              <AppImage
                v-if="category.image?.image_api"
                :src="category.image"
                :alt="category.title"
                class="size-full object-contain transition-transform duration-500 group-hover:scale-110"
              />
            </div>
            <p class="mt-3 text-sm font-medium text-brand-rust">{{ category.title }}</p>
          </NuxtLink>
        </li>
      </ul>
    </div>
  </section>
</template>

<script setup>
const { categories } = useHome()
const { t } = useLang('web', 'home')
</script>
