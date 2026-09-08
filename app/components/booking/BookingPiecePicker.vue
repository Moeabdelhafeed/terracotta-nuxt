<template>
  <div class="grid gap-8 lg:grid-cols-[1.5fr_1fr] lg:items-start">
    <div>
      <h2 class="font-display text-2xl font-semibold">{{ t('pieces_title', 'Choose your pieces', 'اختيار القطع') }}</h2>
      <p class="mt-2 text-sm text-muted-foreground">{{ boundsNote }}</p>

      <!-- category tabs -->
      <ul v-if="categories.length" class="mt-6 flex gap-2 overflow-x-auto pb-2">
        <li v-for="category in categories" :key="category.id" class="shrink-0">
          <Button
            type="button"
            size="sm"
            class="rounded-xl"
            :variant="categoryId === category.id ? 'default' : 'outline'"
            :class="categoryId === category.id ? 'bg-brand-rust hover:bg-brand-rust/90' : ''"
            @click="categoryId = category.id"
          >{{ category.title }}</Button>
        </li>
      </ul>

      <!-- sub-category tabs -->
      <template v-if="category">
        <p class="mt-6 text-xs uppercase tracking-[0.2em] text-muted-foreground">
          {{ t('sub_categories_of', 'Categories of :name', 'فئات :name', { name: category.title }) }}
        </p>
        <ul class="mt-3 flex gap-2 overflow-x-auto pb-2">
          <li v-for="sub in category.sub_categories" :key="sub.id" class="shrink-0">
            <Button
              type="button"
              size="sm"
              class="rounded-xl"
              :variant="subId === sub.id ? 'default' : 'outline'"
              :class="subId === sub.id ? 'bg-brand-rust hover:bg-brand-rust/90' : ''"
              @click="subId = sub.id"
            >{{ sub.title }}</Button>
          </li>
        </ul>
      </template>

      <ul class="mt-6 flex flex-col gap-3" data-test="product-list">
        <li
          v-for="product in products"
          :key="product.id"
          class="flex items-center gap-4 rounded-2xl border bg-card p-4"
        >
          <div class="size-16 shrink-0 overflow-hidden rounded-xl bg-brand-mist">
            <AppImage v-if="product.images?.[0]" :src="product.images[0]" :alt="product.title" class="size-full object-cover" />
          </div>
          <div class="min-w-0 flex-1">
            <p class="truncate font-medium">{{ product.title }}</p>
            <p v-if="product.subtitle" class="truncate text-xs text-muted-foreground">{{ product.subtitle }}</p>
            <p class="mt-1 font-display font-black text-primary">{{ format(product.price) }}</p>
          </div>
          <Button
            type="button"
            size="icon"
            class="size-10 shrink-0 rounded-xl bg-brand-rust hover:bg-brand-rust/90"
            :aria-label="t('add_piece', 'Add', 'اضافة')"
            :data-add-product="product.id"
            @click="addProduct(product)"
          >
            <LucidePlus class="size-5" />
          </Button>
        </li>
      </ul>

      <!-- Pieces the caller made in an earlier session; always quantity 1. -->
      <section v-if="ownPieces?.pieces?.length" class="mt-10 rounded-3xl border bg-brand-mist/40 p-6">
        <h3 class="font-display text-xl font-semibold">{{ t('own_pieces_pick', 'Or paint a piece you made', 'أو لوّن قطعة صنعتها بنفسك') }}</h3>
        <p class="mt-1 text-sm text-muted-foreground">
          {{ t('own_pieces_each', ':price each', ':price للقطعة', { price: format(ownPieces.price) }) }}
        </p>
        <ul class="mt-4 flex flex-col gap-3">
          <li v-for="piece in ownPieces.pieces" :key="piece.id" class="flex items-center gap-4 rounded-2xl border bg-card p-4">
            <div class="size-16 shrink-0 overflow-hidden rounded-xl bg-brand-mist">
              <AppImage v-if="piece.images?.[0]" :src="piece.images[0]" :alt="piece.label ?? ''" class="size-full object-cover" />
            </div>
            <div class="min-w-0 flex-1">
              <p class="truncate font-medium">{{ piece.label ?? t('your_piece', 'Your piece', 'قطعتك') }}</p>
              <p v-if="piece.made_on" class="text-xs text-muted-foreground">{{ piece.made_on }}</p>
            </div>
            <Button
              type="button"
              size="icon"
              variant="outline"
              class="size-10 shrink-0 rounded-xl"
              :disabled="hasPiece(piece.id)"
              :aria-label="t('add_piece', 'Add', 'اضافة')"
              :data-add-piece="piece.id"
              @click="addOwnPiece(piece)"
            >
              <LucidePlus class="size-5" />
            </Button>
          </li>
        </ul>
      </section>
    </div>

    <!-- Selected pieces: the sheet in the frames, a panel on the web. -->
    <aside class="rounded-3xl border bg-card p-6">
      <h3 class="font-display text-lg font-semibold">
        {{ t('pieces_selected', 'Selected pieces :n', 'القطع المختارة :n', { n: totalQuantity }) }}
      </h3>

      <p v-if="!lines.length" class="mt-4 text-sm text-muted-foreground">
        {{ t('pieces_empty', 'Nothing chosen yet.', 'لم تختر أي قطعة بعد.') }}
      </p>

      <ul v-else class="mt-4 flex flex-col gap-3" data-test="selected-pieces">
        <li v-for="line in lines" :key="lineKey(line)" class="rounded-2xl border p-3">
          <div class="flex items-start gap-3">
            <div class="min-w-0 flex-1">
              <p class="truncate text-sm font-medium">{{ line.title }}</p>
              <p v-if="line.subtitle" class="truncate text-xs text-muted-foreground">{{ line.subtitle }}</p>
              <p class="mt-1 text-sm font-medium text-primary">{{ format(line.price) }}</p>
            </div>
            <Button type="button" size="icon" variant="ghost" class="size-10 rounded-lg text-destructive sm:size-8" :aria-label="t('remove', 'Remove', 'حذف')" @click="removeLine(line)">
              <LucideX class="size-4" />
            </Button>
          </div>

          <div v-if="line.workshop_product_id" class="mt-3 flex items-center gap-3">
            <Button type="button" size="icon" variant="outline" class="size-10 rounded-lg sm:size-8" :data-dec="line.workshop_product_id" @click="step(line, -1)">
              <LucideMinus class="size-4" />
            </Button>
            <span class="text-sm tabular-nums">{{ t('qty_n', 'Qty :n', 'عدد :n', { n: line.quantity }) }}</span>
            <Button type="button" size="icon" variant="outline" class="size-10 rounded-lg sm:size-8" :data-inc="line.workshop_product_id" :disabled="totalQuantity >= bounds.max" @click="step(line, 1)">
              <LucidePlus class="size-4" />
            </Button>
          </div>
        </li>
      </ul>

      <p v-if="boundsError" class="mt-4 text-xs text-destructive">{{ boundsError }}</p>
      <span v-if="fieldError(errors, 'products')" class="mt-2 block text-xs text-destructive">{{ fieldError(errors, 'products') }}</span>
    </aside>
  </div>
