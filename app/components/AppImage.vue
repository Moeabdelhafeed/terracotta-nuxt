<template>
  <img
    v-if="url"
    ref="img"
    :src="url"
    :alt="alt"
    :style="loaded ? undefined : placeholderStyle"
    @load="loaded = true"
    @error="loaded = true"
  />
</template>

<script setup>
/**
 * Backend Image object — `{ id, url, type, blurhash, image_api }` — rendered with its
 * blurhash behind it until the real file paints over. `image_api` is the public URL;
 * `url` is the stored path, so never bind that one. A plain URL string works too.
 *
 * Attributes (class, sizes, loading, …) fall through to the <img>.
 */
const props = defineProps({
  src: { type: [Object, String], default: null },
  alt: { type: String, default: '' },
})

const url = computed(() => (typeof props.src === 'string' ? props.src : props.src?.image_api ?? null))
const hash = computed(() => (typeof props.src === 'string' ? null : props.src?.blurhash ?? null))

const img = ref(null)
const loaded = ref(false)
const { placeholderStyle } = useBlurhash(hash)

// The <img> ships in the SSR HTML, so a cached file is usually decoded before Vue
// hydrates and its `load` event fires with no listener attached. Without this check
// the placeholder would sit behind the image forever — very visible on a logo with
// transparency, which is exactly where it showed up.
const syncLoaded = () => {
  if (img.value?.complete && img.value.naturalWidth > 0) loaded.value = true
}

onMounted(syncLoaded)

watch(url, async () => {
  loaded.value = false
  await nextTick()
  syncLoaded()
})
</script>
