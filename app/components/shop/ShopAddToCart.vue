<template>
  <div class="flex flex-col gap-3">
    <p v-if="soldOut" class="rounded-2xl bg-destructive/10 px-4 py-3 text-sm font-medium text-destructive">
      {{ t('sold_out', 'Sold out', 'نفدت الكمية') }}
    </p>

    <p v-else-if="stockNote" class="text-xs font-medium text-brand-rust">{{ stockNote }}</p>

    <div class="flex flex-wrap items-center gap-3">
      <ShopQuantityStepper v-model="quantity" :max="max" :disabled="soldOut || pending" />

      <Button
        type="button"
        class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="soldOut || pending"
        @click="onAdd"
      >
        {{ pending ? t('adding', 'Adding…', 'جارٍ الإضافة…') : t('add_to_cart', 'Add', 'اضافة') }}
      </Button>
    </div>

    <span v-if="error" class="text-xs text-destructive">{{ error }}</span>

    <Button v-if="added" as-child variant="outline" class="h-11 rounded-xl">
      <NuxtLink to="/cart">{{ t('go_to_cart', 'Go to my cart', 'الذهاب إلى عربيتي') }}</NuxtLink>
    </Button>
  </div>
</template>

<script setup>
/**
 * The buy control on a product page. `max_quantity` is the server's cap
 * (`min(stock, 100)` tracked, 100 untracked), so the stepper can never ask for stock
 * that is not there — and a stock refusal still comes back on `errors.cart`, worded for
 * the customer, so it is shown verbatim rather than reworded here.
 */
const props = defineProps({
  product: { type: Object, required: true },
})

const { t } = useLang('web', 'shop')
const toast = useToast()
const route = useRoute()
const { add, isRegistered } = useCart()

const quantity = ref(1)
const pending = ref(false)
const error = ref('')
const added = ref(false)

const soldOut = computed(() => props.product.in_stock === false)
const max = computed(() => Math.min(props.product.max_quantity ?? HARD_MAX_QUANTITY, HARD_MAX_QUANTITY))

// `stock: null` is untracked — never claim a number for it.
const stockNote = computed(() => {
  const stock = props.product.stock
  if (stock === null || stock === undefined || stock > 5) return ''
  return t('only_n_left_short', 'Only :n left', 'متبقٍ :n فقط', { n: stock })
})

watch(() => props.product.id, () => { quantity.value = 1; added.value = false; error.value = '' })

const onAdd = async () => {
  if (!isRegistered.value) {
    return navigateTo({ path: '/login', query: { redirect: route.fullPath } })
  }
  pending.value = true
  error.value = ''
  try {
    const res = await add(props.product.id, quantity.value)
    added.value = true
    toast.success(res?.message || t('added_to_cart', 'Added to your cart.', 'تمت الإضافة إلى عربيتك.'))
  } catch (err) {
    const normalized = normalizeApiError(err)
    error.value = fieldError(normalized, 'cart') || fieldError(normalized, 'quantity') || normalized.message
  } finally {
    pending.value = false
  }
}
</script>
