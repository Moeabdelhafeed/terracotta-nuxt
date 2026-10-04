/**
 * The gift as a keepsake card, saved as a PDF — "save my gift" on the gift link page.
 *
 * Drawn on a canvas, not printed from the page: the browser shapes Arabic correctly on a
 * canvas, which PDF libraries without bundled Arabic fonts do not, and the visitor gets
 * a file straight away instead of a print dialog to find "Save as PDF" in. The canvas
 * becomes a JPEG and imagePdf() wraps it in one A5 page.
 *
 * Every line arrives already worded and translated by the page. The gift's link is NOT
 * on the card: whoever holds the token can claim the gift, and a saved file gets forwarded.
 */
const WIDTH = 1240 // A5 portrait at ~210 dpi
const HEIGHT = 1754
const PAGE_WIDTH = 420 // points
const PAGE_HEIGHT = 595

// The page's own colours (--brand-blush, --brand-ink, --muted-foreground) in sRGB: a
// canvas can't be relied on to read oklch.
const BLUSH = '#e7938d'
const INK = '#290802'
const MUTED = '#776862'
const FONT = 'Kufam, ui-sans-serif, system-ui, sans-serif'

// BrandMark.vue's path, in its 21 × 29 viewBox.
const MARK = 'M10.3177 28.998C13.3166 28.998 17.2851 27.7871 18.9219 22.8903C19.026 22.5782 18.7218 22.2858 18.4136 22.3977C17.8229 22.6116 16.9691 22.8295 16.1468 22.7078C15.7876 22.6548 15.6914 22.1798 15.9996 21.9875C16.0643 21.9463 16.1114 21.9168 16.133 21.905C16.8573 21.4968 17.5481 21.0258 18.1781 20.4821C19.7737 19.1063 21.0082 17.126 20.5352 14.9494C20.2173 13.4912 19.4342 12.1429 18.341 11.1301C17.6031 10.4452 16.6708 10.0252 15.8857 9.39713C15.1007 8.76909 14.4098 8.03309 13.9231 7.15776C12.6179 4.81632 13.4344 2.52396 15.0026 0.56328C15.1831 0.335614 15.0202 0 14.7278 0H10.3197H5.91159C5.62112 0 5.45626 0.335614 5.63682 0.56328C6.31786 1.41507 7.11862 2.55536 7.33058 3.63481C7.57788 4.89876 7.26385 6.23728 6.61029 7.33243C6.10982 8.17244 5.4229 8.88488 4.65158 9.48152C3.89204 10.0703 3.00492 10.4746 2.29641 11.1321C1.20322 12.1448 0.420125 13.4951 0.102177 14.9514C-0.37082 17.128 0.863678 19.1083 2.45931 20.4841C3.08931 21.0277 3.78017 21.4988 4.50438 21.907C4.52401 21.9188 4.57307 21.9482 4.63784 21.9894C4.94597 22.1818 4.8498 22.6567 4.49064 22.7097C3.67026 22.8314 2.81455 22.6136 2.22379 22.3996C1.91369 22.2878 1.60948 22.5802 1.71546 22.8923C3.35231 27.7891 7.32077 29 10.3197 29L10.3177 28.998Z'

/** Breaks text into lines that fit, at spaces — or anywhere, for one word too long to fit. */
const wrap = (ctx, text, maxWidth, maxLines) => {
  const lines = []
  let line = ''
  for (const word of text.split(/\s+/).filter(Boolean)) {
    const candidate = line ? `${line} ${word}` : word
    if (ctx.measureText(candidate).width <= maxWidth) {
      line = candidate
      continue
    }
    if (line) lines.push(line)
    line = ''
    for (const char of Array.from(word)) {
      if (ctx.measureText(line + char).width > maxWidth && line) {
        lines.push(line)
        line = ''
      }
      line += char
    }
  }
  if (line) lines.push(line)

  if (lines.length > maxLines) {
    lines.length = maxLines
    lines[maxLines - 1] = `${lines[maxLines - 1].replace(/\s*\S{0,3}$/, '')}…`
  }
  return lines
}

