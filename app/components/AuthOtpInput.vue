<template>
  <div class="flex w-full justify-center gap-1.5 sm:gap-2" dir="ltr">
    <input
      v-for="(digit, index) in digits"
      :key="index"
      :ref="(el) => { boxes[index] = el }"
      :value="digit"
      type="text"
      inputmode="numeric"
      autocomplete="one-time-code"
      maxlength="1"
      class="h-12 w-full min-w-0 max-w-11 rounded-field border border-input bg-transparent text-center text-lg font-semibold text-foreground outline-none transition-[color,box-shadow] focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50"
      @input="onInput(index, $event)"
      @keydown="onKeydown(index, $event)"
      @paste="onPaste($event)"
    >
  </div>
</template>

<script setup>
/**
 * A code entry as boxes, one digit each, the way the design draws it — rather than one
 * bare text input. Emits the joined string through `v-model`, same as any text field.
 */
const props = defineProps({
  length: { type: Number, default: 6 },
})

const emit = defineEmits(['complete'])
const modelValue = defineModel({ type: String, default: '' })

// The last digit submits, the way the app's code screens do — nobody types six digits
// and then goes looking for a button.
watch(modelValue, (value, previous) => {
  if (value.length === props.length && previous.length < props.length) emit('complete', value)
})

const digits = computed(() => {
  const chars = modelValue.value.split('')
  return Array.from({ length: props.length }, (_, i) => chars[i] ?? '')
})

const boxes = ref([])

const setDigit = (index, value) => {
  const chars = modelValue.value.split('')
  chars[index] = value
  modelValue.value = chars.join('').slice(0, props.length)
}

const onInput = (index, event) => {
  const raw = event.target.value.replace(/\D/g, '')
  event.target.value = digits.value[index] ?? ''

  if (!raw) {
    setDigit(index, '')
    return
  }

  // A fast typist's keystroke can land more than one digit (autofill, IME); take the
  // last one and let the loop's own `input` events fill the rest as focus advances.
  setDigit(index, raw.at(-1))
  boxes.value[index + 1]?.focus()
}

const onKeydown = (index, event) => {
  if (event.key === 'Backspace' && !digits.value[index] && index > 0) {
    boxes.value[index - 1]?.focus()
  }
}

const onPaste = (event) => {
  const pasted = (event.clipboardData?.getData('text') ?? '').replace(/\D/g, '')
  if (!pasted) return
  event.preventDefault()
  modelValue.value = pasted.slice(0, props.length)
  boxes.value[Math.min(pasted.length, props.length - 1)]?.focus()
}

onMounted(() => boxes.value[0]?.focus())
</script>
