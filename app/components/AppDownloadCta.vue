<template>
  <!-- Browsing happens here, doing happens in the app: this build has no booking or
       checkout, so every detail page ends by pointing at the stores. Rendered even with
       no badges configured — the sentence is the point, the badges are the shortcut. -->
  <section class="rounded-3xl border bg-brand-mist/50 p-6">
    <h2 class="font-display text-lg font-semibold">{{ title }}</h2>
    <p class="mt-2 text-sm text-muted-foreground">{{ note }}</p>

    <ul v-if="badges.length" class="mt-5 flex flex-wrap gap-3">
      <li v-for="badge in badges" :key="`${badge.block}-${badge.id}`">
        <a :href="badge.url" target="_blank" rel="noopener noreferrer" :title="badge.text">
          <AppImage
            v-if="badge.image?.image_api"
            :src="badge.image"
            :alt="badge.text"
            class="h-11 w-auto object-contain"
          />
          <span
            v-else
            class="inline-flex h-11 items-center rounded-xl border bg-card px-4 text-sm font-medium"
          >{{ badge.text }}</span>
        </a>
      </li>
    </ul>
  </section>
</template>

<script setup>
/**
 * The store call-to-action that closes a workshop or a product page.
 *
 * The wording differs by what the visitor was looking at — you book a workshop and you
 * buy a piece — so the copy comes from the caller; the badges are shared.
 */
defineProps({
  title: { type: String, required: true },
  note: { type: String, required: true },
})

const { appStore, googlePlay, appGallery } = useAppSettings()

const badges = computed(() => [
  ...appStore.value.map((item) => ({ ...item, block: 'app_store' })),
  ...googlePlay.value.map((item) => ({ ...item, block: 'google_play' })),
  ...appGallery.value.map((item) => ({ ...item, block: 'app_gallery' })),
])
</script>
