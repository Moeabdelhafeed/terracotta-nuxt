<template>
  <!--
    Motion note: the fade lives in the binding value (opacity: 0), not in the
    `fromInvisible` modifier. That modifier ships `opacity: 0` as plain SSR CSS, so a
    failed trigger — no JS, an error, a crawler — would leave the section invisible for
    good. Passing it to GSAP instead means the content renders visible and only animates
    when the script actually runs.
  -->
  <section
    id="workshops"
    v-if="workshops.length"
    class="mx-auto max-w-6xl px-6 py-24"
  >
    <header class="mb-12 flex flex-wrap items-end justify-between gap-4">
      <div class="max-w-xl">
        <h2 class="font-display text-3xl font-semibold sm:text-4xl lg:text-5xl">
          {{ t("workshops_title", "The workshop experience", "تجربة الورشة") }}
        </h2>
        <p class="mt-3 text-muted-foreground">
          {{
            t(
              "workshops_subtitle",
              "Hands-on sessions with an instructor — shape or paint your piece step by step in the studio.",
              "جلسات عملية بإشراف مدرّبين تصنع أو تلوّن قطعتك خطوة بخطوة داخل الاستوديو",
            )
          }}
        </p>
      </div>
      <NuxtLink
        to="/workshops"
        class="text-sm font-medium text-primary underline-offset-4 hover:underline"
      >
        {{ t("view_all", "View all", "عرض الكل") }}
      </NuxtLink>
    </header>

    <ul
      v-gsap.whenVisible.once.from.stagger="{
        opacity: 0,
        y: 48,
        duration: 0.7,
      }"
      class="grid auto-rows-fr gap-4 sm:grid-cols-2"
    >
      <li v-for="workshop in workshops" :key="workshop.id">
        <!-- The app's card, as on the workshops page: a band in the workshop's own
             colour, words from the reading start, picture in a well at the end. -->
        <NuxtLink
          :to="`/workshops/${workshop.id}`"
          class="flex h-full min-h-[110px] overflow-hidden rounded-control p-1 transition-opacity hover:opacity-95"
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
                  : t("price_per_person", ":price per person", ":price للشخص", {
                      price: format(workshop.price),
                    })
              }}
            </p>
          </div>

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
  </section>
</template>

<script setup>
const { workshops } = useWorkshops();
const { artFor } = useWorkshopArt();
const { t } = useLang("web", "home");
const { format } = usePrice();
</script>
