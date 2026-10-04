/**
 * The gift page, saved as a PDF — "save my gift" on the gift link page.
 *
 * A landscape A5 page, drawn on a canvas to the page's own measurements, not printed from it: the browser
 * shapes Arabic correctly on a canvas, which PDF libraries without bundled Arabic fonts do
 * not, and the visitor gets a file at once instead of a print dialog. The canvas becomes a
 * JPEG, imagePdf() wraps it in one page, and every button drawn on it is a real link in
 * the PDF: Claim opens the gift, the store buttons open the stores.
 *
 * The page lays the gift out; this redraws that layout. Every line arrives already worded
 * and translated by the page, so the two say the same thing in the same language. The one
 * thing left out is the "save as PDF" button itself.
 */
// A5 landscape at ~210 dpi: the card sits in the middle of a wide page, as the gift page
// does on a computer screen.
const WIDTH = 1754;
const HEIGHT = 1240;
const PAGE_WIDTH = 595; // points
const PAGE_HEIGHT = 420;
const MARGIN = 100; // the least the page keeps clear above and below the content
const UNIT = 2.4; // canvas pixels per CSS pixel, shrunk when a long message needs the room

// The page's colours (--brand-blush, --brand-ink, --muted-foreground, --border) in sRGB: a
// canvas can't be relied on to read oklch.
const BLUSH = "#e7938d";
const INK = "#290802";
const MUTED = "#776862";
const BORDER = "#e5e5e5";
const FONT = "Kufam, ui-sans-serif, system-ui, sans-serif";

// BrandMark.vue's path, in its 21 × 29 viewBox.
const MARK =
  "M10.3177 28.998C13.3166 28.998 17.2851 27.7871 18.9219 22.8903C19.026 22.5782 18.7218 22.2858 18.4136 22.3977C17.8229 22.6116 16.9691 22.8295 16.1468 22.7078C15.7876 22.6548 15.6914 22.1798 15.9996 21.9875C16.0643 21.9463 16.1114 21.9168 16.133 21.905C16.8573 21.4968 17.5481 21.0258 18.1781 20.4821C19.7737 19.1063 21.0082 17.126 20.5352 14.9494C20.2173 13.4912 19.4342 12.1429 18.341 11.1301C17.6031 10.4452 16.6708 10.0252 15.8857 9.39713C15.1007 8.76909 14.4098 8.03309 13.9231 7.15776C12.6179 4.81632 13.4344 2.52396 15.0026 0.56328C15.1831 0.335614 15.0202 0 14.7278 0H10.3197H5.91159C5.62112 0 5.45626 0.335614 5.63682 0.56328C6.31786 1.41507 7.11862 2.55536 7.33058 3.63481C7.57788 4.89876 7.26385 6.23728 6.61029 7.33243C6.10982 8.17244 5.4229 8.88488 4.65158 9.48152C3.89204 10.0703 3.00492 10.4746 2.29641 11.1321C1.20322 12.1448 0.420125 13.4951 0.102177 14.9514C-0.37082 17.128 0.863678 19.1083 2.45931 20.4841C3.08931 21.0277 3.78017 21.4988 4.50438 21.907C4.52401 21.9188 4.57307 21.9482 4.63784 21.9894C4.94597 22.1818 4.8498 22.6567 4.49064 22.7097C3.67026 22.8314 2.81455 22.6136 2.22379 22.3996C1.91369 22.2878 1.60948 22.5802 1.71546 22.8923C3.35231 27.7891 7.32077 29 10.3197 29L10.3177 28.998Z";

// BrandLine.vue's curve: the sweep behind the card, in its 1601 × 922 viewBox.
const LINE =
  "M533.499 -308.5C561.499 -140.5 487.899 246.8 -30.5009 452C-678.501 708.5 240.999 -304.5 884.499 -146.5C1528 11.5 1738 466.5 1512 1153.5C1286 1840.5 349.5 489.5 -89.5 497.5";

