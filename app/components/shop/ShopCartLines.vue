<template>
  <ul class="flex flex-col gap-4">
    <li
      v-for="line in items"
      :key="line.id"
      class="rounded-2xl border bg-card p-4"
      :class="{ 'border-destructive/40': line.in_stock === false }"
      :data-line="line.id"
    >
      <div class="flex gap-4" :class="{ 'opacity-60': line.in_stock === false }">
        <NuxtLink :to="`/shop/${line.product?.id}`" class="block size-24 shrink-0 overflow-hidden rounded-xl border bg-brand-mist sm:size-28">
          <AppImage
            v-if="line.product?.image?.image_api"
            :src="line.product.image"
            :alt="line.product.title"
            class="size-full object-cover"
            :class="{ grayscale: line.in_stock === false }"
          />
        </NuxtLink>

        <div class="flex min-w-0 flex-1 flex-col gap-2">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <NuxtLink :to="`/shop/${line.product?.id}`" class="block truncate font-medium text-foreground hover:underline">
                {{ line.product?.title ?? t('product_unavailable', 'Product no longer available', 'المنتج لم يعد متاحًا') }}
              </NuxtLink>
              <p class="mt-1 flex items-baseline gap-2">
                <span class="font-display text-lg font-black text-primary">{{ format(line.unit_price) }}</span>
                <span v-if="line.product?.sale_price" class="text-sm text-muted-foreground line-through">{{ format(line.product.price) }}</span>
              </p>
            </div>

            <button
              type="button"
              class="flex size-9 shrink-0 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
              :aria-label="t('remove_line', 'Remove from cart', 'إزالة من العربة')"
              :disabled="busy === line.id"
              @click="onRemove(line)"
            >
              <LucideTrash2 class="size-4" />
            </button>
          </div>

          <div class="flex flex-wrap items-center justify-between gap-3">
            <ShopQuantityStepper
              :model-value="line.quantity"
              :max="lineMax(line)"
              :disabled="busy === line.id || line.in_stock === false"
              @update:model-value="onUpdate(line, $event)"
            />
            <span class="font-display text-base font-semibold">{{ format(line.line_total) }}</span>
          </div>
        </div>
      </div>

      <p v-if="line.in_stock === false" class="mt-3 flex items-center gap-2 text-xs font-medium text-destructive">
        <LucideAlertCircle class="size-4 shrink-0" />
        <span v-if="line.available_stock > 0">
          {{ t('only_n_left', 'Only :n left — reduce the quantity to continue.', 'متبقٍ :n فقط — قلّل الكمية للمتابعة.', { n: line.available_stock }) }}
        </span>
        <span v-else>{{ t('sold_out_line', 'Sold out — remove this line to continue.', 'نفدت الكمية — أزل هذا المنتج للمتابعة.') }}</span>
      </p>

      <span v-if="lineErrors[line.id]" class="mt-2 block text-xs text-destructive">{{ lineErrors[line.id] }}</span>
    </li>
  </ul>
</template>

<script setup>
/**
 * The basket's lines with their steppers. A line that can no longer be fulfilled stays on
 * screen, greyed and explained — hiding it would hide the reason checkout is blocked.
 */
const { t } = useLang('web', 'shop')
const { format } = usePrice()
const { items, update, remove } = useCart()

const busy = ref(null)
const lineErrors = ref({})

const run = async (line, call) => {
  busy.value = line.id
  lineErrors.value = { ...lineErrors.value, [line.id]: '' }
  try {
    await call()
  } catch (err) {
    const normalized = normalizeApiError(err)
    // Stock refusals arrive as `errors.cart` and are already worded for the customer.
    lineErrors.value = { ...lineErrors.value, [line.id]: fieldError(normalized, 'cart') || fieldError(normalized, 'quantity') || normalized.message }
  } finally {
    busy.value = null
  }
}

const onUpdate = (line, quantity) => {
  if (quantity === line.quantity) return
  run(line, () => update(line.id, quantity))
}

const onRemove = (line) => run(line, () => remove(line.id))
</script>
