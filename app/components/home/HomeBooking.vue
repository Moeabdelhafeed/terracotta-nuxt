<template>
  <section v-if="greeting" class="mx-auto max-w-6xl px-6 pt-14">
    <p v-if="greeting" class="font-display text-2xl font-semibold sm:text-3xl">{{ greeting }}</p>

  </section>
</template>

<script setup>
/**
 * The signed-in visitor's welcome — the greeting, by their own local hour.
 *
 * The next booking used to sit here too, off `GET /api/home`'s `current_booking`, and it
 * was the SAME row the live strip draws from the bookings list. One of them had to go,
 * and the strip's is the one the app keeps: it answers the workshops page as well.
 */
const { user } = useSanctumAuth()
const { t } = useLang('web', 'home')

const name = computed(() => {
  const record = user.value?.data ?? user.value
  return record?.is_guest ? '' : (record?.name ?? '')
})

// The hour is the *viewer's*, which the server does not know — reading it during SSR
// would greet half the world with the wrong half of the day and then swap it on
// hydration. So it stays null until mounted, and the line simply is not there yet.
const hour = ref(null)
onMounted(() => { hour.value = new Date().getHours() })

/**
 * The hour greets everyone; the name is only there for somebody who has one. A guest gets
 * the salutation on its own rather than nothing at all — and the line under it says what
 * signing in would keep.
 */
const greeting = computed(() => {
  if (hour.value === null) return ''
  const salutation = hour.value < 12
    ? t('good_morning', 'Good morning', 'صباح الخير')
    : t('good_evening', 'Good evening', 'مساء الخير')
  return name.value ? `${salutation}, ${name.value}` : salutation
})
</script>
