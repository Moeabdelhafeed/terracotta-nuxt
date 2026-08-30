<template>
  <button
    v-if="other"
    type="button"
    class="flex items-center gap-2 whitespace-nowrap rounded-full bg-white/10 px-4 py-2 text-white/85 transition-colors hover:bg-white/20 hover:text-white"
    :aria-label="t('language', 'Language', 'اللغة')"
    @click="setLanguage(other.code)"
  >
    <AppImage
      v-if="other.image?.image_api"
      :src="other.image"
      :alt="other.code"
      class="size-4 rounded-sm object-cover"
    />
    {{ other.native_name ?? other.name }}
  </button>
</template>

<script setup>
/**
 * The project ships Arabic and English only, so this is a straight swap rather than a
 * menu: the button is labelled with the language you would be switching *to*. With more
 * than two it steps to the next one in the list, which keeps every language reachable.
 */
const { lang, languages, setLanguage, t } = useLang()

const other = computed(() => {
  const list = languages.value ?? []
  const index = list.findIndex((l) => l.code === lang.value?.code)
  return list[(index + 1) % list.length] ?? null
})
</script>
