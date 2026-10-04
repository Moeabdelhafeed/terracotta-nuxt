<template>
  <!-- The coffee house on the front door: always the invitation (the studio has one, and
       the menu is a tap away), and under it the items the studio starred — only when it
       has starred some. -->
  <section id="coffee-house" class="mx-auto max-w-6xl px-6 py-20" data-test="home-coffee">
    <div class="grid items-center gap-8 overflow-hidden rounded-card bg-brand-mist md:grid-cols-2">
      <div class="aspect-[4/3] md:aspect-auto md:h-full md:min-h-80">
        <AppMedia :src="picture" alt="" class="size-full object-cover" />
      </div>
      <div class="flex flex-col items-start gap-4 p-8 md:py-12 md:pe-12 md:ps-0">
        <span class="text-sm font-medium text-brand-terracotta">
          {{ t('home_coffee_eyebrow', 'Our coffee house', 'مقهى تيراكوتا') }}
        </span>
        <h2 class="font-display text-3xl font-semibold sm:text-4xl">
          {{ t('home_coffee_title', 'A coffee while your piece takes shape', 'قهوة بينما تتشكّل قطعتك') }}
        </h2>
        <p class="text-muted-foreground">
          {{
            t(
              'home_coffee_body',
              'Our coffee house is open to everyone — order at the counter, whether you are here for a workshop or just passing by.',
              'مقهانا مفتوح للجميع — اطلب من الكاونتر، سواء جئت لورشة أو مررت بنا فقط.',
            )
          }}
        </p>
        <Button as-child size="lg" class="mt-2 h-12 rounded-control px-6">
          <NuxtLink to="/coffee-house" data-test="home-coffee-menu">
            <LucideCoffee class="size-4" aria-hidden="true" />
            {{ t('home_coffee_menu', 'View the menu', 'عرض القائمة') }}
          </NuxtLink>
        </Button>
      </div>
    </div>

    <div v-if="featured.length" class="mt-10" data-test="home-coffee-featured">
      <h3 class="mb-5 font-display text-xl font-semibold">{{ t('home_coffee_featured', 'From our menu', 'من قائمتنا') }}</h3>
      <ul
        v-gsap.whenVisible.once.from.stagger="entranceFrom({ opacity: 0, y: 36, duration: 0.6 })"
        class="grid grid-cols-2 gap-3 sm:gap-5 lg:grid-cols-4"
      >
        <li v-for="item in featured" :key="item.id"><CoffeeItemCard :item="item" show-category /></li>
      </ul>
    </div>
  </section>
</template>

<script setup>
/** The front door's invitation to the coffee house, and the menu items the studio starred. */
const { t } = useLang('web', 'home')
const { mediaAsset } = useMedia('web', 'home')
const { items: featured } = useCoffeeFeatured(4)

// Dynamic storage, like the rest of the home page's pictures; the studio swaps it from the CMS.
const picture = computed(() => mediaAsset('coffee_house', '/seed/studio-1.webp'))
</script>
