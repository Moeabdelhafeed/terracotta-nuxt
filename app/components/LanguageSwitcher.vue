<template>
  <!-- An icon, as the app draws it (`Icons.translate_rounded`): the same cell as the bell
       and the cart, so the row of controls reads as one. The language it switches TO is
       named for screen readers, since the glyph alone does not say which. -->
  <button
    v-if="other"
    type="button"
    class="flex size-[54px] items-center justify-center rounded-[5px] text-white/70 transition-colors hover:bg-white/10 hover:text-white"
    :aria-label="
      t('switch_to_language', 'Switch to :language', 'التبديل إلى :language', {
        language: other.native_name ?? other.name,
      })
    "
    :title="other.native_name ?? other.name"
    @click="setLanguage(other.code)"
  >
    <LucideLanguages class="size-[26px]" />
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
