<template>
  <div class="relative">
    <Input
      :id="id"
      v-model="modelValue"
      :type="visible ? 'text' : 'password'"
      class="h-12 rounded-xl pe-11 text-base"
      v-bind="$attrs"
    />
    <button
      type="button"
      class="absolute top-1/2 -translate-y-1/2 text-brand-rust/80 transition-colors hover:text-brand-rust ltr:right-4 rtl:left-4"
      :aria-label="visible ? t('hide_password', 'Hide password', 'إخفاء كلمة المرور') : t('show_password', 'Show password', 'إظهار كلمة المرور')"
      @click="visible = !visible"
    >
      <LucideEyeOff v-if="visible" class="size-5" />
      <LucideEye v-else class="size-5" />
    </button>
  </div>
</template>

<script setup>
/**
 * The password field the design shows everywhere: same height and radius as the other
 * inputs, with the rust eye-toggle sitting inside it rather than a bare `type="password"`.
 */
defineProps({
  id: { type: String, required: true },
})

const modelValue = defineModel({ type: String, default: '' })
const { t } = useLang('web', 'general')
const visible = ref(false)
</script>
