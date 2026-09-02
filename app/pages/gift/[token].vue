<template>
  <!--
    The link always lands here, never in the app: no Universal/App Link association is
    served for this path on purpose, so the OS hands the URL to the browser and the
    recipient sees the gift — often their first sight of Terracotta at all. Opening the
    app is a button they press, not something that happens to them.
  -->
  <div>
    <!-- Opened by hand: the gift is behind it, and tapping the mark is the opening of it. -->
    <AppCurtain
      :label="t('gift_open', 'Tap to open your gift', 'اضغط لفتح هديتك')"
      color="#F07272"
      @opened="celebrate = true"
    />

    <!-- Only once the wrapper is off, and only for a gift there is still something to
         celebrate about — paper over "already claimed" would be a joke at the reader's
         expense. -->
    <AppConfetti v-if="celebrate && gift?.is_claimable" @done="celebrate = false" />

  <main ref="root" class="relative isolate flex min-h-svh flex-col items-center justify-center overflow-hidden bg-[#FC8B8B] px-6 py-16 text-white">
    <!-- The line the rest of the site is drawn with. Decorative only. -->
    <svg
      class="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white/40"
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

    <AppMedia v-if="logo" ref="mark" :src="logo" alt="" class="h-14 w-auto object-contain sm:h-16" />

    <div ref="card" class="mt-8 w-full max-w-md rounded-[2rem] bg-background p-8 text-center text-foreground shadow-2xl sm:p-10">
      <!-- The gift itself. Shown whether or not it can still be claimed: the buyer may be
           checking it landed, or the recipient re-opening their own link. -->
      <template v-if="gift">
        <p class="text-sm text-muted-foreground">
          {{ gift.from
            ? t('gift_from', ':name sent you a gift', ':name أرسل لك هدية', { name: gift.from })
            : t('gift_from_someone', 'You have been sent a gift', 'وصلتك هدية') }}
        </p>

        <p class="mt-4 font-display text-5xl font-black leading-none text-[#FC8B8B]">
          {{ format(gift.amount) }}
        </p>

        <!-- The buyer's own words, rendered as written — never translated. -->
        <p v-if="gift.message" class="mt-6 text-lg leading-relaxed">“{{ gift.message }}”</p>

        <p v-if="gift.recipient_name" class="mt-4 text-sm text-muted-foreground">
          {{ t('gift_to', 'For :name', 'إلى :name', { name: gift.recipient_name }) }}
        </p>

        <div class="my-8 h-px bg-border" />

        <!-- Claimed: say so plainly and drop the buttons. Who claimed it is not in the
             response, deliberately. -->
        <p
          v-if="!gift.is_claimable"
          class="rounded-2xl bg-brand-mist px-4 py-4 text-sm font-medium text-brand-rust"
        >
          {{ t('gift_claimed', 'This gift has already been claimed.', 'تم استلام هذه الهدية بالفعل.') }}
        </p>

        <template v-else>
          <!--
            Points at the store, not at `deep_link`: the app does not handle the scheme
            yet, and a button that opens an error dialog is worse than one that installs
            the thing it needs. Swap `redeemHref` back to the deep link once it works.
          -->
          <Button
            v-if="redeemHref"
            as-child
            size="lg"
            class="h-14 w-full rounded-2xl bg-[#FC8B8B] text-base text-white hover:bg-[#fb7a7a]"
          >
            <a :href="redeemHref" target="_blank" rel="noopener noreferrer">
              {{ t('gift_redeem', 'Redeem your gift', 'استرد هديتك') }}
            </a>
          </Button>

          <div v-if="gift.store_links?.length" class="mt-6">
            <p class="text-xs text-muted-foreground">
              {{ t('gift_get_app', 'Do not have the app yet?', 'ليس لديك التطبيق بعد؟') }}
            </p>
            <ul class="mt-3 flex flex-wrap items-center justify-center gap-3">
              <li v-for="link in gift.store_links" :key="link.type">
                <a
                  :href="link.url"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="inline-flex h-11 items-center rounded-xl border px-4 text-sm font-medium transition-colors hover:bg-brand-mist"
                >{{ storeLabel(link.type) }}</a>
              </li>
            </ul>
          </div>
        </template>
      </template>

      <!-- An unknown token, or a gift the buyer never paid for. The API does not tell the
           two apart, and neither does this. -->
      <template v-else-if="notFound">
        <h1 class="font-display text-2xl font-semibold">
          {{ t('gift_invalid_title', "This gift link isn't valid", 'رابط الهدية غير صالح') }}
        </h1>
        <p class="mt-3 text-sm text-muted-foreground">
          {{ t('gift_invalid_body', 'Check the link you were sent, or ask whoever sent it.', 'تأكد من الرابط الذي وصلك، أو اسأل من أرسله.') }}
        </p>
      </template>

      <!-- Never an empty gift shell: "you have been sent 0.00" reads worse than an error. -->
      <template v-else>
        <h1 class="font-display text-2xl font-semibold">
          {{ t('gift_error_title', 'We could not open this gift', 'تعذّر فتح الهدية') }}
        </h1>
        <p class="mt-3 text-sm text-muted-foreground">
          {{ t('gift_error_body', 'Something went wrong on our side. Try again in a moment.', 'حدث خطأ لدينا. حاول مرة أخرى بعد قليل.') }}
        </p>
        <Button variant="outline" class="mt-6 h-12 rounded-xl px-8" @click="refresh()">
          {{ t('try_again', 'Try again', 'حاول مرة أخرى') }}
        </Button>
      </template>
    </div>

    <NuxtLink to="/" class="mt-8 text-sm text-white/80 underline-offset-4 transition-colors hover:text-white hover:underline">
      {{ t('gift_explore', 'See what Terracotta makes', 'تعرّف على تيراكوتا') }}
    </NuxtLink>
  </main>
  </div>