/**
 * @param {{ from: string, amount: string, message?: string, to?: string, footer?: string }} card
 * @param {{ dir?: 'ltr'|'rtl', fileName?: string }} options
 */
export const saveGiftPdf = async (card, { dir = 'ltr', fileName = 'terracotta-gift.pdf' } = {}) => {
  const sample = [card.from, card.amount, card.message, card.to, card.footer].filter(Boolean).join(' ')
  // The card is drawn once, so the face has to be there first — including its Arabic
  // subset, which the browser only fetches for text that needs it.
  await Promise.all(['400 52px', '500 40px', '900 170px'].map((weight) => document.fonts.load(`${weight} Kufam`, sample))).catch(() => {})

  const canvas = document.createElement('canvas')
  canvas.width = WIDTH
  canvas.height = HEIGHT
  const ctx = canvas.getContext('2d')
  ctx.direction = dir
  ctx.textAlign = 'center'

  ctx.fillStyle = BLUSH
  ctx.fillRect(0, 0, WIDTH, HEIGHT)

  // The mark, white on the blush, as the page paints it.
  const markScale = 170 / 29
  ctx.save()
  ctx.translate(WIDTH / 2 - (21 * markScale) / 2, 150)
  ctx.scale(markScale, markScale)
  ctx.fillStyle = '#ffffff'
  ctx.fill(new Path2D(MARK))
  ctx.restore()

  // Lay the card out before drawing it, so it is exactly as tall as what it holds.
  const cardX = 120
  const cardWidth = WIDTH - cardX * 2
  const padding = 130
  ctx.font = `400 52px ${FONT}`
  const messageLines = card.message ? wrap(ctx, `“${card.message}”`, cardWidth - padding * 1.5, 8) : []
  const blocks = [
    card.from && { text: card.from, font: `400 46px ${FONT}`, size: 46, color: MUTED, before: 0 },
    { text: card.amount, font: `900 170px ${FONT}`, size: 170, color: BLUSH, before: 70 },
    ...messageLines.map((text, index) => ({ text, font: `400 52px ${FONT}`, size: 52, color: INK, before: index ? 30 : 90 })),
    card.to && { text: card.to, font: `400 44px ${FONT}`, size: 44, color: MUTED, before: 80 },
  ].filter(Boolean)

  const cardHeight = padding * 2 + blocks.reduce((sum, block) => sum + block.before + block.size, 0)
  const top = 420
  const bottom = HEIGHT - 220
  const cardY = Math.max(top, (top + bottom) / 2 - cardHeight / 2)

  ctx.save()
  ctx.shadowColor = 'rgba(41, 8, 2, 0.18)'
  ctx.shadowBlur = 60
  ctx.shadowOffsetY = 24
  ctx.fillStyle = '#ffffff'
  ctx.beginPath()
  if (ctx.roundRect) ctx.roundRect(cardX, cardY, cardWidth, cardHeight, 64)
  else ctx.rect(cardX, cardY, cardWidth, cardHeight)
  ctx.fill()
  ctx.restore()

  let y = cardY + padding
  for (const block of blocks) {
    y += block.before + block.size
    ctx.font = block.font
    ctx.fillStyle = block.color
    ctx.fillText(block.text, WIDTH / 2, y)
  }

  if (card.footer) {
    ctx.font = `500 40px ${FONT}`
    ctx.fillStyle = '#ffffff'
    ctx.fillText(card.footer, WIDTH / 2, HEIGHT - 120)
  }

  const jpeg = await new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.92))
  const pdf = imagePdf(new Uint8Array(await jpeg.arrayBuffer()), WIDTH, HEIGHT, PAGE_WIDTH, PAGE_HEIGHT)

  const url = URL.createObjectURL(new Blob([pdf], { type: 'application/pdf' }))
  const link = Object.assign(document.createElement('a'), { href: url, download: fileName })
  document.body.append(link)
  link.click()
  link.remove()
  // Some browsers start the download after the click returns.
  setTimeout(() => URL.revokeObjectURL(url), 30_000)
}
