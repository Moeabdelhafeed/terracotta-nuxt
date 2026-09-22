<template>
  <div class="flex flex-col gap-4">
    <!-- The link itself, visible and selectable: on a desktop with no share sheet and a
         blocked clipboard, reading it off the screen is the last resort that always works. -->
    <div class="flex items-center gap-2 rounded-2xl border bg-brand-mist/40 p-2 ps-4">
      <code class="min-w-0 flex-1 truncate font-mono text-xs text-muted-foreground" dir="ltr">{{ shareUrl }}</code>
      <Button type="button" variant="outline" size="sm" class="h-9 shrink-0 rounded-xl" @click="copy">
        <LucideCopy class="size-3.5" />
        {{ t('copy_link', 'Copy', 'نسخ') }}
      </Button>
    </div>

    <div class="flex flex-col gap-3 sm:flex-row">
      <Button type="button" class="h-12 flex-1 rounded-xl bg-brand-terracotta text-base hover:bg-brand-terracotta/90" @click="share">
        <LucideShare2 class="size-4" />
        {{ t('gift_share', 'Share the link', 'مشاركة الرابط') }}
      </Button>

      <Button as-child type="button" variant="outline" class="h-12 flex-1 rounded-xl text-base">
        <a :href="whatsappHref" target="_blank" rel="noopener noreferrer">
          <LucideMessageCircle class="size-4" />
          {{ t('gift_share_whatsapp', 'WhatsApp', 'واتساب') }}
        </a>
      </Button>
    </div>
  </div>
</template>

<script setup>
/**
 * How a gift actually reaches someone. `share_url` is built by the server from
 * `GIFT_SHARE_BASE_URL` and is used exactly as given — rebuilding it from the token here
 * would silently point at the wrong host the moment that setting changes.
 */
const props = defineProps({
  shareUrl: { type: String, required: true },
  /** Notes on the gift; only used to pre-address WhatsApp and to word the message. */
  recipientPhone: { type: String, default: '' },
  recipientName: { type: String, default: '' },
})

const { t } = useLang('web', 'gifts')
const toast = useToast()

const shareText = computed(() => t(
  'gift_share_text',
  'I sent you a Terracotta gift — open it here: :url',
  'أرسلت لك هدية من تيراكوتا — افتحها من هنا: :url',
  { url: props.shareUrl },
))

// wa.me wants bare digits; an empty number opens the chooser instead of a chat.
const whatsappHref = computed(() => {
  const digits = String(props.recipientPhone ?? '').replace(/\D/g, '')
  return `https://wa.me/${digits}?text=${encodeURIComponent(shareText.value)}`
})

const copy = async () => {
  try {
    await navigator.clipboard.writeText(props.shareUrl)
    toast.success(t('gift_link_copied', 'Link copied.', 'تم نسخ الرابط.'))
  } catch {
    toast.error(t('gift_link_copy_failed', 'Could not copy — select the link and copy it by hand.', 'تعذّر النسخ — حدّد الرابط وانسخه يدويًا.'))
  }
}

/**
 * The OS share sheet where there is one (every phone, some desktops), the clipboard
 * everywhere else. `navigator.share` is only read on click, so SSR and hydration render
 * the same button either way.
 */
const share = async () => {
  if (import.meta.client && navigator.share) {
    try {
      await navigator.share({ title: t('gift_share_title', 'A gift for you', 'هدية لك'), text: shareText.value, url: props.shareUrl })
      return
    } catch (err) {
      // The user dismissing the sheet is not a failure — do not fall through to a copy
      // they did not ask for.
      if (err?.name === 'AbortError') return
    }
  }
  await copy()
}
</script>
