<template>
  <div class="min-h-svh bg-muted/40 p-6">
    <div class="mx-auto flex max-w-3xl flex-col gap-6">
      <div class="flex items-center justify-between gap-4">
        <Button variant="outline" as-child>
          <NuxtLink to="/">{{ t('home', 'Home', 'الرئيسية') }}</NuxtLink>
        </Button>
      </div>

      <div v-if="pending" class="text-sm text-muted-foreground">
        {{ t('loading', 'Loading...', 'جارٍ التحميل...') }}
      </div>

      <div v-else-if="!page" class="flex flex-col items-center gap-3 py-16 text-center">
        <h1 class="text-2xl font-bold">{{ t('page_not_found', 'Page not found', 'الصفحة غير موجودة') }}</h1>
        <p class="text-sm text-muted-foreground">
          {{ t('page_not_found_note', 'This page does not exist or is unavailable.', 'هذه الصفحة غير موجودة أو غير متاحة.') }}
        </p>
      </div>

      <Card v-else>
        <CardHeader>
          <CardTitle class="text-2xl">{{ page.name }}</CardTitle>
        </CardHeader>
        <CardContent>
          <AppImage
            v-if="page.image?.image_api"
            :src="page.image"
            :alt="page.name"
            class="mb-6 aspect-video w-full rounded-lg object-cover"
          />
          <div
            class="prose prose-sm max-w-none dark:prose-invert [&_a]:text-primary [&_a]:underline [&_h2]:mt-6 [&_h2]:mb-2 [&_h2]:text-xl [&_h2]:font-semibold [&_h3]:mt-4 [&_h3]:mb-2 [&_h3]:font-semibold [&_li]:my-1 [&_p]:my-3 [&_ul]:list-disc [&_ul]:ps-6"
            v-html="page.content"
          />
        </CardContent>
      </Card>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ name: 'page' })

const route = useRoute()
const { t } = useLang()
const { page, pending } = usePage(() => route.params.slug)
</script>
