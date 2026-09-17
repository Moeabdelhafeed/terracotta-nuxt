<template>
  <main>
    <PageHero
      media-key="hero_workshops"
      fallback="/seed/hero-workshops.webp"
      :crumbs="[
        {
          to: '/',
          label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }),
        },
        {
          label: t('nav_workshops', 'Workshops', 'الورشات', {
            subGroup: 'general',
          }),
        },
      ]"
      :title="t('workshops_title', 'The workshop experience', 'تجربة الورشة')"
      :subtitle="
        t(
          'workshops_subtitle',
          'Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.',
          'جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو',
        )
      "
    />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <!-- Hub tabs (woLWX): browse the workshops, or jump to the bookings you already have. -->
      <ul class="mb-8 flex flex-wrap gap-2">
        <li>
          <Button
            size="sm"
            class="rounded-xl bg-brand-rust hover:bg-brand-rust/90"
            >{{ t("tab_book", "Book a workshop", "حجز ورشة") }}</Button
          >
        </li>
        <li>
          <Button as-child size="sm" variant="outline" class="rounded-xl">
            <NuxtLink to="/bookings">
              {{ t("tab_mine", "My workshops", "ورشاتي") }}
              <span
                v-if="activeCount"
                class="ms-2 rounded-full bg-brand-rust px-2 text-xs text-white"
                >{{ activeCount }}</span
              >
            </NuxtLink>
          </Button>
        </li>
      </ul>

      <ul
        v-if="pending"
        class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3"
        aria-busy="true"
      >
        <li
          v-for="n in 3"
          :key="n"
          class="overflow-hidden rounded-3xl border bg-card"
        >
          <AppSkeleton class="aspect-[4/3] w-full !rounded-none" />
          <div class="flex flex-col gap-3 p-6">
            <AppSkeleton class="h-6 w-2/3" />
            <AppSkeleton class="h-4 w-full" />
            <AppSkeleton class="h-4 w-4/5" />
            <div class="mt-4 flex gap-4">
              <AppSkeleton class="h-4 w-20" />
              <AppSkeleton class="h-4 w-20" />
            </div>
          </div>
        </li>
      </ul>

      <!-- A failed request and an empty catalogue are two different things, and neither is
           a page with nothing on it. -->
      <AppLoadError
        v-else-if="error"
        data-test="workshops-error"
        :error="error"
        :retry="refresh"
      />

      <p
        v-else-if="!workshops.length"
        class="rounded-card border border-dashed p-10 text-center text-sm text-muted-foreground"
        data-test="workshops-empty"
      >
        {{
          t(
            "workshops_empty",
            "No workshops are running just now. Check back soon.",
            "لا توجد ورشات متاحة حاليًا. تابعنا قريبًا.",
          )
        }}
      </p>

      <ul v-else class="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <li
          v-for="workshop in workshops"
          :key="workshop.id"
          class="group flex h-full flex-col overflow-hidden rounded-3xl border bg-card transition-colors hover:border-brand-rust"
        >
          <NuxtLink
            :to="`/workshops/${workshop.id}`"
            class="relative block aspect-[4/3] overflow-hidden bg-brand-mist"
          >
            <AppImage
              v-if="workshop.image?.image_api"
              :src="workshop.image"
              :alt="workshop.title"
              class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
            />
            <span
              class="absolute top-4 rounded-md px-3 py-1 text-xs font-medium text-white ltr:left-4 rtl:right-4"
              :style="{
                backgroundColor: workshop.color || 'var(--brand-terracotta)',
              }"
              >{{ typeLabel(workshop.type) }}</span
            >
          </NuxtLink>

          <div class="flex flex-1 flex-col gap-2 p-6">
            <NuxtLink
              :to="`/workshops/${workshop.id}`"
              class="font-display text-xl font-semibold"
              >{{ workshop.title }}</NuxtLink
            >
            <WorkshopAudienceBadge :audience="workshop.audience" />
            <p class="line-clamp-2 text-sm text-muted-foreground">
              {{ workshop.short_description }}
            </p>

            <!-- The three info tiles from the hub frames: price, seats per session, length. -->
            <dl
              class="mt-auto grid gap-2 pt-4 text-center text-xs sm:grid-cols-3"
            >
              <div class="rounded-2xl bg-brand-mist/60 p-3">
                <dd class="font-display text-sm font-semibold">
                  {{
                    isZeroMoney(workshop.price)
                      ? t("price_from_pieces", "By the pieces", "حسب القطع")
                      : t(
                          "price_per_person",
                          ":price per person",
                          ":price للشخص",
                          { price: format(workshop.price) },
                        )
                  }}
                </dd>
              </div>
              <div class="rounded-2xl bg-brand-mist/60 p-3">
                <dd class="font-display text-sm font-semibold">
                  {{
                    t(
                      "per_session_people",
                      ":n people per session",
                      ":n اشخاص بالجلسة",
                      { n: workshop.capacity_per_session },
                    )
                  }}
                </dd>
              </div>
              <div class="rounded-2xl bg-brand-mist/60 p-3">
                <dd class="font-display text-sm font-semibold">
                  {{
                    t("minutes", ":n min", ":n دقيقة", {
                      n: workshop.duration_minutes,
                    })
                  }}
                </dd>
              </div>
            </dl>

            <div class="mt-4 flex gap-2">
              <Button
                as-child
                class="h-12 flex-1 rounded-xl bg-brand-rust text-base hover:bg-brand-rust/90"
              >
                <NuxtLink :to="`/workshops/${workshop.id}/book`">{{
                  t("book_now", "Book", "احجز")
                }}</NuxtLink>
              </Button>
              <Button
                v-if="workshop.location_url"
                as-child
                variant="outline"
                class="h-12 flex-1 rounded-xl"
              >
                <a
                  :href="workshop.location_url"
                  target="_blank"
                  rel="noopener noreferrer"
                  >{{ t("the_location", "The location", "الموقع") }}</a
                >
              </Button>
            </div>
          </div>
        </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
const { workshops, pending, error, refresh } = useWorkshops();
const { t } = useLang("web", "home");
const { format } = usePrice();
const { activeCount } = useActiveBookingsCount();


const typeLabel = (type) =>
  ({
    make_your_piece: t("type_make_piece", "Make your piece", "اصنع قطعتك"),
    paint_your_piece: t("type_paint_piece", "Paint your piece", "لوّن قطعتك"),
    make_your_candle: t("type_make_candle", "Make your candle", "اصنع شمعتك"),
  })[type] ?? type;

const { media: heroMedia } = useMedia("web", "heroes");

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`;

useSeoMeta({
  title: () => t("workshops_title", "Workshops", "الورشات"),
  description: () =>
    t(
      "workshops_subtitle",
      "Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.",
      "جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو",
    ),
  ogImage: () => heroMedia("hero_workshops") ?? fallbackCard,
});

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      {
        name: t("nav_home", "Home", "الرئيسية", { subGroup: "general" }),
        item: "/",
      },
      {
        name: t("nav_workshops", "Workshops", "الورشات", {
          subGroup: "general",
        }),
        item: "/workshops",
      },
    ],
  }),
]);
</script>
