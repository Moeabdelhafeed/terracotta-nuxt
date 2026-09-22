<template>
  <ConfigProvider :dir="dir">
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </ConfigProvider>
</template>

<script setup>
import { ConfigProvider } from 'reka-ui'

const { dir, code } = useLang()
const { url, name } = useSiteConfig()

/**
 * Site-wide head: the things every page inherits and then overrides where it has
 * something better to say. Icons are the brand mark on terracotta, so the tab reads at
 * 16px where the outline mark would disappear.
 */
useHead({
  titleTemplate: (title) => (title ? `${title} · ${name}` : name),
  link: [
    { rel: 'icon', href: '/favicon.ico', sizes: '32x32' },
    { rel: 'icon', type: 'image/png', href: '/icon-192.png', sizes: '192x192' },
    { rel: 'apple-touch-icon', href: '/icon-180.png', sizes: '180x180' },
    { rel: 'manifest', href: '/site.webmanifest' },
  ],
  meta: [
    { name: 'theme-color', content: '#6B2E19' },
    { name: 'format-detection', content: 'telephone=no' },
  ],
})

/**
 * Who the site belongs to, said once in a form search engines read. `sameAs` comes from
 * the CMS's social block, so adding an account in the admin adds it here — and the legal
 * identifiers are the same ones the footer is obliged to show.
 */
const { social, business } = useAppSettings()

useSchemaOrg([
  defineOrganization({
    name,
    url,
    logo: `${url}/icon-512.png`,
    sameAs: () => social.value.map((item) => item.url).filter(Boolean),
    // Functions, not values: app-settings resolves after this runs, and a spread would
    // freeze whatever was there at setup — which is nothing.
    vatID: () => business.value.vat_number ?? undefined,
    identifier: () => business.value.cr_number ?? undefined,
  }),
  defineWebSite({ name, url, inLanguage: () => code.value }),
  defineWebPage(),
])

/**
 * ONE card for the whole site, from dynamic storage.
 *
 * Every page used to share its own picture — the hero for a listing, the photograph for a
 * product — which meant the card a link showed was decided in a dozen files and could not
 * be changed without a deploy. This is the studio's own, editable in the Media CMS like
 * any other asset, and it seeds itself from `/og-default.png` the first time a page is
 * opened against a fresh backend.
 *
 * Absolute, always: a relative path is what the seed returns before the upload lands, and
 * a relative og:image is ignored by every scraper that reads it.
 */
const { media } = useMedia('web', 'seo')
const ogCard = () => {
  const src = media('og_card', '/og-default.png')
  return src?.startsWith('http') ? src : `${url}${src}`
}

// Defaults, not decisions: a page that sets its own title/description wins.
useSeoMeta({
  ogSiteName: name,
  ogType: 'website',
  twitterCard: 'summary_large_image',
  ogLocale: () => (code.value === 'ar' ? 'ar_SA' : 'en_US'),
  ogImage: ogCard,
  twitterImage: ogCard,
})
</script>
