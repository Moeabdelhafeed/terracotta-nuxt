<template>
  <ul class="flex flex-col divide-y">
    <li v-for="item in items" :key="item.id" class="flex items-center gap-3 py-3 first:pt-0 last:pb-0 sm:gap-4">
      <component
        :is="item.product ? NuxtLink : 'span'"
        :to="item.product ? `/shop/${item.product.id}` : undefined"
        class="block size-12 shrink-0 overflow-hidden rounded-xl border bg-brand-mist sm:size-16"
      >
        <AppImage v-if="item.product?.image?.image_api" :src="item.product.image" :alt="item.product.title" class="size-full object-cover" />
        <span v-else class="flex size-full items-center justify-center text-muted-foreground"><LucidePackage class="size-5" /></span>
      </component>

      <div class="min-w-0 flex-1">
        <p class="truncate text-sm font-medium text-foreground">
          {{ item.product?.title ?? t('product_unavailable', 'Product no longer available', 'المنتج لم يعد متاحًا') }}
        </p>
        <p class="text-xs text-muted-foreground">
          {{ t('qty_times_price', ':qty × :price', ':qty × :price', { qty: item.quantity, price: format(item.unit_price) }) }}
        </p>
      </div>

      <span class="shrink-0 font-display text-sm font-semibold sm:text-base">{{ format(item.line_total) }}</span>
    </li>
  </ul>
</template>

<script setup>
/** Order lines. `product` is `null` once a piece is deleted — the snapshot still renders. */
defineProps({
  items: { type: Array, default: () => [] },
})

const NuxtLink = resolveComponent('NuxtLink')
const { t } = useLang('web', 'shop')
const { format } = usePrice()
</script>
