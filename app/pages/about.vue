<template>
  <main>
    <PageHero
      media-key="hero_about"
      fallback="/seed/hero-about.webp"
      :crumbs="[
        { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
        { label: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }) },
      ]"
      :title="t('about_hero_title', 'About Terracotta', 'عن تيراكوتا')"
      :subtitle="t('about_hero_subtitle', 'A studio in Amman where clay is shaped by hand.', 'استوديو في عمّان يُشكَّل فيه الطين باليد.')"
    />

    <!-- Picture then copy. The mirrored section further down is the same block with the
         column order swapped, so the page reads as one rhythm rather than two designs. -->
    <section class="mx-auto max-w-6xl px-6 py-20 sm:py-24">
      <div class="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
        <div class="overflow-hidden bg-brand-mist">
          <AppMedia
            v-if="storyImage"
            :src="storyImage"
            :alt="t('about_story_title', 'How it started', 'كيف بدأت')"
            class="aspect-[4/3] w-full object-cover"
          />
        </div>

        <div>
          <p class="text-xs uppercase tracking-[0.25em] text-brand-rust/70">
            {{ t('about_story_eyebrow', 'Our story', 'قصتنا') }}
          </p>
          <h2 class="mt-5 font-display text-3xl font-semibold leading-tight sm:text-4xl">
            {{ t('about_story_title', 'How it started', 'كيف بدأت') }}
          </h2>
          <p class="mt-5 text-lg leading-relaxed text-muted-foreground">
            {{ t('about_story_body', 'One wheel, a small kiln and a room that smelled of wet clay. We opened the door to anyone who wanted to try, and the studio grew around the people who kept coming back.', 'دولاب واحد وفرن صغير وغرفة برائحة الطين المبلول. فتحنا الباب لكل من أراد التجربة، ونما الاستوديو حول من واظبوا على العودة.') }}
          </p>
        </div>
      </div>
    </section>

    <!-- The one dark band on the page: centred copy on terracotta, carrying the same line
         the hero and the footer are drawn with. -->
    <section class="relative isolate overflow-hidden bg-brand-terracotta text-white">
      <svg
        class="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white/15"
        viewBox="0 0 1601 922"
        fill="none"
        preserveAspectRatio="xMidYMid slice"
        aria-hidden="true"
      >
        <path
          d="M533.499 -308.5C561.499 -140.5 487.899 246.8 -30.5009 452C-678.501 708.5 240.999 -304.5 884.499 -146.5C1528 11.5 1738 466.5 1512 1153.5C1286 1840.5 349.5 489.5 -89.5 497.5"
          stroke="currentColor"
          stroke-width="2"
          vector-effect="non-scaling-stroke"
        />
      </svg>

      <div class="mx-auto max-w-3xl px-6 py-24 text-center sm:py-28">
        <h2 class="font-display text-3xl font-semibold leading-tight sm:text-5xl">
          {{ t('about_belief_title', 'Everyone can make something', 'كل شخص يستطيع أن يصنع شيئًا') }}
        </h2>
        <p class="mt-6 text-lg leading-relaxed text-white/80">
          {{ t('about_belief_body', 'You do not need talent, only an afternoon. The wheel does most of the arguing, and what you leave with is yours because you made it, not because you bought it.', 'لا تحتاج موهبة، تحتاج بعد ظهر واحد فقط. الدولاب يتكفّل بأغلب المكابرة، وما تخرج به لك لأنك صنعته، لا لأنك اشتريته.') }}
        </p>
      </div>
    </section>

    <!-- The mirror of the first block: copy first, picture second. -->
    <section class="mx-auto max-w-6xl px-6 py-20 sm:py-24">
      <div class="grid items-center gap-10 lg:grid-cols-2 lg:gap-16">
        <div class="lg:order-2">
          <div class="overflow-hidden bg-brand-mist">
            <AppMedia
              v-if="craftImage"
              :src="craftImage"
              :alt="t('about_craft_title', 'How we work', 'كيف نعمل')"
              class="aspect-[4/3] w-full object-cover"
            />
          </div>
        </div>

        <div class="lg:order-1">
          <p class="text-xs uppercase tracking-[0.25em] text-brand-rust/70">
            {{ t('about_craft_eyebrow', 'The craft', 'الحرفة') }}
          </p>
          <h2 class="mt-5 font-display text-3xl font-semibold leading-tight sm:text-4xl">
            {{ t('about_craft_title', 'How we work', 'كيف نعمل') }}
          </h2>
          <p class="mt-5 text-lg leading-relaxed text-muted-foreground">
            {{ t('about_craft_body', 'Every piece is thrown, dried, fired, glazed and fired again — a fortnight of waiting for an afternoon of work. Nothing leaves the studio that we would not keep ourselves.', 'كل قطعة تُشكَّل وتُجفَّف وتُحرق وتُطلى وتُحرق مجددًا — أسبوعان من الانتظار مقابل بعد ظهر من العمل. لا تخرج من الاستوديو قطعة ما كنا لنحتفظ بها لأنفسنا.') }}
          </p>
        </div>
      </div>
    </section>
  </main>
</template>

<script setup>
/**
 * The studio's own page, rather than a CMS entry: the copy is translated like the rest of
 * the site and the two pictures come from dynamic storage, so both are editable without a
 * deploy — but the layout is fixed, which a `content` blob could not give us.
 */
const { t } = useLang('web', 'home')
const { mediaAsset } = useMedia('web', 'about')

const storyImage = computed(() => mediaAsset('about_story', '/seed/about-1.webp'))
const craftImage = computed(() => mediaAsset('about_craft', '/seed/about-2.webp'))

const { media: heroMedia } = useMedia('web', 'heroes')

// A page with no picture of its own still gets a card, not a blank one.
const fallbackCard = `${useSiteConfig().url}/og-default.png`

useSeoMeta({
  title: () => t('about_hero_title', 'About Terracotta', 'عن تيراكوتا'),
  description: () => t('about_hero_subtitle', 'A studio in Amman where clay is shaped by hand.', 'استوديو في عمّان يُشكَّل فيه الطين باليد.'),
  ogImage: () => heroMedia('hero_about') ?? fallbackCard,
})

useSchemaOrg([
  defineBreadcrumb({
    itemListElement: [
      { name: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }), item: '/' },
      { name: t('nav_about', 'About', 'عن تيراكوتا', { subGroup: 'general' }), item: '/about' },
    ],
  }),
])
</script>
