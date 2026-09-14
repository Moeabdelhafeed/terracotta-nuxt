<template>
  <span
    v-if="label"
    class="inline-flex w-fit items-center gap-1.5 rounded-md bg-brand-blush/40 px-3 py-1 text-xs font-medium text-brand-rust"
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
