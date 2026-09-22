<template>
  <NuxtLink
    :to="`/bookings/${booking.id}`"
    class="flex h-full min-h-[110px] overflow-hidden rounded-control p-1 transition-[transform,box-shadow,opacity] duration-200 hover:-translate-y-0.5 hover:opacity-95 hover:shadow-md active:translate-y-0"
    :style="{ backgroundColor: workshopColour(workshop) }"
  >
    <div class="flex min-w-0 flex-1 flex-col gap-1 pb-4 pe-2 ps-4 pt-4 text-white">
      <h2 class="line-clamp-2 font-display text-xl font-semibold leading-snug">
        {{ booking.workshop_title }}
      </h2>

      <!-- Where the workshop card carries its audience badge: the booking's own two
           labels sit in the copy, as pills, rather than banded across the artwork. A band
           cut the illustration in half and left the well looking broken. -->
      <div v-if="statusLabel || booking.has_celebration" class="flex flex-wrap gap-1.5">
        <span
          v-if="statusLabel"
          class="inline-flex w-fit items-center rounded-full px-2 py-0.5 text-[11px] font-semibold text-white"
          :class="statusTone"
          :data-state="state"
        >{{ statusLabel }}</span>

        <span
          v-if="booking.has_celebration"
          class="inline-flex w-fit items-center rounded-full bg-white/20 px-2 py-0.5 text-[11px] font-medium text-white"
        >{{ t('with_celebration', 'with a celebration', 'مع احتفال') }}</span>
      </div>

      <p class="line-clamp-2 text-xs leading-relaxed text-white/85">
        {{ t('n_people', ':n people', ':n اشخاص', { n: booking.people_count }) }}
        · {{ formatBookingDate(booking.booking_date, code) }}
        · {{ formatSlotTime(booking.start_time, booking.end_time, code) }}
      </p>

      <!-- On the card's own colour, so the price reads as part of the booking rather than
           borrowing the shop's brown. -->
      <p class="mt-auto pt-2 font-display text-xl font-black">{{ format(booking.total_price) }}</p>
    </div>

    <!-- The workshop card's well, to the pixel: a photograph fills it untouched, and the
         family's drawing is black art on a wash of the card's own ink, inverted to white. -->
    <div class="w-[101px] shrink-0 self-stretch overflow-hidden rounded-[6px]">
      <AppImage
        v-if="booking.workshop_image?.image_api"
        :src="booking.workshop_image"
        :alt="booking.workshop_title"
        class="size-full object-cover"
      />
      <div v-else class="size-full bg-white/45">
        <img
          v-if="art"
          :src="art"
          alt=""
          class="size-full object-cover opacity-90 [filter:brightness(0)_invert(1)]"
        />
      </div>
    </div>
  </NuxtLink>
</template>

<script setup>
/**
 * One of the customer's own bookings — the workshop card's twin, as the app draws it: the
 * same coloured band and illustration well, with the session's facts in place of the
 * description and the status as a pill where the workshop card carries its audience.
 *
 * The booking payload carries no `type` and no colour, so the CATALOGUE answers both,
 * matched on `workshop_id`. Unmatched falls back to the studio's own hue rather than
 * drawing nothing — a booking of a retired workshop still has to render.
 */
const props = defineProps({ booking: { type: Object, required: true } })

const { t, code } = useLang('web', 'bookings')
const { format } = usePrice()
const { workshops } = useWorkshops()
const { artFor } = useWorkshopArt()

const workshop = computed(
  () => workshops.value.find((entry) => entry.id === props.booking.workshop_id) ?? null,
)
const art = computed(() => (workshop.value ? artFor(workshop.value) : null))

const state = computed(() => bookingState(props.booking))

const labels = useBookingStatusLabels()

/**
 * The pill's colour is the only thing on the card that is not the workshop's own — a
 * cancelled booking has to read as cancelled whatever family it belongs to. Waiting is
 * amber, not blue: «قيد التحضير» in an informational blue read as "done, here is a note"
 * beside «مكتمل» in green.
 */
const tones = {
  pending_payment: 'bg-warning',
  confirmed: 'bg-success',
  attending: 'bg-success',
  absent: 'bg-warning',
  preparing: 'bg-warning',
  ready: 'bg-warning',
  awaiting_pickup: 'bg-warning',
  getting_ready: 'bg-info',
  on_the_way: 'bg-info',
  delivered: 'bg-success',
  cancelled: 'bg-destructive',
}

// An unmodelled status draws nothing rather than printing `pending_payment` at a customer.
const statusLabel = computed(() => labels.value[state.value] ?? '')
const statusTone = computed(() => tones[state.value] ?? 'bg-warning')
</script>
