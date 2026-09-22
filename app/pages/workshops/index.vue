<template>
  <main class="bg-background">
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
      <!-- What the reader has to spend, and the way to give somebody else some. The app
           carries this pair on its own workshops header. -->
      <GiftWalletGiftRow class="mb-8" />

      <WorkshopHubTabs class="mb-8" />

      <!-- The same grid the real list uses, so nothing moves when it resolves. -->
      <ul
        v-if="pending && !workshops.length"
        class="grid auto-rows-fr gap-4 sm:grid-cols-2"
        aria-busy="true"
      >
        <li v-for="n in 4" :key="n"><WorkshopCardSkeleton /></li>
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
        class="mx-auto max-w-xl rounded-card border border-dashed p-10 text-center text-sm text-muted-foreground"
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

      <!--
        The app's workshop card: a band painted in the workshop's own colour with white
        type, the words running from the reading start and the picture in a well at the
        end. The colour carries the family, so the card needs no type chip to say it.
      -->
      <ul v-else class="grid auto-rows-fr gap-4 sm:grid-cols-2">
        <li v-for="workshop in workshops" :key="workshop.id">
          <NuxtLink
            :to="`/workshops/${workshop.id}`"
            class="flex h-full min-h-[110px] overflow-hidden rounded-control p-1 transition-[transform,box-shadow,opacity] duration-200 hover:-translate-y-0.5 hover:opacity-95 hover:shadow-md active:translate-y-0"
            :style="{ backgroundColor: workshopColour(workshop) }"
          >
            <div class="flex min-w-0 flex-1 flex-col gap-1 pb-4 pe-2 ps-4 pt-4 text-white">
              <h3 class="font-display text-xl font-semibold leading-snug">
                {{ workshop.title }}
              </h3>

              <WorkshopAudienceBadge :audience="workshop.audience" on-color />

              <p class="line-clamp-3 text-xs leading-relaxed text-white/85">
                {{ workshop.short_description }}
              </p>

              <p class="mt-auto pt-2 font-display text-xl font-black text-white">
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
              </p>
            </div>

            <!-- A photograph is not line work: it fills the well, with no wash over it.
                 Without one the well is the card's own ink, as the app draws it. -->
            <div class="w-[101px] shrink-0 self-stretch overflow-hidden rounded-[6px]">
              <!-- A photograph is not line work: it fills the well untouched. The family's
                   drawing is black art on a wash of the card's own ink, inverted to white
                   the way the app recolours it. -->
              <AppImage
                v-if="workshop.image?.image_api"
                :src="workshop.image"
                :alt="workshop.title"
                class="size-full object-cover"
              />
              <div v-else class="size-full bg-white/45">
                <img
                  v-if="artFor(workshop)"
                  :src="artFor(workshop)"
                  alt=""
                  class="size-full object-cover opacity-90 [filter:brightness(0)_invert(1)]"
                />
              </div>
            </div>
          </NuxtLink>
        </li>
      </ul>
    </div>
  </main>
</template>

<script setup>
const { workshops, pending, error, refresh } = useWorkshops();
const { artFor } = useWorkshopArt();
const { t } = useLang("web", "home");
const { format } = usePrice();



useSeoMeta({
  title: () => t("workshops_title", "Workshops", "الورشات"),
  description: () =>
    t(
      "workshops_subtitle",
      "Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.",
      "جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو",
    ),
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
