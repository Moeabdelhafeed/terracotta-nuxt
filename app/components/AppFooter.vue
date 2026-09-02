<template>
  <footer class="relative isolate mt-auto overflow-hidden bg-brand-terracotta text-white">
    <!-- The hero's line, carried through to the close of the page. Decorative only. -->
    <svg
      class="pointer-events-none absolute inset-0 -z-10 h-full w-full text-white/20"
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

    <div class="mx-auto max-w-6xl px-6 py-20">
      <div class="flex flex-col gap-12 lg:flex-row lg:items-start lg:justify-between">
        <div class="max-w-sm">
          <!-- AppMedia, not AppImage: `mediaAsset` hands back the `{ type, image }`
               wrapper (or the /public fallback path), which only AppMedia unwraps. -->
          <AppMedia
            v-if="logo"
            :src="logo"
            alt=""
            class="h-12 w-auto object-contain"
          />
          <p class="mt-5 text-lg leading-relaxed text-white/80">
            {{ t('footer_tagline', 'Baked earth, shaped by hand — workshops and pieces from our studio.', 'طين مشوي يُشكّل باليد — ورشات وقطع من الاستوديو.') }}
          </p>
        </div>

        <div class="grid flex-1 gap-10 sm:grid-cols-3 lg:max-w-2xl">
          <!-- The site's own sections, the same set the bottom bar navigates. The CMS
               pages are legal copy, so they sit in the bottom row instead. -->
          <nav class="flex flex-col gap-3">
            <h2 class="text-xs uppercase tracking-[0.2em] text-white/50">
              {{ t('footer_pages', 'Pages', 'الصفحات') }}
            </h2>
            <NuxtLink
              v-for="item in sections"
              :key="item.to"
              :to="item.to"
              class="text-sm text-white/85 transition-colors hover:text-white"
            >{{ item.label }}</NuxtLink>
          </nav>

          <div v-if="contact.length" class="flex flex-col gap-3">
            <h2 class="text-xs uppercase tracking-[0.2em] text-white/50">
              {{ t('footer_contact', 'Contact', 'تواصل') }}
            </h2>
            <a
              v-for="item in contact"
              :key="item.id"
              :href="item.url"
              class="flex items-center gap-2 text-sm text-white/85 transition-colors hover:text-white"
            >
              <AppImage
                v-if="item.image?.image_api"
                :src="item.image"
                :alt="item.text"
                class="size-4 shrink-0 object-contain"
              />
              {{ item.text }}
            </a>
          </div>

          <div v-if="social.length || storeBadges.length" class="flex flex-col gap-3">
            <h2 class="text-xs uppercase tracking-[0.2em] text-white/50">
              {{ t('footer_follow', 'Follow', 'تابعنا') }}
            </h2>

            <ul v-if="social.length" class="flex flex-wrap gap-2">
              <li v-for="item in social" :key="item.id">
                <a
                  :href="item.url"
                  target="_blank"
                  rel="noopener noreferrer"
                  :title="item.text"
                  class="flex size-10 items-center justify-center rounded-full border border-white/25 transition-colors hover:bg-white/15"
                >
                  <AppImage
                    v-if="item.image?.image_api"
                    :src="item.image"
                    :alt="item.text"
                    class="size-4 object-contain"
                  />
                  <span v-else class="text-xs font-medium">{{ initial(item.text) }}</span>
                </a>
              </li>
            </ul>

            <ul v-if="storeBadges.length" class="mt-2 flex flex-wrap gap-2">
              <li v-for="item in storeBadges" :key="`${item.block}-${item.id}`">
                <a :href="item.url" target="_blank" rel="noopener noreferrer" :title="item.text">
                  <AppImage
                    v-if="item.image?.image_api"
                    :src="item.image"
                    :alt="item.text"
                    class="h-10 object-contain"
                  />
                  <span
                    v-else
                    class="inline-flex h-10 items-center rounded-md border border-white/25 px-3 text-sm"
                  >{{ item.text }}</span>
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>

      <!-- Saudi law requires a storefront trading there to display its commercial
           registration and VAT numbers. The API omits whichever is not configured, so
           outside Saudi — or before the business is registered — the row does not exist. -->
      <div v-if="registration.length" class="mt-16 flex flex-wrap gap-3 border-t border-white/15 pt-8">
        <component
          :is="entry.url ? 'a' : 'div'"
          v-for="entry in registration"
          :key="entry.label"
          :href="entry.url || undefined"
          :target="entry.url ? '_blank' : undefined"
          :rel="entry.url ? 'noopener noreferrer' : undefined"
          class="flex items-center gap-3.5 rounded-xl bg-white/10 py-2.5 pe-5 ps-3.5 transition-colors"
          :class="entry.url ? 'hover:bg-white/20' : ''"
        >
          <img :src="entry.icon" :alt="entry.label" draggable="false" class="h-12 w-auto shrink-0 object-contain" />
          <span class="flex min-w-0 flex-col gap-0.5">
            <span class="text-[11px] uppercase leading-none text-white/50">{{ entry.label }}</span>
            <span class="text-sm font-semibold leading-tight text-white" dir="ltr">{{ entry.value }}</span>
          </span>
        </component>
      </div>

      <div class="mt-10 flex flex-col gap-3 border-t border-white/15 pt-6 text-sm text-white/60 sm:flex-row sm:items-center sm:justify-between">
        <p>&copy; {{ year }} {{ t('brand_name', 'Terracotta', 'تيراكوتا') }}</p>

        <!-- Terms, privacy and the rest: CMS pages, kept close to the copyright line
             where legal copy is looked for. -->
        <nav v-if="pages.length" class="flex flex-wrap gap-x-4 gap-y-1">
          <NuxtLink
            v-for="page in pages"
            :key="page.id"
            :to="`/${page.slug}`"
            class="underline-offset-4 transition-colors hover:text-white hover:underline"
          >{{ page.name }}</NuxtLink>
        </nav>

        <p>{{ t('footer_made', 'Handmade in Amman', 'مصنوع يدويًا في عمّان') }}</p>
      </div>
    </div>
  </footer>
