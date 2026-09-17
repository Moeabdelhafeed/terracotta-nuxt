<template>
  <div class="flex flex-col gap-3">
    <p v-if="soldOut" class="rounded-card bg-destructive/10 px-4 py-3 text-sm font-medium text-destructive">
      {{ t('sold_out', 'Sold out', 'نفدت الكمية') }}
    </p>

    <p v-else-if="stockNote" class="text-xs font-medium text-warning">{{ stockNote }}</p>

    <div class="flex flex-wrap items-center gap-3">
      <ShopQuantityStepper v-if="!soldOut" v-model="quantity" :max="room" :disabled="full || pending" />

      <Button
        type="button"
        class="h-12 flex-1 bg-brand-rust text-base hover:bg-brand-rust/90"
        :disabled="soldOut || full || pending"
        @click="onAdd"
      >
        {{ pending ? t('adding', 'Adding…', 'جارٍ الإضافة…') : t('add_to_cart', 'Add', 'اضافة') }}
      </Button>
    </div>

    <!-- Context for the decision, not a warning — until the cart holds the cap, which is
         the one case the customer cannot act on and the button goes dead. -->
    <p v-if="inCart && !full" class="text-xs text-muted-foreground">
      {{ t('in_cart_already', ':n of this already in your cart.', 'لديك :n من هذه القطعة في السلة.', { n: inCart }) }}
    </p>
    <p v-else-if="full" class="text-xs font-medium text-warning">
      {{ t('cart_full_for_item', 'That is all we can add — you already have :n of this in your cart.', 'هذا كل ما يمكن إضافته، فلديك :n من هذه القطعة في السلة.', { n: inCart }) }}
    </p>

    <span v-if="error" class="text-xs text-destructive">{{ error }}</span>

    <Button v-if="added" as-child variant="outline" class="h-11">
      <NuxtLink to="/cart">{{ t('go_to_cart', 'Go to my cart', 'الذهاب إلى عربيتي') }}</NuxtLink>
    </Button>
  </div>
</template>

<script setup>
/**
 * The buy control on a product page. `max_quantity` is the server's cap
 * (`min(stock, 100)` tracked, 100 untracked), and it is a cap on the LINE the server
 * keeps — so what is already in the basket comes off what this stepper may ask for,
 * across every colourway of the same piece. A stock refusal still comes back on
 * `errors.cart`, worded for the customer, so it is shown verbatim rather than reworded.
 */
const props = defineProps({
  product: { type: Object, required: true },
  /** The chosen glaze, as the bare hex the cart takes as its variant id. */
  colour: { type: String, default: null },
})

const { t } = useLang('web', 'shop')
const toast = useToast()
const { add, items } = useCart()

const quantity = ref(1)
const pending = ref(false)
const error = ref('')
const added = ref(false)

const soldOut = computed(() => props.product.in_stock === false)
const ceiling = computed(() => Math.min(props.product.max_quantity ?? HARD_MAX_QUANTITY, HARD_MAX_QUANTITY))
const inCart = computed(() => quantityOf(items.value, props.product.id))
const room = computed(() => Math.max(0, ceiling.value - inCart.value))
const full = computed(() => !soldOut.value && room.value === 0)

// `stock: null` is untracked — never claim a number for it. Below five is worth saying;
// at five or more a count is noise.
const stockNote = computed(() => {
  const stock = props.product.stock
  if (stock === null || stock === undefined || stock >= 5) return ''
  return t('only_n_left_short', 'Only :n left', 'متبقٍ :n فقط', { n: stock })
})

watch(() => props.product.id, () => { quantity.value = 1; added.value = false; error.value = '' })
watch(room, (value) => { if (quantity.value > value) quantity.value = Math.max(1, value) })

const onAdd = async () => {
  pending.value = true
  error.value = ''
  try {
    const res = await add(props.product.id, quantity.value, props.colour)
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
