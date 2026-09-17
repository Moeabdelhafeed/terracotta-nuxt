# PDF Viewer — Future Work

The module is DONE as a viewer. Items 13, 14, 15, 17 and document
metadata all shipped — see `CLAUDE.md` for what each turned into and
what it cannot do, and its "Known gaps" for the live caveats.

What is below is what nobody has asked for yet. None of it is needed
for the module to be used; read this before adding anything large so a
half-built annotation layer does not appear next to a finished
reader.

---

## 16. A11y sweep — mostly DONE

Semantics, touch targets and the string sweep have shipped. What
remains is the part that needs a device: reading ORDER, and confirming
a "go to page N" announcement actually fires on TalkBack and
VoiceOver rather than merely being wired.

---

## Annotations, forms, signatures

Rendering annotations is a toggle (`PdfStyle.annotationMode`).
EDITING them is not, and none of it is here: ink, highlight, free
text, form filling, signature capture. Each needs a writer as well as
a reader, which pdfrx does not give us — the engine renders.

---

## What shipped, and what it cannot do

### 13. Open from device picker — DONE
`GlobalPdfViewer.pickFromDevice()` / `.openFromDevice(context)`.
Android scoped-storage notes still want a write-up in `docs/setup/`.

### 14. Annotation rendering toggle — DONE
`PdfStyle.annotationMode`, mirroring pdfrx's enum so the engine type
does not escape.

### 15. Cache management — DONE
`PdfCache.clearAll()` / `.clearFor(persistKey)`, plus `documentCount`
and `byteCount` for a Settings row that has to say what clearing would
free. The on-DISK side is not covered: pdfrx's own temp files are its
business, and this module's caches are all in memory.

### 17. Keyboard shortcuts — DONE
`⌘F`, arrows, `+`/`-`, `⌘0`, `R`, `⌘P`, `Esc`. On every platform, not
just desktop.

### Document metadata — DONE, with limits
`pdf_metadata.dart` parses `/Info` out of the bytes, because
pdfrx-engine still does not expose it. It cannot read a document whose
cross-reference is a compressed STREAM with the `/Info` reference
inside it, and it refuses ENCRYPTED documents outright rather than
returning ciphertext that looks like a title. Upstream exposure of
`PdfDocument.info` would replace the whole file.
