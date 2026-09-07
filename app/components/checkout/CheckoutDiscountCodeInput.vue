<template>
  <div class="flex flex-col gap-2">
    <Label :for="id">{{ t('discount_code', 'Discount code', 'كود الخصم') }}</Label>

    <div v-if="applied" class="flex h-12 items-center justify-between rounded-xl border border-brand-green/40 bg-brand-green/10 px-4 text-sm">
      <span class="flex items-center gap-2 font-medium text-brand-green">
        <LucideTicket class="size-4" />
        <span class="uppercase">{{ applied }}</span>
      </span>
      <button type="button" class="text-xs text-muted-foreground underline-offset-4 hover:underline" :disabled="disabled" @click="clear">
        {{ t('remove', 'Remove', 'إزالة') }}
      </button>
    </div>

    <div v-else class="flex gap-2">
      <Input
        :id="id"
        v-model="draft"
        type="text"
        autocomplete="off"
        autocapitalize="characters"
        class="h-12 flex-1 rounded-xl text-base uppercase"
        :placeholder="t('discount_code_placeholder', 'e.g. WELCOME10', 'مثال: WELCOME10')"
        :disabled="disabled"
        @keydown.enter.prevent="apply"
      />
      <Button type="button" variant="outline" class="h-12 rounded-xl px-5" :disabled="disabled || !draft.trim()" @click="apply">
        {{ t('apply', 'Apply', 'تطبيق') }}
      </Button>
    </div>

    <span v-if="errorText" class="text-xs text-destructive">{{ errorText }}</span>
  </div>
</template>

<script setup>
/**
 * The coupon box. `v-model` is the code the parent should send with its next quote
 * (`discount_code`); the parent re-quotes on change and hands back `errors` so the
 * server's field-keyed refusal shows here. Both spellings of the key are read — the
 * validate endpoint says `errors.code`, every quote/create says `errors.discount_code`.
 */
const props = defineProps({
  id: { type: String, default: 'discount_code' },
  errors: { type: Object, default: () => ({}) },
  disabled: { type: Boolean, default: false },
})

const applied = defineModel({ type: String, default: '' })
const { t } = useLang('web', 'checkout')

const draft = ref('')

const errorText = computed(() => fieldError(props.errors, 'discount_code') || fieldError(props.errors, 'code'))

// A refused code must stay editable — drop it back into the box instead of showing a
// "removed" pill for something that never applied.
watch(errorText, (text) => {
  if (text && applied.value) {
    draft.value = applied.value
    applied.value = ''
  }
})

const apply = () => {
  const code = draft.value.trim().toUpperCase()
  if (!code) return
  applied.value = code
}

const clear = () => {
  draft.value = ''
  applied.value = ''
}
</script>
