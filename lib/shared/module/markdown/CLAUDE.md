# CLAUDE.md — shared/module/markdown

Themed, source-flexible markdown. Behind every legal document, every
FAQ answer, and the HTML module.

```
markdown/
  markdown_source.dart     — the sealed source (inline / asset / file / url / future)
  markdown_loader.dart     — source → MarkdownLoadResult
  markdown_options.dart    — BEHAVIOUR: which features, which builder slots
  markdown_style.dart      — MarkdownDefaults · MarkdownStyle · Resolved…
  theme/markdown_theme_extension.dart — GlobalMarkdownTheme + the resolve + the sheet
  global_markdown.dart     — GlobalMarkdown
  extensions/              — callouts, code copy, frontmatter, headings, lightbox, math, highlighting
```

## Options are BEHAVIOUR, style is LOOK

`MarkdownOptions` says which features run and which builder slots a
caller filled. `MarkdownStyle` says how the document looks. They were
one class, and the look half was not reachable at all: the style sheet
came from a static `MarkdownTheme.build(context)` — one function, the
same for every app that forks this template, with every spacing and
corner written into it.

- **All-nullable `MarkdownStyle`**, floor in `MarkdownDefaults`,
  app-wide layer in `MyGlobalMarkdownTheme.build(tokens:)`
  (`core/theme/widget_themes/global_markdown_theme.dart`, wired in
  `theme.dart`). Preset: `compact`.
- **It carries no colours and no text styles.** Those come from
  `context.<group>Colors` and the app's type scale when the sheet is
  built, so a document tracks role, brightness, saturation and the
  reader's font size. What the bag holds is the geometry the sheet
  used to hard-code.
- **`styleSheetBuilder` gets the last word**, and is handed the sheet
  the bag produced — so a house adjusts one thing without restating
  the other forty. `MarkdownOptions.styleSheet` still replaces the
  sheet outright for one call site.

## Fixed on the way

- **A failed load rendered NOTHING.** The loader returned the empty
  string for a missing asset, an unreadable file and a URL the network
  never answered — and the widget renders empty as
  `SizedBox.shrink()`. So a missing legal document, a changelog that
  failed to fetch and a genuinely blank file were the same blank
  screen, with nothing said and nothing to retry, on screens whose
  whole job is to show that document. `MarkdownLoadResult` is sealed
  now: `MarkdownLoaded` or `MarkdownLoadFailed`. The default failure
  state is the app's own `GlobalEmptyState` with a Retry that goes
  past the cache; `errorBuilder` replaces it.
- **A caller's `future` loader could throw straight out.** Nothing
  caught it, so it took the whole `FutureBuilder` down. It is a
  `MarkdownLoadFailed` like any other.
- **Only successes are cached.** A cached failure is a failure that
  never retries for the rest of the session. `invalidate(url)` is what
  Retry calls.
- **An empty document is still empty**, not an error — that
  distinction is the whole point of the sealed result.
- **It had no `Semantics` at all.** `semanticLabel` names the document
  with `explicitChildNodes`, so every heading, link and code block
  inside stays reachable rather than being flattened into one string.

## The math path had DUPLICATE KEYS

`MarkdownBody` memoises its parsed tree against `data` + `styleSheet`,
so flipping a feature flag changed the builders and nothing else and
the toggle appeared dead until hot restart. The fix for that was a key
hashing the flag combo — and the math path renders one `MarkdownBody`
per prose segment, side by side in a `Column`. Every one of them got
the SAME key, because the hash covered the options and nothing else:
"Duplicate keys found", every frame, on any document mixing prose with
`$$…$$`.

The segment's index is part of the hash now, and the math blocks
between them are keyed too. Both halves are tested: no duplicate keys
on a mixed document, and a flag flip still forcing a fresh tree —
which is what the key was for in the first place.

## Code is LTR, in every language

A fenced block inherited the app's direction, so in Arabic
`void main() {}` rendered right-aligned and REVERSED — and the copy
button, pinned to the visual right, landed on top of the first
characters. Source is not prose: its direction is a property of the
language it is written in, not of the reader. Both block widgets force
`TextDirection.ltr` around themselves.

Only the code. A document that pinned its whole self to LTR would be
worse than the bug — the prose around a snippet still follows the
reader, and there is a test for each half.

## Does it unload off screen? And why the page used to JUMP

There is no ticker and no clock here: a document off screen costs
memory, not frames, so there is nothing a `pauseWhenOffscreen` would
pause. But in a LAZY list — which is what `ShowcasePage` builds — an
off-screen child is DISPOSED like any other, and scrolling back builds
a new widget from scratch.

That is what made the page move under the reader. A remounted document
rendered a SPINNER for one frame and then the full text, so the block
grew from about seventy points to several hundred and everything below
it shifted. Scroll to the end of a page of documents, come back slowly,
and it happens once per card.

Two things fix it, and both are about not redoing work that was
already done:

- **An inline source is not a LOAD.** `MarkdownSource.inline` is a
  string already in memory, and it went through the loader and a
  `FutureBuilder` like a network fetch. It renders on the first frame
  now. Every document in the showcase — and most in an app — is
  inline.
- **The body cache is STATIC.** A loader is per-widget, so a
  per-instance cache did nothing for a remount. Bodies are held across
  instances, capped at 32, successes only — a cached failure is a
  failure that never retries.

What is left is the PARSE, which happens per mount and is not free. A
very long document in a list still wants
`AutomaticKeepAliveClientMixin` around it.

## It had NO tests

`test/markdown/` covers the bag and the three layers, the theme lerp,
the sheet being built from the bag AND the palette, the
`styleSheetBuilder` override, and each failure path — a missing asset,
a throwing loader, a caller's own error state, and an empty document
NOT being treated as one.

One test-harness note: `rootBundle` caches a load by path, **including
a failed one**, so two tests that share a missing-asset path share its
future. They use different paths.

## Still true

`MarkdownLoader` holds a raw `Dio`, like `HtmlLoader`,
`LegalRepository`, `ConnectivityProbe` and `FeedbackSubmitter`. That is
deliberate and it is the app's convention for fetching an arbitrary
URL: `ApiService` carries the app's base URL, auth headers and its
whole interceptor chain, none of which belong on a request for
somebody else's markdown file.
