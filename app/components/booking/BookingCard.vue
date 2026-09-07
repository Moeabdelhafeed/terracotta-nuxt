<template>
  <NuxtLink :to="`/bookings/${booking.id}`" class="flex gap-4 rounded-3xl border bg-card p-4 transition-shadow hover:shadow-lg sm:p-6">
    <div class="size-20 shrink-0 overflow-hidden rounded-2xl bg-brand-mist sm:size-24">
      <AppImage v-if="booking.workshop_image" :src="booking.workshop_image" :alt="booking.workshop_title" class="size-full object-cover" />
    </div>

    <div class="min-w-0 flex-1">
      <div class="flex items-start justify-between gap-3">
        <h2 class="font-display text-lg font-semibold">
          {{ booking.workshop_title }}<span v-if="booking.has_celebration"> {{ t('with_celebration', 'with a celebration', 'مع احتفال') }}</span>
        </h2>
        <BookingStatusBadge :booking="booking" />
      </div>

      <p class="mt-1 text-sm text-muted-foreground">
        {{ t('n_people', ':n people', ':n اشخاص', { n: booking.people_count }) }}
        · {{ formatBookingDate(booking.booking_date, code) }}
        · <span dir="ltr">{{ formatSlotTime(booking.start_time, booking.end_time) }}</span>
      </p>

      <p class="mt-2 font-display text-xl font-black text-primary">{{ format(booking.total_price) }}</p>
    </div>
  </NuxtLink>
</template>

<script setup>
defineProps({ booking: { type: Object, required: true } })

const { t, code } = useLang('web', 'bookings')
const { format } = usePrice()
</script>
