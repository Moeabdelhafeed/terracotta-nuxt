<template>
  <article class="flex h-full flex-col overflow-hidden rounded-card border bg-card" data-test="coffee-item">
    <div class="relative aspect-[4/3] overflow-hidden bg-brand-mist">
      <AppImage v-if="item.image?.image_api" :src="item.image" :alt="item.title" class="size-full object-cover" />
      <span v-else class="flex size-full items-center justify-center text-brand-terracotta/50" aria-hidden="true">
        <LucideCoffee class="size-10" />
      </span>
      <span
        v-if="showCategory && item.category?.title"
        class="absolute start-3 top-3 rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-brand-terracotta backdrop-blur-sm"
      >
        {{ item.category.title }}
      </span>
    </div>

    <div class="flex flex-1 flex-col gap-2 p-4">
      <div class="flex items-start justify-between gap-3">
        <h3 class="font-display text-base font-semibold leading-snug">{{ item.title }}</h3>
        <!-- One price sits beside the name; sizes get a line of their own below. -->
        <span v-if="!item.sizes?.length && item.price" class="shrink-0 font-display font-semibold text-brand-terracotta">
          {{ format(item.price) }}
        </span>
      </div>
      <p v-if="item.description" class="line-clamp-3 text-sm text-muted-foreground">{{ item.description }}</p>

      <ul v-if="item.sizes?.length" class="mt-auto flex flex-wrap gap-2 pt-2" :aria-label="t('coffee_sizes', 'Sizes', 'الأحجام')">
        <li
          v-for="size in item.sizes"
          :key="size.id"
          class="flex items-center gap-1.5 rounded-full bg-brand-terracotta/10 px-3 py-1 text-xs"
        >
          <span class="text-muted-foreground">{{ size.name }}</span>
          <span class="font-semibold text-brand-terracotta">{{ format(size.price) }}</span>
        </li>
      </ul>
    </div>
  </article>
</template>

<script setup>
/** One thing on the coffee house menu — the menu page and the home page draw it the same. */
defineProps({
  item: { type: Object, required: true },
  showCategory: { type: Boolean, default: false },
});

const { t } = useLang("web", "coffee");
const { format } = usePrice();
</script>