</template>

<script setup>
/**
 * Catalogue selection for `paint_your_piece` / `make_your_candle`: category → sub-category
 * → product, plus the caller's own unpainted pieces. Totals must land inside
 * `people_count × min/max_products_per_person`, so the bounds move with the party size.
 */
const props = defineProps({
  workshop: { type: Object, required: true },
  peopleCount: { type: Number, default: 1 },
  errors: { type: Object, default: () => ({}) },
})

const lines = defineModel({ type: Array, default: () => [] })

const { t } = useLang('web', 'bookings')
const { format } = usePrice()

const categories = computed(() => props.workshop.categories ?? [])
const ownPieces = computed(() => props.workshop.own_pieces ?? null)

const categoryId = ref(categories.value[0]?.id ?? null)
const category = computed(() => categories.value.find((c) => c.id === categoryId.value) ?? categories.value[0] ?? null)

const subId = ref(category.value?.sub_categories?.[0]?.id ?? null)
watch(category, (value) => { subId.value = value?.sub_categories?.[0]?.id ?? null })

const sub = computed(() => category.value?.sub_categories?.find((s) => s.id === subId.value) ?? category.value?.sub_categories?.[0] ?? null)
const products = computed(() => sub.value?.products ?? [])

const bounds = computed(() => catalogueBounds(props.workshop, props.peopleCount))
const totalQuantity = computed(() => lines.value.reduce((sum, line) => sum + (line.quantity ?? 1), 0))

const lineKey = (line) => (line.workshop_product_id ? `p${line.workshop_product_id}` : `o${line.workshop_booking_piece_id}`)
const hasPiece = (id) => lines.value.some((line) => line.workshop_booking_piece_id === id)

const boundsNote = computed(() => {
  const { min, max } = bounds.value
  return Number.isFinite(max)
    ? t('pieces_bounds', 'Choose between :min and :max pieces in total.', 'اختر ما بين :min و :max قطعة إجمالًا.', { min, max })
    : t('pieces_bounds_min', 'Choose at least :min piece(s).', 'اختر :min قطعة على الأقل.', { min })
})

const boundsError = computed(() => {
  const { min, max } = bounds.value
  if (totalQuantity.value && totalQuantity.value < min) return t('pieces_too_few', 'Add at least :min piece(s).', 'أضف :min قطعة على الأقل.', { min })
  if (totalQuantity.value > max) return t('pieces_too_many', 'You can choose at most :max piece(s).', 'يمكنك اختيار :max قطعة كحد أقصى.', { max })
  return ''
})

const addProduct = (product) => {
  if (totalQuantity.value >= bounds.value.max) return
  const existing = lines.value.find((line) => line.workshop_product_id === product.id)
  if (existing) {
    lines.value = lines.value.map((line) => (line === existing ? { ...line, quantity: line.quantity + 1 } : line))
    return
  }
  lines.value = [...lines.value, {
    workshop_product_id: product.id,
    quantity: 1,
    title: product.title,
    subtitle: product.subtitle,
    price: product.price,
  }]
}

const addOwnPiece = (piece) => {
  if (totalQuantity.value >= bounds.value.max || hasPiece(piece.id)) return
  lines.value = [...lines.value, {
    workshop_booking_piece_id: piece.id,
    quantity: 1,
    title: piece.label ?? t('your_piece', 'Your piece', 'قطعتك'),
    subtitle: null,
    price: ownPieces.value?.price ?? '0.00',
  }]
}

const step = (line, delta) => {
  const next = line.quantity + delta
  if (next < 1) { removeLine(line); return }
  if (delta > 0 && totalQuantity.value >= bounds.value.max) return
  lines.value = lines.value.map((candidate) => (lineKey(candidate) === lineKey(line) ? { ...candidate, quantity: next } : candidate))
}

const removeLine = (line) => { lines.value = lines.value.filter((candidate) => lineKey(candidate) !== lineKey(line)) }

// Shrinking the party can push the basket over the new maximum; the server would refuse it.
watch(() => props.peopleCount, () => {
  while (totalQuantity.value > bounds.value.max && lines.value.length) removeLine(lines.value[lines.value.length - 1])
})

defineExpose({ totalQuantity, bounds })
</script>
