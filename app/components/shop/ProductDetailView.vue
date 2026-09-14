<!--
  One product, both shelves. The shop and the raw materials catalogue sell the same
  shape of thing through the same basket, so they show it the same way — only the
  breadcrumb says which shelf you came from.
-->
<template>
  <!-- A client-side navigation lands here before the fetch resolves; the skeleton keeps
       the page's shape instead of flashing an empty screen. -->
  <main
    v-if="status !== 'success' && !product"
    class="mx-auto max-w-6xl px-6 py-16"
    aria-busy="true"
  >
    <div class="grid gap-10 lg:grid-cols-2 lg:items-start">
      <div>
        <AppSkeleton class="aspect-square w-full !rounded-2xl" />
        <div class="mt-3 flex gap-3">
          <AppSkeleton v-for="n in 4" :key="n" class="size-20 !rounded-xl" />
        </div>
      </div>

      <div class="rounded-2xl border bg-card p-6 sm:p-8">
        <AppSkeleton class="h-4 w-32" />
        <AppSkeleton class="mt-3 h-9 w-3/4" />
        <AppSkeleton class="mt-5 h-8 w-32" />
        <AppSkeleton class="mt-6 h-4 w-full" />
        <AppSkeleton class="mt-2 h-4 w-5/6" />
        <AppSkeleton class="mt-2 h-4 w-2/3" />
        <div class="mt-8 grid gap-4 sm:grid-cols-3">
          <AppSkeleton v-for="n in 3" :key="n" class="h-16 !rounded-2xl" />
        </div>
      </div>
    </div>
  </main>

  <main v-else-if="product">
    <PageBar :crumbs="crumbs" />

    <div class="mx-auto max-w-6xl px-6 py-16">
      <div class="grid gap-10 lg:grid-cols-2 lg:items-start">
        <div ref="content">
          <div class="overflow-hidden rounded-2xl border bg-card">
            <AppImage
              v-if="active"
              :src="active"
              :alt="product.title"
              class="aspect-square w-full object-cover"
            />
          </div>

          <ul
            v-if="shots.length > 1"
            class="mt-3 flex gap-3 overflow-x-auto pb-1"
          >
            <li v-for="(shot, index) in shots" :key="index">
              <button
                type="button"
                class="size-20 shrink-0 overflow-hidden rounded-xl border transition-opacity"
                :class="
                  active === shot
                    ? 'border-primary'
                    : 'opacity-70 hover:opacity-100'
                "
                @click="chosen = shot"
              >
                <AppImage
                  :src="shot"
                  :alt="product.title"
                  class="size-full object-cover"
                />
              </button>
            </li>
          </ul>
        </div>

        <!-- Pinned rather than `position: sticky`: ScrollSmoother transforms
             #smooth-content, and a transformed ancestor makes sticky behave like static. -->
        <aside ref="aside">
          <div class="rounded-2xl border bg-card p-6 sm:p-8">
            <!-- The API sends these as plain localized strings, not objects. -->
            <p
              v-if="product.category"
              class="text-sm uppercase tracking-[0.18em] text-muted-foreground"
            >
              {{ product.category
              }}<template v-if="product.sub_category">
                · {{ product.sub_category }}</template
              >

              <script setup>
                const props = defineProps({
                  /** Null until the fetch resolves; the page above owns the loading and 404 paths. */
                  product: { type: Object, default: null },
                  status: { type: String, default: "idle" },
                  /** Which shelf this piece came from — the shop, or raw materials and tools. */
                  sectionTo: { type: String, default: "/shop" },
                  sectionLabel: { type: String, default: "" },
                });

                const product = computed(() => props.product);
                const status = computed(() => props.status);

                const { t } = useLang("web", "home");
                const { format } = usePrice();

                const content = ref(null);
                const aside = ref(null);

                useStickyAside(aside, content, product);

                const crumbs = computed(() => [
                  {
                    to: "/",
                    label: t("nav_home", "Home", "الرئيسية", {
                      subGroup: "general",
                    }),
                  },
                  { to: props.sectionTo, label: props.sectionLabel },
                  ...(product.value?.category
                    ? [{ label: product.value.category }]
                    : []),
                  { label: product.value?.title ?? "" },
                ]);

                const shots = computed(() => {
                  const gallery = product.value?.images ?? [];
                  return gallery.length
                    ? gallery
                    : [product.value?.image].filter(Boolean);
                });

                /**
                 * Derived, not synced. An `immediate` watcher would set this during setup — while the
                 * SSR fetch is still in flight and `shots` is empty — and Vue does not flush watchers
                 * again before the server render, so the main photo was missing from the SSR HTML
                 * entirely and only appeared after hydration (a mismatch, and a late LCP).
                 * `chosen` holds a thumbnail the visitor picked; until then the first shot wins.
                 */
                const chosen = ref(null);
                const active = computed(() =>
                  chosen.value && shots.value.includes(chosen.value)
                    ? chosen.value
                    : (shots.value[0] ?? null),
                );

                /**
                 * Swatch names, since the API sends bare hex strings. The value is matched to the nearest
                 * of these in RGB — close enough to label a glaze, and the studio palette is small.
                 */
                const NAMED_COLOURS = [
                  { hex: "#000000", en: "Black", ar: "أسود" },
                  { hex: "#2b2b2b", en: "Charcoal", ar: "فحمي" },
                  { hex: "#808080", en: "Grey", ar: "رمادي" },
                  { hex: "#ffffff", en: "White", ar: "أبيض" },
                  { hex: "#f5efe6", en: "Cream", ar: "كريمي" },
                  { hex: "#e0cfae", en: "Sand", ar: "رملي" },
                  { hex: "#c96f4a", en: "Terracotta", ar: "تراكوتا" },
                  { hex: "#8b4513", en: "Rust", ar: "صدئي" },
                  { hex: "#5b3a29", en: "Brown", ar: "بني" },
                  { hex: "#d64545", en: "Red", ar: "أحمر" },
                  { hex: "#e08a3c", en: "Orange", ar: "برتقالي" },
                  { hex: "#e6c34a", en: "Yellow", ar: "أصفر" },
                  { hex: "#7a8b3a", en: "Olive", ar: "زيتي" },
                  { hex: "#345a4a", en: "Forest", ar: "أخضر داكن" },
                  { hex: "#4aa37a", en: "Green", ar: "أخضر" },
                  { hex: "#3a7d8b", en: "Teal", ar: "أزرق مخضر" },
                  { hex: "#3a5a8b", en: "Blue", ar: "أزرق" },
                  { hex: "#1e2a44", en: "Navy", ar: "كحلي" },
                  { hex: "#6b4a8b", en: "Purple", ar: "بنفسجي" },
                  { hex: "#d98ba5", en: "Pink", ar: "وردي" },
                ];

                const rgb = (hex) => {
                  const value = hex.replace("#", "");
                  const full =
                    value.length === 3
                      ? value
                          .split("")
                          .map((c) => c + c)
                          .join("")
                      : value;
                  const number = parseInt(full, 16);
                  return [
                    (number >> 16) & 255,
                    (number >> 8) & 255,
                    number & 255,
                  ];
                };

                const nameFor = (hex) => {
                  const [r, g, b] = rgb(hex);
                  const nearest = NAMED_COLOURS.reduce(
                    (best, entry) => {
                      const [er, eg, eb] = rgb(entry.hex);
                      const distance =
                        (r - er) ** 2 + (g - eg) ** 2 + (b - eb) ** 2;
                      return distance < best.distance
                        ? { entry, distance }
                        : best;
                    },
                    { entry: NAMED_COLOURS[0], distance: Infinity },
                  ).entry;

                  return t(
                    `colour_${nearest.en.toLowerCase()}`,
                    nearest.en,
                    nearest.ar,
                  );
                };

                const colours = computed(() =>
                  (product.value?.colors ?? []).map((colour) => {
                    const hex = colour.hex ?? colour.color ?? colour;
                    return { hex, name: colour.name ?? nameFor(hex) };
                  }),
                );

                const dimensions = computed(() => {
                  const p = product.value;
                  if (!p) return [];

                  // Decimals arrive as strings ("8.00"); the unit is always centimetres.
                  const cm = (value) =>
                    value ? `${Number(value)} ${t("cm", "cm", "سم")}` : null;

                  return [
                    {
                      label: t("height", "Height", "ارتفاع"),
                      value: cm(p.height),
                    },
                    { label: t("width", "Width", "عرض"), value: cm(p.width) },
                    {
                      label: t("length", "Length", "طول"),
                      value: cm(p.length),
                    },
                  ].filter((row) => row.value);
                });
              </script>
            </p>
          </div>
        </aside>
      </div>
    </div>
  </main>
</template>
