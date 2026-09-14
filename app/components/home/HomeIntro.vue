<template>
  <section v-if="visible" class="mx-auto max-w-3xl px-6 pt-14">
    <div class="relative rounded-3xl border border-brand-mist bg-brand-mist/30 p-6 sm:p-8">
      <button
        type="button"
        class="absolute top-3 flex size-10 items-center justify-center rounded-full text-muted-foreground transition-colors hover:bg-brand-mist hover:text-foreground ltr:right-3 rtl:left-3"
        :aria-label="t('dismiss', 'Dismiss', 'تجاهل')"
        @click="dismiss"
      >
        <LucideX class="size-4" />
      </button>

      <ul class="flex flex-col gap-5">
        <li v-for="(step, index) in steps" :key="step.title" class="flex gap-4">
          <span class="mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-full bg-brand-terracotta/10 font-display text-sm font-semibold text-brand-rust">
            {{ index + 1 }}
          </span>
          <div class="min-w-0">
            <h3 class="font-display text-base font-semibold text-foreground">{{ step.title }}</h3>
            <p class="mt-1 text-sm leading-relaxed text-muted-foreground">{{ step.body }}</p>
          </div>
        </li>
      </ul>
    </div>
  </section>
</template>

<script setup>
/**
 * A three-line "what this place is" note, shown once per browser under the hero and
 * dismissible. It is a section in the page flow, not an overlay: nothing about it blocks
 * the site, and once the flag is set it never appears again.
 *
 * The flag lives in localStorage, which the server cannot read — so the section renders
 * only after mount rather than being guessed at during SSR and swapped on hydration.
 */
const SEEN_KEY = 'terracotta:intro-seen'

const { t } = useLang('web', 'home')

const visible = ref(false)

// A browser with site data blocked throws on read; that reads as "not seen", which shows
// the intro every visit rather than taking the page down.
onMounted(() => {
  try {
    visible.value = localStorage.getItem(SEEN_KEY) !== '1'
  } catch {
    visible.value = true
  }
})

const dismiss = () => {
  visible.value = false
  try {
    localStorage.setItem(SEEN_KEY, '1')
  } catch { /* nothing to persist to — it simply shows again next time */ }
}

const steps = computed(() => [
  {
    title: t('intro_make_title', 'Shape your own piece', 'اصنع قطعتك بيدك'),
    body: t('intro_make_body', 'Sit at the wheel, take a lump of clay and leave with something only you could have made.', 'اجلس على الدولاب، خذ قطعة من الطين، واخرج بشيء لا يمكن لأحد غيرك أن يصنعه.'),
  },
  {
    title: t('intro_workshop_title', 'The workshop experience', 'تجربة الورشة'),
    body: t('intro_workshop_body', 'Pick a date, bring whoever you like, and we handle the clay, the tools and the firing.', 'اختر موعدًا، أحضر من تحب، ونحن نتكفل بالطين والأدوات والحرق.'),
  },
  {
    title: t('intro_track_title', 'Follow your order step by step', 'تتبّع طلبك أول بأول'),
    body: t('intro_track_body', 'From the kiln to your door — every stage of your piece and your order is visible from your account.', 'من الفرن إلى بابك — كل مرحلة من قطعتك وطلبك تظهر لك في حسابك.'),
  },
])
</script>
