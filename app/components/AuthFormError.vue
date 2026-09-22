<template>
  <!--
    The failures that have no field to attach to: 429 from the auth/OTP throttles, 403 on
    a deactivated account, 500. Laravel sends those as `{ success, message }` with no
    `errors` key at all, so a screen that only renders `errors.<field>` shows the customer
    nothing whatsoever — the button simply re-enables and they try again into the same
    wall. Rate limiting is easy to reach here: `check-identifier` shares the login screen's
    5-per-minute bucket, so a few debounced lookups plus two password attempts is enough.
  -->
  <p
    v-if="message"
    role="alert"
    class="rounded-xl bg-destructive/10 px-4 py-3 text-center text-sm text-destructive"
  >
    {{ message }}
  </p>
</template>

<script setup>
defineProps({
  message: { type: String, default: '' },
})
</script>
