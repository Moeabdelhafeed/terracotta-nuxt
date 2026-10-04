/**
 * A one-page PDF holding a single JPEG, stretched over the page.
 *
 * Written by hand rather than pulling in a PDF library: a page that is one picture needs
 * five objects and a cross-reference table, and the JPEG goes in as it is (`/DCTDecode`),
 * so there is nothing to compress or encode. `pageWidth`/`pageHeight` are in points
 * (1/72 inch) — A5 portrait is 420 × 595.
 *
 * @param {Uint8Array} jpeg
 * @returns {Uint8Array}
 */
export const imagePdf = (jpeg, imageWidth, imageHeight, pageWidth, pageHeight) => {
  const encoder = new TextEncoder()
  const parts = []
  const offsets = []
  let length = 0

  const push = (chunk) => {
    const bytes = typeof chunk === 'string' ? encoder.encode(chunk) : chunk
    parts.push(bytes)
    length += bytes.length
  }

  const object = (number, dictionary, stream = null) => {
    offsets[number] = length
    push(`${number} 0 obj\n${dictionary}\n`)
    if (stream) {
      push('stream\n')
      push(stream)
      push('\nendstream\n')
    }
    push('endobj\n')
  }

  const drawing = encoder.encode(`q ${pageWidth} 0 0 ${pageHeight} 0 0 cm /Im0 Do Q`)

  push('%PDF-1.4\n')
  object(1, '<< /Type /Catalog /Pages 2 0 R >>')
  object(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>')
  object(3, `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageWidth} ${pageHeight}] /Resources << /XObject << /Im0 4 0 R >> >> /Contents 5 0 R >>`)
  object(4, `<< /Type /XObject /Subtype /Image /Width ${imageWidth} /Height ${imageHeight} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>`, jpeg)
  object(5, `<< /Length ${drawing.length} >>`, drawing)

  // Every entry exactly 20 bytes, as the format requires.
  const xref = length
  push(`xref\n0 ${offsets.length}\n0000000000 65535 f \n`)
  push(offsets.slice(1).map((offset) => `${String(offset).padStart(10, '0')} 00000 n \n`).join(''))
  push(`trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`)

  const pdf = new Uint8Array(length)
  let at = 0
  for (const part of parts) {
    pdf.set(part, at)
    at += part.length
  }
  return pdf
}
