<template>
  <section data-test="upload">
    <!--
      Collapsed to one dashed control, as the app has it: during the session the customer
      is holding a wet pot, not reading a form. Everything else lives in the sheet behind
      it. The piece model underneath is unchanged — an object is named first and
      photographed second, and the client-side `key` is what says two cards are two
      objects.
    -->
    <button
      v-if="!full"
      type="button"
      class="flex w-full flex-col items-center gap-2 rounded-2xl border-2 border-dashed border-primary/40 bg-primary/5 p-6 text-primary transition-colors hover:bg-primary/10"
      data-test="open-upload"
      @click="openSheet"
    >
      <LucideCamera class="size-6" />
      <span class="text-sm font-semibold">
        {{ t("upload_open", "Upload a photo of your piece", "ارفع صورة قطعتك") }}
      </span>
    </button>

    <p v-if="!full" class="mt-3 text-xs text-muted-foreground" data-test="upload-window">
      {{
        t(
          "upload_window",
          "Photos can only be added while the session is running. Once the studio finishes it nothing can ever be added to this booking again.",
          "يمكن إضافة الصور أثناء الورشة فقط. بمجرد أن ينهيها الاستوديو لن يمكن إضافة أي شيء إلى هذا الحجز مرة أخرى.",
        )
      }}
    </p>

    <!-- What has already been kept, one card per object. -->
    <ul v-if="savedPieces.length" class="mt-4 flex flex-col gap-3">
      <li
        v-for="piece in savedPieces"
        :key="`saved-${piece.id}`"
        class="rounded-2xl border bg-card p-4"
        data-test="saved-piece"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="truncate font-display font-semibold">{{ pieceLabel(piece) }}</p>
            <p class="text-xs text-muted-foreground">
              {{ t("n_photos", ":n photos", ":n صور", { n: piece.images?.length ?? 0 }) }}
            </p>
          </div>

          <div class="flex shrink-0 items-center gap-1">
            <label
              class="flex size-9 cursor-pointer items-center justify-center rounded-control text-primary transition-colors hover:bg-primary/10"
              :aria-label="t('add_angle', 'Add another photo of this piece', 'أضيفي صورة أخرى لهذه القطعة')"
            >
              <LucideCamera class="size-4" />
              <input
                :key="`add-${piece.id}-${resetKey}`"
                type="file"
                accept="image/*"
                multiple
                class="sr-only"
                :data-add-to="piece.id"
                @change="pick($event, { pieceId: piece.id })"
              />
            </label>

            <Button
              type="button"
              size="icon"
              variant="ghost"
              class="size-9 rounded-control text-destructive"
              :aria-label="t('remove', 'Remove', 'إزالة')"
              :data-remove-piece="piece.id"
              @click="emit('remove-piece', piece)"
            >
              <LucideTrash2 class="size-4" />
            </Button>
          </div>
        </div>

        <ul v-if="piece.images?.length" class="mt-3 flex flex-wrap gap-2">
          <!--
            The remove sits ON the photograph: there is no replace in the API, so a shot
            that came out badly is deleted and taken again, and that has to be reachable
            from where the customer is looking at it.
          -->
          <li v-for="(image, index) in piece.images" :key="image.id" class="relative">
            <button
              type="button"
              class="block overflow-hidden rounded-xl transition-opacity hover:opacity-80"
              :aria-label="t('view_photo', 'View photo', 'عرض الصورة')"
              @click="openPhotos(piece.images, index)"
            >
              <AppImage :src="image" alt="" class="size-16 object-cover" />
            </button>
            <button
              type="button"
              class="absolute top-1 flex size-6 items-center justify-center rounded-full bg-background/90 text-destructive shadow-sm transition-colors hover:bg-destructive hover:text-white ltr:right-1 rtl:left-1"
              :aria-label="t('remove', 'Remove', 'إزالة')"
              :data-remove-image="image.id"
              @click="emit('remove-image', image.id)"
            >
              <LucideX class="size-3.5" />
            </button>
          </li>
        </ul>

        <!-- Angles chosen but not sent yet. -->
        <ul v-if="additions[piece.id]?.length" class="mt-2 flex flex-wrap gap-2">
          <li v-for="(file, index) in additions[piece.id]" :key="index">
            <img :src="previewOf(file)" alt="" class="size-16 rounded-xl object-cover opacity-70" />
          </li>
        </ul>
      </li>
    </ul>

    <!-- Anything staged from a card rather than the sheet still needs sending. -->
    <Button
      v-if="Object.values(additions).some((files) => files.length)"
      type="button"
      class="mt-4 h-12 w-full rounded-xl bg-primary text-base hover:bg-primary/90"
      :disabled="!canUpload"
      @click="upload"
    >
      {{ uploading ? t("uploading", "Uploading…", "جارٍ الرفع...") : t("upload_action", "Upload", "رفع") }}
    </Button>

    <span v-if="uploadError" class="mt-3 block text-xs text-destructive">{{ uploadError }}</span>

    <!-- A shot taken on a phone, at 64px, is a picture of something the customer wants to
         look at. One piece's angles per run, as on the finished booking. -->
    <AppLightbox v-model="viewing" :items="viewingImages" />

    <!-- «أضف صوراً» — one person at a time, named, with room for four photographs. -->
    <BookingSheet
      :open="sheetOpen"
      :busy="uploading"
      :title="t('upload_sheet_title', 'Add photos', 'أضف صوراً')"
      @close="sheetOpen = false"
    >
      <template #icon><LucideCamera class="size-5" /></template>

      <p
        class="mb-4 w-fit rounded-full bg-brand-mist/60 px-3 py-1 text-xs font-medium tabular-nums"
        data-test="piece-progress"
      >
        {{
          t("pieces_progress", ":done of :expected named", ":done من :expected مسماة", {
            done: savedPieces.length,
            expected,
          })
        }}
      </p>

      <div v-for="(draft, index) in drafts" :key="draft.key" class="flex flex-col gap-3">
        <p class="text-sm font-medium">
          {{ t("person_n", "Person :n", "الشخص :n", { n: localeDigits(index + 1, code) }) }}
        </p>

        <Input
          v-model="draft.label"
          class="h-12 rounded-xl"
          :placeholder="t('piece_label', 'Their name', 'اسمه')"
          maxlength="60"
          :data-draft-label="draft.key"
        />

        <!-- Four slots, because the cap is four photographs per person. -->
        <ul class="grid grid-cols-4 gap-2">
          <li v-for="slot in MAX_PHOTOS_PER_PERSON" :key="slot">
            <div
              v-if="draft.files[slot - 1]"
              class="relative aspect-square overflow-hidden rounded-xl"
            >
              <img :src="previewOf(draft.files[slot - 1])" alt="" class="size-full object-cover" />
              <button
                type="button"
                class="absolute end-1 top-1 flex size-6 items-center justify-center rounded-full bg-brand-ink/70 text-white"
                :aria-label="t('remove', 'Remove', 'إزالة')"
                @click="dropFile(draft, slot - 1)"
              >
                <LucideX class="size-3.5" />
              </button>
            </div>

            <label
              v-else
              class="flex aspect-square cursor-pointer items-center justify-center rounded-xl border-2 border-dashed border-primary/40 bg-primary/5 text-primary transition-colors hover:bg-primary/10"
            >
              <LucideCamera class="size-5" />
              <input
                type="file"
                accept="image/*"
                multiple
                class="sr-only"
                :data-draft-files="draft.key"
                @change="pick($event, { draft })"
              />
            </label>
          </li>
        </ul>
      </div>

      <Button
        v-if="!atCeiling"
        type="button"
        variant="outline"
        class="mt-4 h-12 w-full rounded-xl"
        data-test="add-piece"
        @click="addDraft"
      >
        <LucidePlus class="size-4" />
        {{ t("add_piece_action", "Add a piece", "إضافة قطعة") }}
      </Button>

      <p v-if="atCeiling" class="mt-3 text-xs text-muted-foreground" data-test="ceiling-note">
        {{
          t(
            "pieces_ceiling",
            "You bought :n piece(s), so that is everything this booking can hold.",
            "اشتريتِ :n قطعة، وهذا كل ما يمكن أن يحتويه هذا الحجز.",
            { n: expected },
          )
        }}
      </p>

      <p class="mt-3 text-xs text-muted-foreground">
        {{ t("photos_left", ":n photo(s) left", "متبقٍ :n صورة", { n: photosLeft }) }}
      </p>

      <span v-if="uploadError" class="mt-3 block text-xs text-destructive">{{ uploadError }}</span>
      <span v-for="field in ERROR_FIELDS" :key="field">
        <span v-if="fieldError(errors, field)" class="mt-1 block text-xs text-destructive">
          {{ fieldError(errors, field) }}
        </span>
      </span>

      <template #footer>
        <Button
          type="button"
          class="h-12 flex-1 rounded-xl bg-primary text-base hover:bg-primary/90"
          :disabled="!canUpload"
          @click="upload"
        >
          {{ uploading ? t("uploading", "Uploading…", "جارٍ الرفع...") : t("upload_action", "Upload", "رفع") }}
        </Button>
      </template>
    </BookingSheet>
  </section>
