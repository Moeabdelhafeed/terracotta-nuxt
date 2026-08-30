<template>
  <AppImage
    v-if="type === 'image'"
    :src="asset"
    :alt="alt"
  />

  <video
    v-else-if="type === 'video'"
    :src="url"
    :poster="poster ?? undefined"
    :style="started ? undefined : placeholderStyle"
    :controls="controls"
    playsinline
    preload="metadata"
    @loadeddata="started = true"
    @playing="started = true"
  />

  <a
    v-else-if="url"
    :href="url"
    target="_blank"
    rel="noopener noreferrer"
  >{{ asset?.name || alt || url.split('/').pop() }}</a>
</template>

<script setup>
/**
 * A typed backend asset — `{ type, image|video|file }`, as `/api/media` items and gallery
 * items return — rendered by its `type`:
 *   image → <AppImage> (blurhash placeholder)
 *   video → <video> postered with the thumbnail, its blurhash behind it until playback starts
 *   file  → a link labelled with the stored name
 *
 * The nested morph is the canonical model shape: an Image is `{ id, url, type, blurhash,
 * image_api }`, a Video is the same plus `video_api` and a `thumbnail` that is itself an
 * Image. A bare Image object (or URL string) is accepted too, and treated as an image.
 *
 * Attributes (class, controls, autoplay, …) fall through to the rendered element.
 */
const props = defineProps({
  src: { type: [Object, String], default: null },
  alt: { type: String, default: '' },
  /** Off for decorative/background video, where a control bar would be noise. */
  controls: { type: Boolean, default: true },
})

const type = computed(() => (typeof props.src === 'string' ? 'image' : props.src?.type ?? 'image'))

// `{ type, image|video|file }` wrappers carry the asset under their type key; a bare
// Image object (app-settings, pages, languages) is already the asset.
const asset = computed(() => {
  if (typeof props.src === 'string') return { image_api: props.src }
  return props.src?.[type.value] ?? props.src
})

const url = computed(() => asset.value?.image_api ?? asset.value?.video_api ?? asset.value?.file_api ?? null)
const poster = computed(() => asset.value?.thumbnail?.image_api ?? null)

// The thumbnail's own hash when there is one, else the asset's.
const hash = computed(() => asset.value?.thumbnail?.blurhash ?? asset.value?.blurhash ?? null)
const { placeholderStyle } = useBlurhash(hash)

const started = ref(false)
watch(url, () => { started.value = false })
</script>
