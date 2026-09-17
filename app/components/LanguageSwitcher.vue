<template>
  <button
    v-if="other"
    type="button"
    class="flex h-[54px] items-center gap-2 whitespace-nowrap rounded-[5px] bg-white/15 px-4 text-white transition-colors hover:bg-white/25"
    :aria-label="t('language', 'Language', 'اللغة')"
    @click="setLanguage(other.code)"
  >
    <AppImage
      v-if="other.image?.image_api"
      :src="other.image"
      :alt="other.code"
      class="size-[18px] rounded-[4px] object-cover"
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
  const list = asList(languages.value)
  const index = list.findIndex((l) => l.code === lang.value?.code)
  return list[(index + 1) % list.length] ?? null
})
</script>