</template>

<script setup>
/**
 * The photo step, built around objects rather than files: a piece is created first, then
 * photographed. The client-side `key` is what tells the server two cards are two objects —
 * matching on the label text could never express two friends both calling their cup "mug".
 * A photo added to a piece that already exists travels as that piece's `id` instead.
 */
const props = defineProps({
  booking: { type: Object, required: true },
});

const emit = defineEmits(["uploaded", "remove-piece", "remove-image"]);

const viewingImages = ref([]);
const viewing = ref(null);
const openPhotos = (images, index) => {
  viewingImages.value = images;
  viewing.value = index;
};

const { t, code } = useLang("web", "bookings");
const actions = useBookingActions(() => props.booking.id);

const ERROR_FIELDS = ["piece_labels", "piece_keys", "piece_ids", "images"];

const sheetOpen = ref(false);

/** Opening with nothing to fill in would show an empty sheet. */
const openSheet = () => {
  if (!drafts.value.length && !atCeiling.value) addDraft();
  sheetOpen.value = true;
};

/**
 * A preview for a File the customer has chosen but not sent.
 *
 * Cached per File and revoked on unmount: a fresh `createObjectURL` on every render would
 * leak one blob per keystroke, and the browser holds them for the life of the document.
 */
const previews = new WeakMap();
const revocable = [];
const previewOf = (file) => {
  // Guarded, and caught: `createObjectURL` is missing in some non-browser DOMs and
  // refuses a File in others. A thumbnail is cosmetic — a throw here would take the whole
  // form down with it, mid-session, with the customer holding a wet pot.
  if (previews.has(file)) return previews.get(file);
  try {
    const url = URL.createObjectURL(file);
    previews.set(file, url);
    revocable.push(url);
    return url;
  } catch {
    previews.set(file, "");
    return "";
  }
};
onBeforeUnmount(() => revocable.forEach((url) => URL.revokeObjectURL?.(url)));

