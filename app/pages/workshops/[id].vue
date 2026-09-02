<template>
  <main v-if="pending && !workshop" class="mx-auto max-w-6xl px-6 py-16" aria-busy="true">
    <div class="grid gap-10 lg:grid-cols-[1.4fr_1fr] lg:items-start">
      <div>
        <AppSkeleton class="aspect-[16/10] w-full !rounded-3xl" />
        <AppSkeleton class="mt-8 h-9 w-2/3" />
        <AppSkeleton class="mt-4 h-5 w-full" />
        <AppSkeleton class="mt-2 h-5 w-4/5" />
      </div>

      <div class="rounded-3xl border bg-card p-6">
        <AppSkeleton v-for="n in 4" :key="n" class="mb-4 h-16 !rounded-2xl last:mb-0" />
      </div>
    </div>
  </main>

  <main v-else-if="workshop">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="grid gap-10 lg:grid-cols-[1.4fr_1fr] lg:items-start">
        <div ref="content">
          <div class="relative aspect-[16/10] overflow-hidden rounded-3xl bg-brand-mist">
            <AppImage
              v-if="workshop.image?.image_api"
              :src="workshop.image"
              :alt="workshop.title"
              class="size-full object-cover"
            />
          </div>

          <h1 class="mt-8 font-display text-3xl font-semibold sm:text-4xl">{{ workshop.title }}</h1>
          <p class="mt-3 text-lg text-muted-foreground">{{ workshop.short_description }}</p>

          <div
            v-if="workshop.long_description"
            class="prose prose-sm mt-6 max-w-none dark:prose-invert [&_a]:text-primary [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
            v-html="workshop.long_description"
          />

          <section v-if="workshop.gallery?.length" class="mt-10">
            <h2 class="font-display text-xl font-semibold">
              {{ t('workshop_gallery', 'From this workshop', 'من هذه الورشة') }}
            </h2>
            <ul class="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
              <li v-for="(shot, index) in workshop.gallery" :key="index" class="overflow-hidden rounded-2xl border">
                <AppImage :src="shot" :alt="workshop.title" class="aspect-square w-full object-cover" />
              </li>
            </ul>
          </section>

          <!--
            Catalogue types (paint_your_piece, make_your_candle) carry the pieces a customer
            picks from at booking time, three levels deep: category -> sub-category ->
            product. The levels are the choice itself, so they are kept rather than flattened.
          -->
          <section v-if="workshop.categories?.length" class="mt-12">
            <h2 class="font-display text-2xl font-semibold">
              {{ t('workshop_catalogue', 'Pieces you can choose from', 'قطع يمكنك الاختيار منها') }}
            </h2>
            <p v-if="perPersonNote" class="mt-2 text-sm text-muted-foreground">{{ perPersonNote }}</p>

            <div v-for="category in workshop.categories" :key="category.id" class="mt-8">
              <h3 class="font-display text-lg font-semibold text-brand-rust">{{ category.title }}</h3>

              <div v-for="sub in category.sub_categories" :key="sub.id" class="mt-4">
                <p class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ sub.title }}</p>

                <ul class="mt-3 grid grid-cols-2 gap-4 sm:grid-cols-3">
                  <li v-for="piece in sub.products" :key="piece.id" class="overflow-hidden rounded-2xl border bg-card">
                    <div class="aspect-square bg-brand-mist">
                      <AppImage
                        v-if="piece.images?.[0]"
                        :src="piece.images[0]"
                        :alt="piece.title"
                        class="size-full object-cover"
                      />
                    </div>

                    <div class="p-3">
                      <p class="truncate text-sm font-medium">{{ piece.title }}</p>
                      <p v-if="piece.subtitle" class="truncate text-xs text-muted-foreground">{{ piece.subtitle }}</p>
                      <p class="mt-1 font-display font-black text-primary">{{ format(piece.price) }}</p>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </section>

          <!--
            Painting a piece you made yourself, offered next to the bisque catalogue. The API
            assembles it per caller, so it is empty for a guest and for anyone with no
            completed sessions — the block still explains the option in that case.
          -->
          <section v-if="ownPieces" class="mt-12 rounded-3xl border bg-brand-mist/40 p-6">
            <h2 class="font-display text-2xl font-semibold">
              {{ t('own_pieces_title', 'Or paint a piece you made', 'أو لوّن قطعة صنعتها بنفسك') }}
            </h2>
            <p class="mt-2 text-sm text-muted-foreground">
              {{ Number(ownPieces.price) > 0
                ? t('own_pieces_price', 'Bring back a piece from an earlier session — :price to paint it.', 'أحضر قطعة من جلسة سابقة — :price لتلوينها.', { price: format(ownPieces.price) })
                : t('own_pieces_free', 'Bring back a piece from an earlier session and paint it at no extra cost.', 'أحضر قطعة من جلسة سابقة ولوّنها دون تكلفة إضافية.') }}
            </p>

            <ul v-if="ownPieces.pieces?.length" class="mt-5 grid grid-cols-2 gap-4 sm:grid-cols-3">
              <li v-for="piece in ownPieces.pieces" :key="piece.id" class="overflow-hidden rounded-2xl border bg-card">
                <div class="aspect-square bg-brand-mist">
                  <AppImage
                    v-if="piece.images?.[0]"
                    :src="piece.images[0]"
                    :alt="piece.label ?? ''"
                    class="size-full object-cover"
                  />
                </div>

                <div class="p-3">
                  <p class="truncate text-sm font-medium">{{ piece.label ?? t('your_piece', 'Your piece', 'قطعتك') }}</p>
                  <p v-if="piece.made_on" class="text-xs text-muted-foreground">{{ piece.made_on }}</p>
                </div>
              </li>
            </ul>

            <p v-else class="mt-4 text-sm text-muted-foreground">
              {{ t('own_pieces_empty', 'Pieces from your finished sessions show up here.', 'ستظهر هنا القطع من جلساتك المكتملة.') }}
            </p>
          </section>
        </div>

        <!-- Stays in view while the catalogue below scrolls past: the price, the length of
             a session and the seat count are what a visitor keeps referring back to. -->
        <!-- Pinned rather than `position: sticky`: ScrollSmoother transforms
             #smooth-content, and a transformed ancestor makes sticky behave like static. -->
        <aside ref="aside">
          <div class="rounded-3xl border bg-card p-6">
            <dl class="grid gap-px overflow-hidden rounded-2xl bg-border">
              <div v-for="fact in facts" :key="fact.label" class="bg-card px-6 py-5">
                <dt class="text-xs uppercase tracking-[0.2em] text-muted-foreground">{{ fact.label }}</dt>
                <dd class="mt-1.5 font-display text-xl font-semibold">{{ fact.value }}</dd>
              </div>
            </dl>

            <Button
              v-if="workshop.location_url"
              as-child
              size="lg"
              variant="outline"
              class="mt-4 h-12 w-full rounded-xl"
            >
              <a :href="workshop.location_url" target="_blank" rel="noopener noreferrer">
                {{ t('get_directions', 'Get directions', 'الاتجاهات') }}
              </a>
            </Button>
          </div>

          <AppDownloadCta
            class="mt-4"
            :title="t('book_in_app_title', 'Book this workshop in the app', 'احجز هذه الورشة من التطبيق')"
            :note="t('book_in_app_note', 'Pick a date, choose your seats and pay in the Terracotta app — this site is for browsing.', 'اختر التاريخ والمقاعد وادفع عبر تطبيق تيراكوتا — هذا الموقع للتصفح فقط.')"
          />
        </aside>
      </div>
    </div>
  </main>