</template>

<script setup>
definePageMeta({
  // No site chrome: the recipient followed a link to one thing.
  layout: 'bare',
})

// The gift page has a ground of its own, unlike the rest of the site. Set on the body too
// so an overscroll bounce does not flash white behind it.
useHead({ bodyAttrs: { class: 'bg-[#FC8B8B]' } })

const route = useRoute()
const { t } = useLang('web', 'home')
const { format } = usePrice()
const { mediaAsset } = useMedia('web', 'branding')

// Everything sitting directly on the pink is white, the mark included.
const logo = computed(() => mediaAsset('logo_light', '/logo-light.png'))

/**
 * Server-rendered on purpose: WhatsApp and iMessage fetch the link to build a preview
 * card and run no JavaScript. The call goes to our own server route, which holds the API
 * token — see server/api/gift/[token].get.js.
 */
const { data: gift, error, refresh } = await useFetch(() => `/api/gift/${route.params.token}`, {
  key: () => `gift-${route.params.token}`,
})

const notFound = computed(() => error.value?.statusCode === 404)

/**
 * Where "redeem" sends someone. The gift is claimed in the app, so on a phone that means
 * the right store for that phone; anywhere else, whichever store the CMS lists first.
 *
 * `deep_link` is deliberately unused for now — the app does not register the scheme yet,
 * so tapping it would raise "cannot open page" and the recipient would be stuck.
 */
const { platform } = useDevice()

const redeemHref = computed(() => {
  const links = gift.value?.store_links ?? []
  const wanted = { ios: 'app_store', android: 'google_play' }[platform.value]

  return (wanted && links.find((link) => link.type === wanted)?.url) ?? links[0]?.url ?? null
})

const storeLabel = (type) => ({
  app_store: t('app_store', 'App Store', 'آب ستور'),
  google_play: t('google_play', 'Google Play', 'جوجل بلاي'),
  app_gallery: t('app_gallery', 'AppGallery', 'آب جاليري'),
}[type] ?? type)

const celebrate = ref(false)

const root = ref(null)
const mark = ref(null)
const card = ref(null)

onMounted(() => {
  const gsap = useGSAP()
  const mm = gsap.matchMedia()

  // The card arrives rather than appearing — the one flourish the page gets, and only for
  // visitors who have not asked for less motion.
  mm.add('(prefers-reduced-motion: no-preference)', () => {
    gsap.from([mark.value?.$el ?? mark.value, card.value], {
      opacity: 0,
      y: 28,
      scale: 0.97,
      duration: 0.7,
      stagger: 0.12,
      ease: 'power2.out',
    })
  })

  onBeforeUnmount(() => mm.revert())
})

/**
 * The token is the entitlement — whoever holds it can claim the gift — and previews get
 * screenshotted and forwarded, so it appears in no tag. A claimed or dead link previews
 * generically rather than as a live offer, and the page is never indexed.
 */
const previewTitle = computed(() => {
  if (!gift.value?.is_claimable) return t('gift_generic_title', 'A gift from Terracotta', 'هدية من تيراكوتا')

  return gift.value.from
    ? t('gift_from', ':name sent you a gift', ':name أرسل لك هدية', { name: gift.value.from })
    : t('gift_from_someone', 'You have been sent a gift', 'وصلتك هدية')
})

const previewDescription = computed(() => (gift.value?.is_claimable
  ? t('gift_og_description', 'A :amount gift from Terracotta', 'هدية بقيمة :amount من تيراكوتا', { amount: format(gift.value.amount) })
  : t('gift_og_generic', 'Handmade pottery, workshops and pieces from our studio.', 'فخار مصنوع يدويًا، ورشات وقطع من الاستوديو.')))

/**
 * The card WhatsApp and iMessage draw when the link is pasted. They fetch the page with no
 * JavaScript, which is why it is server-rendered, and they want an absolute image URL with
 * its dimensions declared — without those the preview falls back to a small thumbnail.
 *
 * The card itself is generic: previews get screenshotted and forwarded, and possession of
 * the token is the entitlement, so it never appears in a tag.
 */
const previewCard = `${useSiteConfig().url}/og-gift.png`

useSeoMeta({
  robots: 'noindex, nofollow',
  title: () => previewTitle.value,
  ogTitle: () => previewTitle.value,
  description: () => previewDescription.value,
  ogDescription: () => previewDescription.value,
  ogType: 'website',
  ogImage: previewCard,
  ogImageSecureUrl: previewCard,
  ogImageType: 'image/png',
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageAlt: () => previewTitle.value,
  twitterCard: 'summary_large_image',
  twitterImage: previewCard,
  twitterTitle: () => previewTitle.value,
  twitterDescription: () => previewDescription.value,
})
</script>
