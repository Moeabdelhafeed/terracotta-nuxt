<template>
  <!--
    One segmented track, as the app draws it: the pair is a single control, so the
    inactive half is the ground the active half sits on.

    Shared by /workshops and /bookings because they are two halves of one hub. Each page
    used to draw its own pair — a segmented track here, two loose buttons there — so
    moving between them looked like the control had disappeared.
  -->
  <div class="flex rounded-control bg-brand-ink/10 p-2">
    <component
      :is="onBookings ? NuxtLink : 'span'"
      v-bind="onBookings ? { to: '/workshops' } : {}"
      class="flex h-12 flex-1 items-center justify-center rounded-[7px] text-sm font-semibold transition-colors"
      :class="onBookings
        ? 'text-foreground/70 hover:text-foreground'
        : 'bg-brand-terracotta text-white'"
    >{{ t('tab_book', 'Book a workshop', 'حجز ورشة') }}</component>

    <component
      :is="onBookings ? 'span' : NuxtLink"
      v-bind="onBookings ? {} : { to: '/bookings' }"
      class="flex h-12 flex-1 items-center justify-center gap-2 rounded-[7px] text-sm font-semibold transition-colors"
      :class="onBookings
        ? 'bg-brand-terracotta text-white'
        : 'text-foreground/70 hover:text-foreground'"
    >
      {{ t('tab_mine', 'My workshops', 'ورشاتي') }}
      <span
        v-if="activeCount"
        class="rounded-full px-2 text-xs"
        :class="onBookings ? 'bg-white/20 text-white' : 'bg-brand-terracotta text-white'"
      >{{ activeCount }}</span>
    </component>
  </div>
</template>

<script setup>
// The resolved component, not the name: `<component :is="'NuxtLink'">` renders a literal
// <nuxtlink> element that navigates nowhere. `resolveComponent` takes a string literal,
// which Nuxt rewrites at build time, so this one does resolve.
const NuxtLink = resolveComponent('NuxtLink')

const { t } = useLang('web', 'home')
const { activeCount } = useActiveBookingsCount()
const route = useRoute()

const onBookings = computed(() => route.path.startsWith('/bookings'))
</script>
