<template>
  <main class="bg-background">
    <PageBar :crumbs="crumbs" />
    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="flex flex-col gap-5">
        <div>
          <h1 class="font-display text-3xl font-semibold sm:text-4xl">
            {{ t('pieces_title', 'My pieces', 'قطعي') }}
          </h1>
          <p class="mt-3 text-muted-foreground">
            {{ t('pieces_subtitle', 'Everything you have made at the studio.', 'كل ما صنعته في الاستوديو.') }}
          </p>
        </div>

        <AppLoadError v-if="error" :error="error" :retry="refresh" />

        <ul
          v-else-if="pending && !pieces.length"
          class="columns-2 gap-2 sm:columns-3 lg:columns-4 xl:columns-5 [&>li]:mb-2"
          aria-busy="true"
        >
          <li v-for="n in 8" :key="n" class="break-inside-avoid">
            <AppSkeleton class="w-full !rounded-none" :style="{ height: `${tileHeight(n)}px` }" />
          </li>
        </ul>

        <div v-else-if="!pieces.length" class="mx-auto flex w-full max-w-xl flex-col items-center gap-2 rounded-2xl border bg-card p-10 text-center">
          <p class="font-display text-base font-semibold">{{ t('pieces_empty', 'Nothing here yet', 'ما صنعت شيئاً بعد') }}</p>
          <p class="text-sm text-muted-foreground">
            {{ t('pieces_empty_body', 'Your pieces show up here once the studio uploads the photos from your session.', 'تظهر قطعك هنا بعد رفع صور جلستك في الاستوديو.') }}
          </p>
        </div>

        <!--
          The gallery's own treatment, deliberately: a customer who has seen «الاستوديو»
          should recognise this. Masonry columns, square corners throughout, so the grid
          reads as one object rather than a scatter of cards.
        -->
        <ul
          v-else
          class="columns-2 gap-2 sm:columns-3 lg:columns-4 xl:columns-5 [&>li]:mb-2"
        >
          <li v-for="piece in pieces" :key="piece.id" class="break-inside-avoid">
            <button
              type="button"
              class="group relative block w-full overflow-hidden bg-brand-mist text-start"
              :style="{ height: `${tileHeight(piece.id)}px` }"
              @click="opened = piece"
            >
              <AppImage
                :src="piece.images[0]"
                :alt="piece.label ?? piece.workshopTitle ?? ''"
                class="size-full object-cover transition-transform duration-700 group-hover:scale-105"
              />

              <!--
                A blur over the WHOLE tile plus a 28% scrim, not a band at the bottom:
                white type has to stay legible over a photograph nobody chose for its
                contrast, and a plain scrim darkens a bright photo too little and a dark
                one too much.
              -->
              <span
                class="absolute inset-0 flex flex-col items-center justify-center gap-1 px-3 text-center text-white backdrop-blur-[12px]"
                style="background-color: rgba(0, 0, 0, 0.28)"
              >
                <span class="font-display text-base font-semibold drop-shadow-sm">
                  {{ piece.label || t('piece_untitled', 'Untitled piece', 'قطعة بلا اسم') }}
                </span>
                <!-- The tile can only show the first picture, so the count says there are more. -->
                <span class="text-xs text-white/90 drop-shadow-sm">
                  {{ t('piece_photo_count', ':n photos', ':n صور', { n: localeDigits(piece.images.length, code) }) }}
                </span>
              </span>

              <!-- The starting corner: top-right in Arabic, top-left in English. -->
              <span
                v-if="statusLabelFor(piece)"
                class="absolute top-2 rounded-md px-1.5 py-0.5 text-[10px] font-semibold start-2"
                :class="statusTone(piece.status)"
              >{{ statusLabelFor(piece) }}</span>
            </button>
          </li>
        </ul>
      </div>
    </div>

    <PieceSheet :piece="opened" @close="opened = null" @paint="openChooser" />

    <PiecePaintChoiceSheet
      :open="!!choosing"
      :offers="choosing?.offers ?? []"
      @close="choosing = null"
      @choose="startBooking"
    />
  </main>
</template>

<script setup>
definePageMeta({
  // Entered from somewhere, with its own way back in the header — the site's
  middleware: ['auth-mode', 'require-registered', 'verified'],
  name: 'my-gallery',
})

const { t, code } = useLang('web', 'profile')
const { pieces, pending, error, refresh } = useMyPieces()

// Reached from the profile, so the trail says so — and PageBar's arrow follows it.
const crumbs = computed(() => [
  { to: '/', label: t('nav_home', 'Home', 'الرئيسية', { subGroup: 'general' }) },
  { to: '/profile', label: t('nav_profile', 'Profile', 'حسابي', { subGroup: 'general' }) },
  { label: t('pieces_title', 'My pieces', 'قطعي') },
])

const opened = ref(null)
const choosing = ref(null)

/**
 * Tile heights cycle through a fixed table keyed on the piece's own id, so a tile does
 * not change shape when the list is re-read.
 */
const TILE_HEIGHTS = [173, 199, 225, 147]
const tileHeight = (id) => TILE_HEIGHTS[Math.abs(id) % TILE_HEIGHTS.length]

const statusLabelFor = (piece) => pieceStatusLabel(piece.status, t)

const statusTone = (status) => ({
  ready_to_paint: 'bg-brand-terracotta text-white',
  // Painted is done, not an error — the studio's green, not a warning colour.
  painted: 'bg-brand-green text-white',
}[status] ?? 'bg-black/50 text-white')

// Always the chooser, even for a single workshop: where it is painted and what that
// costs is the customer's call.
const openChooser = (piece) => { choosing.value = piece }

/**
 * Straight to the schedule step — day and seat first. The piece rides along in the query
 * so the picker two steps later already holds the cup the customer just named.
 */
const startBooking = (offer) => {
  const piece = choosing.value
  choosing.value = null
  opened.value = null
  return navigateTo(`/workshops/${offer.workshop.id}/book?piece=${piece.id}`)
}

useSeoMeta({ title: () => t('pieces_title', 'My pieces', 'قطعي'), robots: 'noindex' })
</script>
