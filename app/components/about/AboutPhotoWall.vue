<template>
  <div v-if="photos.length">
    <!-- The gallery's own wall: staggered heights, hairline gaps, each photo opening full
         screen. -->
    <ul class="columns-2 gap-1.5 lg:columns-3 [&>li]:mb-1.5">
      <li v-for="(photo, index) in photos" :key="photo.id ?? index" class="break-inside-avoid bg-brand-mist">
        <button
          type="button"
          class="block w-full cursor-zoom-in"
          :aria-label="t('album_open_photo', 'Open photograph :n', 'افتح الصورة :n', { n: index + 1 })"
          data-test="about-photo"
          @click="viewing = index"
        >
          <AppImage :src="photo" :alt="alt" class="w-full object-cover" :class="RATIOS[index % RATIOS.length]" />
        </button>
      </li>
    </ul>

    <AppLightbox v-model="viewing" :items="photos" :alt="alt" />
  </div>
</template>

<script setup>
/** A project's or an event's photographs, laid out like a gallery album. */
defineProps({
  photos: { type: Array, default: () => [] },
  alt: { type: String, default: "" },
});

const { t } = useLang("web", "home");
const viewing = ref(null);

const RATIOS = ["aspect-square", "aspect-[6/7]", "aspect-[3/4]", "aspect-[7/6]"];
</script>
