<template>
  <!-- Route stub: replaced by the domain builder. Keeps the path reserved so links resolve. -->
  <main class="min-h-svh bg-background pb-28">
    <div class="mx-auto max-w-6xl px-6 py-16">
      <h1 class="font-display text-3xl font-semibold sm:text-4xl">{{ t('cart_title', 'My cart', 'عربيتي') }}</h1>
      <p class="mt-3 text-muted-foreground">{{ t('coming_soon', 'Coming soon.', 'قريبًا.') }}</p>
    </div>
  </main>
</template>

<script setup>
definePageMeta({
  middleware: ['auth-mode', 'require-registered'],
  name: 'cart',
})

const { t } = useLang('web', 'general')
</script>