/** One slot cleared, leaving the others where they are. */
const dropFile = (draft, index) => {
  draft.files = draft.files.filter((_, at) => at !== index);
};

const MAX_PHOTOS_PER_PERSON = 4;

const drafts = ref([]);
const additions = ref({});
const resetKey = ref(0);
const uploading = ref(false);
const uploadError = ref("");
const errors = ref({});

let sequence = 0;

const savedPieces = computed(() => props.booking.pieces ?? []);

/** A piece with a blank name is still called something, as it is in the app. */
const pieceLabel = (piece) =>
  (piece?.label ?? "").trim() || t("piece_untitled_short", "Piece", "قطعة");
const expected = computed(() => props.booking.expected_piece_count ?? 0);

/**
 * How many objects this booking can hold.
 *
 * For `paint_your_piece` / `make_your_candle` it is what was bought, and the server
 * answers 422 past it. For `make_your_piece` the API calls it a guide — one per person
 * who checked in, and going over is allowed — but the app's UI stops at it anyway: a
 * booking for one person offers one name, because a second name there is somebody who is
 * not at the session. Same number either way; the difference is only what the server
 * would tolerate.
 */
const atCeiling = computed(
  () => savedPieces.value.length + drafts.value.length >= expected.value,
);

/**
 * Every piece this booking expects has been named and kept, so there is nothing left to
 * open the sheet for. The cards stay — each still offers another angle of its own object,
 * which is not a new piece and so is not capped by this.
 */
const full = computed(() => savedPieces.value.length >= expected.value);

const staged = computed(() => [
  ...savedPieces.value.flatMap((piece) =>
    (additions.value[piece.id] ?? []).map((file) => ({
      file,
      label: piece.label,
      id: piece.id,
    })),
  ),
  ...drafts.value.flatMap((draft) =>
    draft.files.map((file) => ({
      file,
      label: draft.label.trim(),
      key: draft.key,
    })),
  ),
]);

const budget = computed(() =>
  Math.max(
    0,
    MAX_PHOTOS_PER_PERSON * (props.booking.people_count ?? 1) -
      (props.booking.images?.length ?? 0),
  ),
);
const photosLeft = computed(() =>
  Math.max(0, budget.value - staged.value.length),
);

const canUpload = computed(
  () =>
    !!staged.value.length &&
    !uploading.value &&
    drafts.value.every((draft) => !draft.files.length || draft.label.trim()),
);

const addDraft = () => {
  if (atCeiling.value) return;
  drafts.value = [
    ...drafts.value,
    { key: String(++sequence), label: "", files: [] },
  ];
};

const removeDraft = (draft) => {
  drafts.value = drafts.value.filter(
    (candidate) => candidate.key !== draft.key,
  );
};

const pick = (event, target) => {
  const held = target.draft
    ? target.draft.files.length
    : (additions.value[target.pieceId] ?? []).length;
  const room = Math.max(0, budget.value - (staged.value.length - held));
  const picked = Array.from(event.target.files ?? []).slice(0, room);

  // Appended, not replaced: each slot is its own input, so a second pick would otherwise
  // throw away the photographs already chosen for that person.
  if (target.draft) {
    target.draft.files = [...target.draft.files, ...picked].slice(0, MAX_PHOTOS_PER_PERSON);
  } else {
    additions.value = {
      ...additions.value,
      [target.pieceId]: [...(additions.value[target.pieceId] ?? []), ...picked],
    };
  }
  // A file input keeps its selection, so re-picking the same file would not fire again.
  event.target.value = "";
};

const upload = async () => {
  uploading.value = true;
  uploadError.value = "";
  errors.value = {};
  try {
    const res = await actions.uploadImages(staged.value);
    drafts.value = [];
    additions.value = {};
    resetKey.value += 1;
    sheetOpen.value = false;
    emit("uploaded", res);
  } catch (err) {
    const normalized = normalizeApiError(err);
    errors.value = normalized.errors;
    // "Not attending" comes back with `errors: null` — the message is all there is.
    if (!Object.keys(normalized.errors).length)
      uploadError.value = normalized.message;
  } finally {
    uploading.value = false;
  }
};
</script>
