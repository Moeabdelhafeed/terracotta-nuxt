<template>
  <div class="relative">
    <Input
      :id="id"
      v-model="modelValue"
      :type="visible ? 'text' : 'password'"
      class="h-12 rounded-field pe-11 text-base"
      v-bind="$attrs"
    />
    <button
      type="button"
      class="absolute top-1/2 grid size-10 -translate-y-1/2 place-items-center text-brand-terracotta/80 transition-colors hover:text-brand-terracotta ltr:right-1.5 rtl:left-1.5"
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

// Everything else (`required`, `minlength`, …) belongs to the field itself, not to the
// wrapper that holds the eye toggle.
defineOptions({ inheritAttrs: false })

const modelValue = defineModel({ type: String, default: '' })
const { t } = useLang('web', 'general')
const visible = ref(false)
</script>
