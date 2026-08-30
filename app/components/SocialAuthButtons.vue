<template>
  <div v-if="providers.length" class="flex flex-col gap-2">
    <Button
      v-for="p in providers"
      :key="p"
      type="button"
      variant="outline"
      :disabled="loading || pending === p"
      class="w-full justify-center gap-2"
      @click="onClick(p)"
    >
      <span :style="{ backgroundColor: providerColor(p) }" class="h-3 w-3 rounded-full" />
      {{ pending === p
        ? t('please_wait', 'Please wait...', 'يرجى الانتظار...')
        : t(`continue_with_${p.replace('.', '_')}`, `Continue with ${labelFor(p)}`, `المتابعة عبر ${arLabelFor(p)}`) }}
    </Button>
  </div>
</template>

<script setup>
const props = defineProps({
  providers: { type: Array, default: () => [] },
  loading: { type: Boolean, default: false },
})
const emit = defineEmits(['select'])

const { t } = useLang('web', 'auth')
const { signInWithProvider } = useFirebaseAuth()
const pending = ref(null)

const labelFor = (p) => ({
  'google.com': 'Google',
  'apple.com': 'Apple',
  'facebook.com': 'Facebook',
  'twitter.com': 'Twitter',
  'github.com': 'GitHub',
  'microsoft.com': 'Microsoft',
  'yahoo.com': 'Yahoo',
}[p] ?? p)

const arLabelFor = (p) => ({
  'google.com': 'جوجل',
  'apple.com': 'آبل',
  'facebook.com': 'فيسبوك',
  'twitter.com': 'تويتر',
  'github.com': 'جيت هاب',
  'microsoft.com': 'مايكروسوفت',
  'yahoo.com': 'ياهو',
}[p] ?? p)

const providerColor = (p) => ({
  'google.com': '#4285F4',
  'apple.com': '#000000',
  'facebook.com': '#1877F2',
  'twitter.com': '#1DA1F2',
  'github.com': '#181717',
  'microsoft.com': '#00A4EF',
  'yahoo.com': '#6001D2',
}[p] ?? '#888')

const onClick = async (p) => {
  pending.value = p
  try {
    const { idToken } = await signInWithProvider(p)
    emit('select', { provider: p, idToken })
  } catch (err) {
    emit('select', { provider: p, error: err })
  } finally {
    pending.value = null
  }
}
</script>
