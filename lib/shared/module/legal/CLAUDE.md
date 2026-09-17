# CLAUDE.md — shared/module/legal

The About hub and the document screen behind it.

```
legal/
  legal_style.dart         — LegalDefaults · LegalStyle · Resolved…
  theme/legal_theme.dart   — GlobalLegalTheme + the resolve
  legal_index_page.dart    — LegalIndexPage, the `/about` route
  legal_screen.dart        — LegalScreen, one `/legal/:slug` document
core/legal/
  legal_page.dart · legal_content.dart · legal_repository.dart
```

## The About page was the least finished screen in the app

Which is worth saying plainly, because it is the screen an adopter
shows a lawyer and an app reviewer:

- **Its own chrome was hard-coded English** — `'About'`,
  `'Legal & Information'`, `'App'`, `'Version … • Build …'` — on a page
  whose entire list is localized document titles. `LegalStrings`
  already had `titleAbout`; the page simply was not using it.
- **`showLicensePage(applicationName: 'App')`.** Flutter's own licence
  page — the one screen here that nobody wrote — introduced the app as
  "App". It takes the real name and version from `PackageInfo` now.
- **The tile was a `Material` + `InkWell` + `Container` stack**,
  drawing its own fill, ripple, border and corner. `GlobalContainer`
  does all four, and a tappable one is already one button node to a
  screen reader.
- **Twenty-one written-in numbers** and no theme extension.
- **The doc comment promised a `GlobalGrid` split on tablets.** There
  was never one in the build.

## The bag

- **All-nullable `LegalStyle`**, floor in `LegalDefaults`, app-wide
  layer in `MyGlobalLegalTheme.build(tokens:)`
  (`core/theme/widget_themes/global_legal_theme.dart`, wired in
  `theme.dart`). Preset: `compact`.
- **`markBuilder` is the seam an adopter fills.** The default app mark
  is a gradient plate with a Flutter glyph on it — unmistakably a
  PLACEHOLDER, which is right for a template and wrong for a shipped
  app. It lives on the bag so a house replaces it once, from the
  theme, instead of editing the page.
- **No colours in it.** They resolve from `context.<group>Colors` at
  build time.
- **The version goes through `AppNumbers`** — a version is digits, and
  Arabic writes its own.

## The page's own edges

- **The bottom inset belongs to the LIST, not to a `SafeArea`.** A
  `SafeArea` SHORTENS the viewport, so the content stopped above the
  gesture bar and left a dead strip under it. `bottom: false`, and the
  inset moves into the scroll padding — the content scrolls UNDER the
  bar and merely ENDS clear of it. The feedback form had the same
  thing and got the same fix.
- **`GlobalContainer.shell` clamps the WIDTH; it adds no margin.**
  Without `pagePadding` every card ran corner to corner on a phone —
  the clamp only does anything once the window is wider than the
  reading measure.

## The version is copyable

"What version are you on?" is the first thing support asks, and the
answer was on screen but not in the reader's clipboard — so they
retyped it, or guessed. The header card is the target (one node, not a
button nested inside a card), with a copy glyph as a hint.

What it copies is the RAW numbers, not the localized ones: this goes
into a support ticket, where Arabic-Indic digits would be unreadable
to whoever receives it. The screen keeps the localized version;
`AppNumbers` is for reading, not for reporting.

## The document screen takes the bag too

An earlier note here claimed it "was already fine". It was going
through its modules — `LegalStrings`, `GlobalAppBar`,
`GlobalContainer`, `GlobalProgress`, markdown / html — but it never
took the shared bag, and it had the same edge problem the About page
did: `GlobalContainer.prose` bounds the WIDTH and adds no margin, so a
document ran to both screen edges on a phone. It resolves the bag once
now and pads from it, so the list and the document it links to are one
screen's worth of numbers rather than two.

## The origin badge

Debug-only, and it answers one question while you are working on the
content pipeline: is this the copy shipped in the bundle, the one the
backend served, a remote markdown file, or something the cache kept?
Getting that wrong looks like "my edit did nothing".

It was a hand-rolled pill — a `Container` with its own fill and corner
around a raw `Text` reading `source: bundled`. It is a `GlobalChip`
now, with a GLYPH per origin so the four are told apart at a glance
rather than by reading a lowercase word, and labels that say what they
mean. No `onPressed`: it is a report, so it takes no focus and offers
a screen reader nothing to do.

`LegalScreen` used `LegalStrings`, `GlobalAppBar`, `GlobalContainer`,
`GlobalProgress` and the markdown / html modules before this pass. It
takes the shared bag for its geometry and was otherwise left alone.

`test/legal/legal_adoption_test.dart` fails if the English literals,
the hand-rolled ripple surface, the raw `Text` or the `'App'` licence
name come back.