</template>

<script setup>
const { social, contact, appStore, googlePlay, appGallery, business } = useAppSettings()

// The commercial-registration entry carries the Business Center link when the CMS has one,
// since that is the page the number is verified on.
const registration = computed(() => [
  business.value.cr_number && {
    label: t('footer_cr_number', 'Commercial registration', 'السجل التجاري'),
    value: business.value.cr_number,
    url: business.value.business_center_url,
    icon: '/reg.png',
  },
  business.value.vat_number && {
    label: t('footer_vat_number', 'VAT number', 'الرقم الضريبي'),
    value: business.value.vat_number,
    url: null,
    icon: '/vat.png',
  },
].filter(Boolean))

const { pages } = usePages()
const { mediaAsset } = useMedia('web', 'branding')
const { t } = useLang('web', 'general')

// Same destinations, and the same translation keys, as the floating bottom bar.
const sections = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية') },
  { to: '/workshops', label: t('nav_workshops', 'Workshops', 'الورشات') },
  { to: '/shop', label: t('nav_shop', 'Shop', 'المتجر') },
  { to: '/gallery', label: t('nav_gallery', 'Gallery', 'المعرض') },
  { to: '/about', label: t('nav_about', 'About', 'عن تيراكوتا') },
])

const storeBadges = computed(() => [
  ...appStore.value.map((i) => ({ ...i, block: 'app_store' })),
  ...googlePlay.value.map((i) => ({ ...i, block: 'google_play' })),
  ...appGallery.value.map((i) => ({ ...i, block: 'app_gallery' })),
])

// The footer sits on terracotta, so it takes the light mark rather than the default one.
const logo = computed(() => mediaAsset('logo_light', '/logo-light.png'))
const year = new Date().getFullYear()

const initial = (text) => (text?.trim()?.[0] ?? '?').toUpperCase()
</script>
