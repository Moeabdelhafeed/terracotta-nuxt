<template>
  <section class="rounded-3xl border bg-card p-6" data-test="upload">
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div class="min-w-0">
        <h2 class="font-display text-xl font-semibold">
          {{ t("upload_title", "Photograph your pieces", "صوّري قطعك") }}
        </h2>
        <p class="mt-1 text-sm text-muted-foreground">
          {{
            t(
              "upload_note",
              "Add a piece for each object you made, then attach its photos — every angle of the same object belongs to the same piece.",
              "أضيفي قطعة لكل شيء صنعتِه، ثم أرفقي صورها — كل زوايا الشيء نفسه تخص القطعة نفسها.",
            )
          }}
        </p>
      </div>
      <span
        class="shrink-0 rounded-full bg-brand-mist/60 px-3 py-1 text-xs font-medium tabular-nums"
        data-test="piece-progress"
      >
        {{
          t(
            "pieces_progress",
            ":done of :expected named",
            ":done من :expected مسماة",
            { done: savedPieces.length, expected },
          )
        }}
      </span>
    </div>

    <p class="mt-4 rounded-2xl bg-amber-100/70 p-4 text-sm text-amber-900">
      {{
        t(
          "upload_window",
          "Photos can only be added while the session is running. Once the studio finishes it nothing can ever be added to this booking again.",
          "يمكن إضافة الصور أثناء الورشة فقط. بمجرد أن ينهيها الاستوديو لن يمكن إضافة أي شيء إلى هذا الحجز مرة أخرى.",
        )
      }}
    </p>

    <ul class="mt-6 flex flex-col gap-4">
      <li
        v-for="piece in savedPieces"
        :key="`saved-${piece.id}`"
        class="rounded-2xl border p-4"
        data-test="saved-piece"
      >
        <div class="flex items-center justify-between gap-3">
          <div class="min-w-0">
            <p class="truncate font-medium">{{ piece.label }}</p>
            <p class="text-xs text-muted-foreground">
              {{
                t("n_photos", ":n photos", ":n صور", {
                  n: piece.images?.length ?? 0,
                })
              }}
            </p>
          </div>
          <Button
            type="button"
            size="icon"
            variant="ghost"
            class="size-9 shrink-0 rounded-xl text-destructive"
            :aria-label="t('remove', 'Remove', 'إزالة')"
            :data-remove-piece="piece.id"
            @click="emit('remove-piece', piece)"
          >
            <LucideTrash2 class="size-4" />
          </Button>
        </div>

        <input
          :key="`add-${piece.id}-${resetKey}`"
          type="file"
          accept="image/*"
          multiple
          class="mt-3 block w-full text-sm"
          :data-add-to="piece.id"
          :aria-label="
            t(
              'add_angle',
              'Add another photo of this piece',
              'أضيفي صورة أخرى لهذه القطعة',
            )
          "
          @change="pick($event, { pieceId: piece.id })"
        />

        <ul v-if="additions[piece.id]?.length" class="mt-2 flex flex-col gap-1">
          <li
            v-for="(file, index) in additions[piece.id]"
            :key="index"
            class="flex items-center gap-2 text-xs text-muted-foreground"
          >
            <LucideImage class="size-3.5 shrink-0" />
            <span class="min-w-0 flex-1 truncate">{{ file.name }}</span>
          </li>
        </ul>
      </li>

      <li
        v-for="draft in drafts"
        :key="draft.key"
        class="rounded-2xl border border-dashed p-4"
        data-test="draft-piece"
      >
        <div class="flex items-center gap-3">
          <Input
            v-model="draft.label"
            class="h-12 flex-1 rounded-xl"
            :placeholder="t('piece_label', 'Piece name', 'اسم القطعة')"
            maxlength="60"
            :data-draft-label="draft.key"
          />
          <Button
            type="button"
            size="icon"
            variant="ghost"
            class="size-9 shrink-0 rounded-xl text-destructive"
            :aria-label="t('remove', 'Remove', 'إزالة')"
            :data-remove-draft="draft.key"
            @click="removeDraft(draft)"
          >
            <LucideX class="size-4" />
          </Button>
        </div>

        <input
          type="file"
          accept="image/*"
          multiple
          class="mt-3 block w-full text-sm"
          :data-draft-files="draft.key"
          :aria-label="
            t('piece_photos', 'Photos of this piece', 'صور هذه القطعة')
          "
          @change="pick($event, { draft })"
        />

        <ul v-if="draft.files.length" class="mt-2 flex flex-col gap-1">
          <li
            v-for="(file, index) in draft.files"
            :key="index"
            class="flex items-center gap-2 text-xs text-muted-foreground"
          >
            <LucideImage class="size-3.5 shrink-0" />
            <span class="min-w-0 flex-1 truncate">{{ file.name }}</span>
          </li>
        </ul>
      </li>
    </ul>

    <Button
      type="button"
      variant="outline"
      class="mt-4 h-12 rounded-xl"
      data-test="add-piece"
      :disabled="atCeiling"
      @click="addDraft"
    >
      <LucidePlus class="size-4" />
      {{ t("add_piece_action", "Add a piece", "إضافة قطعة") }}
    </Button>

    <p
      v-if="atCeiling"
      class="mt-3 text-xs text-muted-foreground"
      data-test="ceiling-note"
    >
      {{
        t(
          "pieces_ceiling",
          "You bought :n piece(s), so that is everything this booking can hold.",
          "اشتريتِ :n قطعة، وهذا كل ما يمكن أن يحتويه هذا الحجز.",
          { n: expected },
        )
      }}
    </p>
    <p
      v-else-if="!hasCeiling && savedPieces.length >= expected"
      class="mt-3 text-xs text-muted-foreground"
      data-test="guide-note"
    >
      {{
        t(
          "pieces_guide",
          "That is everything we expected — add more if you made more.",
          "هذا كل ما توقعناه — أضيفي المزيد إن صنعتِ أكثر.",
        )
      }}
    </p>

    <p class="mt-3 text-xs text-muted-foreground">
      {{
        t("photos_left", ":n photo(s) left", "متبقٍ :n صورة", { n: photosLeft })
      }}
    </p>

    <span v-if="uploadError" class="mt-3 block text-xs text-destructive">{{
      uploadError
    }}</span>
    <span
      v-if="fieldError(errors, 'piece_labels')"
      class="mt-1 block text-xs text-destructive"
      >{{ fieldError(errors, "piece_labels") }}</span
    >
    <span
      v-if="fieldError(errors, 'piece_keys')"
      class="mt-1 block text-xs text-destructive"
      >{{ fieldError(errors, "piece_keys") }}</span
    >
    <span
      v-if="fieldError(errors, 'piece_ids')"
      class="mt-1 block text-xs text-destructive"
      >{{ fieldError(errors, "piece_ids") }}</span
    >
    <span
      v-if="fieldError(errors, 'images')"
      class="mt-1 block text-xs text-destructive"
      >{{ fieldError(errors, "images") }}</span
    >

    <Button
      type="button"
      class="mt-4 h-12 rounded-xl bg-brand-rust px-8 text-base hover:bg-brand-rust/90"
      :disabled="!canUpload"
      @click="upload"
      >{{
        uploading
          ? t("uploading", "Uploading…", "جارٍ الرفع...")
          : t("upload_action", "Upload", "رفع")
      }}</Button
    >
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

const emit = defineEmits(["uploaded", "remove-piece"]);

const { t } = useLang("web", "bookings");
const actions = useBookingActions(() => props.booking.id);

const MAX_PHOTOS_PER_PERSON = 4;

const drafts = ref([]);
const additions = ref({});
const resetKey = ref(0);
const uploading = ref(false);
const uploadError = ref("");
const errors = ref({});

let sequence = 0;

const savedPieces = computed(() => props.booking.pieces ?? []);
const expected = computed(() => props.booking.expected_piece_count ?? 0);

/**
 * Only `paint_your_piece` / `make_your_candle` carry product lines, and only for those is
 * `expected_piece_count` the number of objects bought — a ceiling the server answers 422
 * on. `make_your_piece` buys nothing per object, so its count is a guide and going over is
 * normal.
 */
const hasCeiling = computed(() => (props.booking.products?.length ?? 0) > 0);
const atCeiling = computed(
  () =>
    hasCeiling.value &&
    savedPieces.value.length + drafts.value.length >= expected.value,
);

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

  if (target.draft) target.draft.files = picked;
  else additions.value = { ...additions.value, [target.pieceId]: picked };
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
