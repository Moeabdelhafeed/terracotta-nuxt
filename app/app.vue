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

// Defaults, not decisions: a page that sets its own title/description/image wins.
useSeoMeta({
  ogSiteName: name,
  ogType: 'website',
  twitterCard: 'summary_large_image',
  ogLocale: () => (code.value === 'ar' ? 'ar_SA' : 'en_US'),
  ogImage: `${url}/og-default.png`,
  twitterImage: `${url}/og-default.png`,
})
</script>