/** Breaks text into lines that fit, at spaces — or anywhere, for one word too long to fit. */
const wrap = (ctx, text, maxWidth, maxLines) => {
  const lines = [];
  let line = "";
  for (const word of text.split(/\s+/).filter(Boolean)) {
    const candidate = line ? `${line} ${word}` : word;
    if (ctx.measureText(candidate).width <= maxWidth) {
      line = candidate;
      continue;
    }
    if (line) lines.push(line);
    line = "";
    for (const char of Array.from(word)) {
      if (ctx.measureText(line + char).width > maxWidth && line) {
        lines.push(line);
        line = "";
      }
      line += char;
    }
  }
  if (line) lines.push(line);

  if (lines.length > maxLines) {
    lines.length = maxLines;
    lines[maxLines - 1] = `${lines[maxLines - 1].replace(/\s*\S{0,3}$/, "")}…`;
  }
  return lines;
};

const roundedRect = (ctx, x, y, width, height, radius) => {
  ctx.beginPath();
  if (ctx.roundRect) ctx.roundRect(x, y, width, height, radius);
  else ctx.rect(x, y, width, height);
};

/**
 * @param {{
 *   from: string, amount: string, message?: string, to?: string,
 *   claim?: { label: string, url: string } | null,
 *   stores?: { heading: string, items: { label: string, url: string }[] } | null,
 *   claimed?: string | null,
 *   explore?: { label: string, url: string } | null,
 * }} page
 * @param {{ dir?: 'ltr'|'rtl', fileName?: string }} options
 */
