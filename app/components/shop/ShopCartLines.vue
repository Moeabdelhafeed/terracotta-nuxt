<template>
  <ul class="flex flex-col gap-4">
    <li
      v-for="line in items"
      :key="line.id"
      class="rounded-card border bg-card p-4"
      :class="{ 'border-destructive/40': line.in_stock === false }"
      :data-line="line.id"
    >
      <div class="flex gap-3 sm:gap-4" :class="{ 'opacity-60': line.in_stock === false }">
        <!-- An order line outlives its product: the row stays, but it must not become a
             link to `/shop/undefined`. -->
        <component
          :is="line.product ? NuxtLink : 'span'"
          :to="line.product ? `/shop/${line.product.id}` : undefined"
          class="block size-20 shrink-0 overflow-hidden rounded-field border bg-brand-mist sm:size-24 md:size-28"
        >
          <AppImage
            v-if="line.product?.image?.image_api"
            :src="line.product.image"
            :alt="line.product.title"
            class="size-full object-cover"
            :class="{ grayscale: line.in_stock === false }"
          />
          <span v-else class="flex size-full items-center justify-center text-muted-foreground"><LucidePackage class="size-6" /></span>
        </component>

        <div class="flex min-w-0 flex-1 flex-col gap-2">
          <div class="flex items-start justify-between gap-3">
            <div class="min-w-0">
              <component
                :is="line.product ? NuxtLink : 'span'"
                :to="line.product ? `/shop/${line.product.id}` : undefined"
                class="block truncate font-medium text-foreground"
                :class="{ 'hover:underline': line.product }"
              >
                {{ line.product?.title ?? t('product_unavailable', 'Product no longer available', 'المنتج لم يعد متاحًا') }}
              </component>
              <p class="mt-1 flex items-baseline gap-2">
                <span class="font-display text-lg font-black text-primary">{{ format(line.unit_price) }}</span>
                <span v-if="line.product?.sale_price" class="text-sm text-muted-foreground line-through">{{ format(line.product.price) }}</span>
              </p>
              <!-- The glaze the line was bought in. Two colourways of one piece are two
                   lines, so without this they are two identical rows. -->
              <p v-if="line.color" class="mt-1 flex items-center gap-1.5 text-xs text-muted-foreground">
                <span class="inline-block size-3.5 rounded-[6px] border" :style="{ backgroundColor: line.color }" />
                {{ t('colour', 'Colour', 'اللون') }}
              </p>
            </div>

            <button
              type="button"
              class="flex size-10 shrink-0 items-center justify-center rounded-control text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
              :aria-label="t('remove_line', 'Remove from cart', 'إزالة من العربة')"
              :disabled="busy === line.id"
              @click="confirming = line.id"
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

      <!-- Named for what it does rather than asking "are you sure": the row disappears, and
           a customer who meant to change the quantity deserves to know that first. -->
      <div v-if="confirming === line.id" class="mt-3 flex flex-wrap items-center justify-between gap-3 rounded-field bg-muted px-4 py-3">
        <p class="text-xs text-muted-foreground">
          {{ t('remove_line_message', ':title will be taken out of your cart. You can always add it again.', 'راح ينشال :title من عربيتك. تقدر ترجع تضيفه في أي وقت.', { title: line.product?.title ?? '' }) }}
        </p>
        <div class="flex items-center gap-2">
          <Button type="button" size="sm" variant="ghost" @click="confirming = null">
            {{ t('keep_line', 'Keep it', 'خلّه') }}
          </Button>
          <Button type="button" size="sm" variant="destructive" :disabled="busy === line.id" @click="onRemove(line)">
            {{ t('remove_line_confirm', 'Take it out', 'شيله') }}
          </Button>
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
import { NuxtLink } from '#components'

const { t } = useLang('web', 'shop')
const { format } = usePrice()
const { items, update, remove } = useCart()

const busy = ref(null)
const confirming = ref(null)
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

const onRemove = async (line) => {
  await run(line, () => remove(line.id))
  confirming.value = null
}
</script>
