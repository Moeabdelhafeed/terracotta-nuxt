<template>
  <!--
    For pages that are a destination in themselves — a gift link opened by somebody who
    has never heard of Terracotta. No floating nav, no footer, and no ScrollSmoother: the
    page is one screen, and the site's chrome would only offer somewhere else to go.
    `lang`/`dir` still have to be set here; they live in the default layout otherwise.
  -->
  <Html :lang="code" :dir="dir" class="light">
    <Body>
      <slot />
    </Body>
  </Html>
</template>

<script setup>
const { code, dir } = useLang()
</script>