</template>

<script setup>
const route = useRoute()
const { workshop, pending, error } = useWorkshop(() => route.params.id)

// A record that does not exist, or a lookup that failed, hands over to the site's error
// page — the markup's `v-if` would otherwise match nothing and leave a blank screen.
watchEffect(() => {
  if (!pending.value && (error.value || !workshop.value)) {
    showError({ statusCode: error.value?.statusCode ?? 404, statusMessage: 'Workshop not found' })
  }
})
const { t } = useLang('web', 'home')
const { format } = usePrice()

const content = ref(null)
const aside = ref(null)

useStickyAside(aside, content, workshop)

const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/workshops', label: t('nav_workshops', 'Workshops', 'الورشات', { subGroup: 'general' }) },
  { label: workshop.value?.title ?? '' },
])

// Null for make_your_piece and make_your_candle — there is nothing to paint onto.
const ownPieces = computed(() => workshop.value?.own_pieces ?? null)

// How many catalogue pieces each person may take, when the workshop bounds it.
const perPersonNote = computed(() => {
  const min = workshop.value?.min_products_per_person
  const max = workshop.value?.max_products_per_person
  if (!min && !max) return ''

  if (min && max && min !== max) {
    return t('pieces_range', ':min to :max pieces per person.', 'من :min إلى :max قطعة للشخص.', { min, max })
  }

  return t('pieces_count', ':n pieces per person.', ':n قطعة للشخص.', { n: max ?? min })
})

const facts = computed(() => {
  const w = workshop.value
  if (!w) return []

  const rows = [
    { label: t('fact_duration', 'A session', 'الجلسة'), value: t('minutes', ':n min', ':n دقيقة', { n: w.duration_minutes }) },
    { label: t('fact_seats', 'Seats', 'المقاعد'), value: t('per_session', ':n per session', ':n لكل جلسة', { n: w.capacity_per_session }) },
    { label: t('fact_group', 'Group size', 'حجم المجموعة'), value: t('up_to_people', 'up to :n', 'حتى :n', { n: w.max_people_per_booking }) },
  ]

  if (Number(w.price) > 0) {
    rows.unshift({ label: t('fact_price', 'From', 'ابتداءً من'), value: format(w.price) })
  }

  return rows
})

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => workshop.value?.title ?? '',
  description: () => workshop.value?.short_description ?? '',
  ogImage: () => workshop.value?.image?.image_api ?? fallbackCard,
})

// A workshop is something offered rather than something sold off a shelf, so Service
// rather than Product — the price is the seat, and the studio is the provider.
useSchemaOrg([
  defineProduct({
    '@type': 'Service',
    name: () => workshop.value?.title ?? '',
    description: () => workshop.value?.short_description ?? '',
    image: () => workshop.value?.image?.image_api,
    offers: () => (Number(workshop.value?.price) > 0
      ? [{ price: Number(workshop.value.price), priceCurrency: 'SAR', availability: 'https://schema.org/InStock' }]
      : []),
  }),
  defineBreadcrumb({
    itemListElement: () => crumbs.value.map((crumb) => ({ name: crumb.label, item: crumb.to })),
  }),
])
</script>
