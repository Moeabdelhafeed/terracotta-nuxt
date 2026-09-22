<template>
  <span
    v-if="label"
    class="inline-flex w-fit items-center gap-1.5 px-2 py-0.5 text-xs font-medium"
    :class="
      onColor
        ? 'rounded-full bg-white/20 text-white'
        : 'rounded-md bg-primary/10 px-3 py-1 text-primary'
    "
    :data-audience="audience"
  >
    <LucideUsers class="size-3.5" />{{ label }}
  </span>
</template>

<script setup>
/**
 * Who a session is for. `mixed` is the default every workshop carries and restricts
 * nobody, so it renders nothing — a badge on every card would drown out the ones that
 * actually rule a customer out.
 */
const props = defineProps({
  audience: { type: String, default: "mixed" },
  /** On a card painted in the workshop's own colour, the pill is the card's ink at 18%.
   *  Off it, the pill tints `--primary` — which the workshop page rebinds to the
   *  workshop's own colour, so the badge follows whatever the page is painted in. */
  onColor: { type: Boolean, default: false },
});

const { t } = useLang("web", "home");

const label = computed(
  () =>
    ({
      women_only: t("audience_women_only", "Women only", "للنساء فقط"),
      men_only: t("audience_men_only", "Men only", "للرجال فقط"),
      couples: t("audience_couples", "Couples", "للأزواج"),
      kids: t("audience_kids", "Kids", "للأطفال"),
      families: t("audience_families", "Families", "للعائلات"),
    })[props.audience] ?? "",
);
</script>
