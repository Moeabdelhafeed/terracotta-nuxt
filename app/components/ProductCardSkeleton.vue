<template>
  <div class="overflow-hidden rounded-card border bg-card">
    <AppSkeleton class="aspect-square w-full !rounded-none" />
    <div class="p-3">
      <AppSkeleton class="h-4 w-3/4" />
      <AppSkeleton class="mt-2 h-4 w-1/2" />
      <AppSkeleton class="mt-1 h-7 w-1/3" />
    </div>
  </div>
</template>

<script setup>
/** The loading shape of <ProductCard>: square image, two title lines, price line. */
</script>
