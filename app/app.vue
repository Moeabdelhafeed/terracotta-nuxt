<template>
  <ConfigProvider :dir="dir">
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </ConfigProvider>
</template>

<script setup>
import { ConfigProvider } from 'reka-ui'
const { dir } = useLang()
</script>