export const saveGiftPdf = async (
  page,
  { dir = "ltr", fileName = "terracotta-gift.pdf" } = {},
) => {
  // Everything below is measured in the page's CSS pixels times `unit`, so the whole
  // layout can be scaled down in one step when it is taller than the page.
  let unit = UNIT;
  const px = (css) => css * unit;
  const font = (weight, size) => `${weight} ${px(size)}px ${FONT}`;

  const sample = [
    page.from,
    page.amount,
    page.message,
    page.to,
    page.claim?.label,
    page.claimed,
    page.explore?.label,
    page.stores?.heading,
    ...(page.stores?.items ?? []).map((item) => item.label),
  ]
    .filter(Boolean)
    .join(" ");
  // The page is drawn once, so the face has to be there first — including its Arabic
  // subset, which the browser only fetches for text that needs it.
  await Promise.all(
    ["400", "500", "900"].map((weight) =>
      document.fonts.load(font(weight, 16), sample),
    ),
  ).catch(() => {});

  const canvas = document.createElement("canvas");
  canvas.width = WIDTH;
  canvas.height = HEIGHT;
  const ctx = canvas.getContext("2d");

  // ── Lay out, top to bottom, in the page's own spacing (Tailwind units in CSS px) ──────
  const layout = () => {
    const cardWidth = px(448); // max-w-md
    const cardX = (WIDTH - cardWidth) / 2;
    const padding = px(40); // p-10
    const inner = cardWidth - padding * 2;
    const items = []; // { kind, top, … } with `top` measured from the card's top edge

    let y = padding;
    const text = (
      value,
      weight,
      size,
      lineHeight,
      color,
      gap,
      maxLines = 1,
    ) => {
      if (!value) return;
      ctx.font = font(weight, size);
      const lines = maxLines > 1 ? wrap(ctx, value, inner, maxLines) : [value];
      y += px(gap);
      items.push({
        kind: "text",
        lines,
        font: font(weight, size),
        color,
        top: y,
        lineHeight: px(lineHeight),
      });
      y += lines.length * px(lineHeight);
    };

    text(page.from, 400, 14, 20, MUTED, 0); // text-sm
    text(page.amount, 900, 48, 48, BLUSH, 16); // mt-4 text-5xl leading-none
    if (page.message) text(`“${page.message}”`, 400, 18, 29.25, INK, 24, 10); // mt-6 text-lg leading-relaxed
    text(page.to, 400, 14, 20, MUTED, 16); // mt-4 text-sm

    y += px(32); // my-8 divider
    items.push({ kind: "divider", top: y });
    y += px(1) + px(32);

    if (page.claim) {
      items.push({
        kind: "button",
        top: y,
        height: px(56),
        label: page.claim.label,
        url: page.claim.url,
      }); // h-14
      y += px(56);
      if (page.stores?.items?.length) {
        text(page.stores.heading, 400, 12, 16, MUTED, 24); // mt-6 text-xs
        y += px(12); // mt-3
        ctx.font = font(500, 14);
        const pills = page.stores.items.map((item) => ({
          ...item,
          width: ctx.measureText(item.label).width + px(32),
        }));
        // flex-wrap gap-3 justify-center, as rows.
        const rows = [[]];
        let rowWidth = 0;
        for (const pill of pills) {
          const gap = rows.at(-1).length ? px(12) : 0;
          if (gap && rowWidth + gap + pill.width > inner) {
            rows.push([]);
            rowWidth = 0;
          }
          rowWidth += (rows.at(-1).length ? px(12) : 0) + pill.width;
          rows.at(-1).push(pill);
        }
        for (const [index, row] of rows.entries()) {
          if (index) y += px(12);
          items.push({ kind: "pills", top: y, row });
          y += px(44); // h-11
        }
      }
    } else if (page.claimed) {
      ctx.font = font(500, 14);
      const lines = wrap(ctx, page.claimed, inner - px(32), 4);
      const height = px(16) * 2 + lines.length * px(20);
      items.push({ kind: "note", top: y, height, lines });
      y += height;
    }
    y += padding;
    const cardHeight = y;

    // The mark above, the explore link below, all centred in the page.
    const markHeight = px(64);
    const content =
      markHeight + px(32) + cardHeight + (page.explore ? px(32) + px(20) : 0);

    return {
      cardWidth,
      cardX,
      padding,
      inner,
      items,
      cardHeight,
      markHeight,
      content,
    };
  };

  // A long message makes the card taller than a landscape page; everything scales together,
  // so one pass at the smaller size fits it exactly.
  let plan = layout();
  if (plan.content > HEIGHT - MARGIN * 2) {
    unit *= (HEIGHT - MARGIN * 2) / plan.content;
    plan = layout();
  }
  const {
    cardWidth,
    cardX,
    padding,
    inner,
    items,
    cardHeight,
    markHeight,
    content,
  } = plan;
  const markWidth = (markHeight * 21) / 29;
  const height = HEIGHT;

  ctx.direction = dir;
  ctx.textAlign = "center";
  ctx.textBaseline = "middle";

  const top = (height - content) / 2;
  const cardY = top + markHeight + px(32);
  const links = [];

  // ── Draw ─────────────────────────────────────────────────────────────────────────────
  ctx.fillStyle = BLUSH;
  ctx.fillRect(0, 0, WIDTH, height);

  // The brand line behind everything, cropped to the page like the site's `slice`.
  const lineScale = Math.max(WIDTH / 1601, height / 922);
  ctx.save();
  ctx.translate((WIDTH - 1601 * lineScale) / 2, (height - 922 * lineScale) / 2);
  ctx.scale(lineScale, lineScale);
  ctx.strokeStyle = "rgba(255, 255, 255, 0.4)";
  ctx.lineWidth = px(2) / lineScale;
  ctx.stroke(new Path2D(LINE));
  ctx.restore();

  ctx.save();
  ctx.translate(WIDTH / 2 - markWidth / 2, top);
  ctx.scale(markHeight / 29, markHeight / 29);
  ctx.fillStyle = "#ffffff";
  ctx.fill(new Path2D(MARK));
  ctx.restore();

  ctx.save();
  ctx.shadowColor = "rgba(0, 0, 0, 0.2)";
  ctx.shadowBlur = px(40);
  ctx.shadowOffsetY = px(20);
  ctx.fillStyle = "#ffffff";
  roundedRect(ctx, cardX, cardY, cardWidth, cardHeight, px(32));
  ctx.fill();
  ctx.restore();

  const centre = WIDTH / 2;
  for (const item of items) {
    const itemTop = cardY + item.top;

    if (item.kind === "text") {
      ctx.font = item.font;
      ctx.fillStyle = item.color;
      item.lines.forEach((line, index) =>
        ctx.fillText(line, centre, itemTop + item.lineHeight * (index + 0.5)),
      );
    } else if (item.kind === "divider") {
      ctx.fillStyle = BORDER;
      ctx.fillRect(cardX + padding, itemTop, inner, px(1));
    } else if (item.kind === "button") {
      ctx.fillStyle = BLUSH;
      roundedRect(ctx, cardX + padding, itemTop, inner, item.height, px(16));
      ctx.fill();
      ctx.font = font(500, 16);
      ctx.fillStyle = "#ffffff";
      ctx.fillText(item.label, centre, itemTop + item.height / 2);
      links.push({
        x: cardX + padding,
        y: itemTop,
        width: inner,
        height: item.height,
        url: item.url,
      });
    } else if (item.kind === "pills") {
      // A right-to-left row starts at the right, as the page's flex row does.
      const ordered = dir === "rtl" ? [...item.row].reverse() : item.row;
      const rowWidth =
        ordered.reduce((sum, pill) => sum + pill.width, 0) +
        px(12) * (ordered.length - 1);
      let x = centre - rowWidth / 2;
      for (const pill of ordered) {
        ctx.strokeStyle = BORDER;
        ctx.lineWidth = px(1);
        roundedRect(ctx, x, itemTop, pill.width, px(44), px(12));
        ctx.stroke();
        ctx.font = font(500, 14);
        ctx.fillStyle = INK;
        ctx.fillText(pill.label, x + pill.width / 2, itemTop + px(22));
        links.push({
          x,
          y: itemTop,
          width: pill.width,
          height: px(44),
          url: pill.url,
        });
        x += pill.width + px(12);
      }
    } else if (item.kind === "note") {
      ctx.fillStyle = "rgba(231, 147, 141, 0.15)";
      roundedRect(ctx, cardX + padding, itemTop, inner, item.height, px(16));
      ctx.fill();
      ctx.font = font(500, 14);
      ctx.fillStyle = BLUSH;
      item.lines.forEach((line, index) =>
        ctx.fillText(line, centre, itemTop + px(16) + px(20) * (index + 0.5)),
      );
    }
  }

  if (page.explore) {
    const exploreY = cardY + cardHeight + px(32);
    ctx.font = font(400, 14);
    ctx.fillStyle = "rgba(255, 255, 255, 0.8)";
    ctx.fillText(page.explore.label, centre, exploreY + px(10));
    const width = ctx.measureText(page.explore.label).width;
    links.push({
      x: centre - width / 2,
      y: exploreY,
      width,
      height: px(20),
      url: page.explore.url,
    });
  }

  const jpeg = await new Promise((resolve) =>
    canvas.toBlob(resolve, "image/jpeg", 0.92),
  );
  const pdf = imagePdf(
    new Uint8Array(await jpeg.arrayBuffer()),
    WIDTH,
    HEIGHT,
    PAGE_WIDTH,
    PAGE_HEIGHT,
    links,
  );

  const url = URL.createObjectURL(new Blob([pdf], { type: "application/pdf" }));
  const link = Object.assign(document.createElement("a"), {
    href: url,
    download: fileName,
  });
  document.body.append(link);
  link.click();
  link.remove();
  // Some browsers start the download after the click returns.
  setTimeout(() => URL.revokeObjectURL(url), 30_000);
};
