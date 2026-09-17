# CLAUDE.md — lib/shared/module/empty_state

`GlobalEmptyState` — "nothing here yet": a glyph or illustration, a
title, an optional line of explanation, and up to two actions.

```dart
GlobalEmptyState(
  title: 'No invoices',
  subtitle: 'Anything you send will show up here.',
  primaryAction: GlobalFilledButton(text: 'New invoice', onPressed: …),
)
```

## Contracts

- **Style is the themeable bag `EmptyStateStyle`** — every field
  nullable, with `defaults` + `mergedWith` + `copyWith`, materialized
  once per build by `style.resolve(context, variant:)` into a
  `ResolvedEmptyStateStyle`.
- **`resolve` takes the VARIANT.** Three fields — glyph size, spacing,
  padding — mean different numbers on a full page and inside a card, and
  the bag cannot know which it is in. That is also why
  `EmptyStateStyle.defaults` carries no sizes: a compile-time floor
  would have to pick one variant and be wrong for the other.
- **Resolution order**: `caller > GlobalEmptyStateTheme.style >
  EmptyStateStyle.defaults`, then colours from `context.<group>Colors`
  and sizes from the variant.
- **`defaults` carries NO colours.** The title and subtitle used to come
  from `Theme.of(context).colorScheme.onSurface` — the one place in this
  module that bypassed the palette entirely.
- **Every hard-coded number lives in `EmptyStateDefaults`.**

## Gotchas

- **The entrance is armed in BUILD, not `initState`.** Whether it runs
  depends on `MediaQuery.disableAnimationsOf`, which cannot be read from
  `initState` — so the controller built there ran the fade-and-rise
  whatever the device asked for. `_armEntrance` starts it on the first
  build that can see a `MediaQuery`, once.
- **Reduced motion turns the entrance OFF, not down.** The block simply
  is there. Guard: "is SKIPPED under reduced motion".
- **The fade keeps its semantics** (`alwaysIncludeSemantics: true`). An
  `Opacity` at zero drops its whole subtree from the semantics tree, so
  for the entire entrance a screen reader landing on the page found
  nothing at all — no title, no action. The content is present the whole
  time; only its paint is catching up. Guard: "an action keeps its OWN
  node, DURING the entrance".
- **The title and subtitle are spoken ONCE, as one sentence.** Both are
  wrapped in `ExcludeSemantics` and the wrapper says
  `"title. subtitle"`; without that they are read twice, once as the
  description and once as the text.
- **The actions keep their own nodes** (`explicitChildNodes: true`). A
  button folded into the description cannot be pressed by name.
- **It announces itself, once per message.** A list going empty is a
  content change with no focus change, so a screen reader says nothing
  about it — the rows are simply gone and the reason is only found by
  going looking. `announceOnAppear` fires after the frame (an
  announcement made during build races the tree it describes) and
  repeats only when the SENTENCE changes, not on every rebuild.
- **The entrance REPLAYS when the message changes.** A search-as-you-type
  screen keeps one empty state mounted and swaps its text, so without
  that the block arrives once and every later message appears with no
  motion and no announcement — the two things that say "this changed".
  A rebuild with the same words is not a new message.
- **The reading measure caps the SENTENCES, not the block**
  (`maxContentWidth`). The glyph and the actions size themselves; a
  subtitle running the full width of a tablet stops scanning as one
  line. Same reason `GlobalContainer.prose` exists.
- **The disc scales WITH the glyph** (`iconPaddingFraction`). A fixed
  inset swallows a small glyph and rattles around a large one.
- **The glyph is the quietest thing on screen** — `outline` at 40%, with
  a disc at 8% of that. It is a shrug, not a warning; a status colour
  here reads as an error.
- **An illustration outranks the icon**, and takes the disc with it: a
  caller supplying artwork does not want a soft circle behind it.
- **`fullPage` takes `MainAxisSize.max`**, which is what centres it. See
  the gap below.

## Known gaps

- **`fullPage` in an unbounded parent does NOT throw** — measured, and
  this file previously claimed otherwise. Inside a `SingleChildScrollView`
  it collapses to its content height and loses its centring, which is a
  quieter failure than a crash and easier to miss. It also overflows a
  box shorter than its own padding plus content. `compact` is the variant
  for both cases, and the distinction is the reason the enum exists.

## Adoption + commons

- **`list` and `grid` drew their own.** Each had a `Column` with a 56dp
  glyph at `onSurface @ 30%` and a title at `@ 60%`, off `Theme.of`
  rather than the palette, against this module's 64dp at
  `outline @ 40%` — two surfaces, two sizes, two colours, no theme
  behind either, and no announcement when the list emptied. Both go
  through `GlobalEmptyState` now. Guard:
  `test/empty_state/empty_state_adoption_test.dart`.
- **`GlobalList.static` has no empty phase at all**, by construction —
  an empty static list renders nothing. That is the constructor's
  contract (no empty / loading / error builders), not an oversight, but
  it does mean a static list of zero items shows a blank area.
- **The four canonical cases live in commons**
  (`lib/shared/common/empty_states/`): `NoResultsEmptyState`,
  `OfflineEmptyState`, `LoadFailedEmptyState`, `FirstRunEmptyState`.
  They are wrappers with the copy, glyph and action already decided, so
  the same "no results" screen is not re-invented with different words
  in six features. The copy is theirs, not the module's — the module
  must not know what an app calls things.
- **"No results" echoes the QUERY.** Without it a user cannot tell
  whether the search ran, and a typo is the most common reason it
  matched nothing. The query is a PLACEHOLDER inside the translated
  sentence, not concatenated onto it — Arabic puts it elsewhere in the
  line.
- **Their copy is translated, and that is tested in Arabic.** A wrapper
  with an English literal baked in looks correct in every test written
  in English, so the guard renders all three under `Locale('ar')` and
  reads the Arabic back. Locale is set per-pump rather than swapped
  mid-test: `Tr` reads `S.current`, which the delegate sets
  asynchronously, so a tree built on the frame the locale changes can
  still hold the old strings.

## Showcase + tests

`/empty-state-showcase` for the module, and the **playground** for the
commons wrappers — the bench drives them live, which is the only way to
see the entrance replaying and the announcement firing as the message
changes.

Tests:

- `global_empty_state_test.dart` — bag merge, resolution order, palette
  colours, per-variant sizes, illustration precedence, disc scaling,
  action order, the entrance and both ways of turning it off, the
  replay, the announcement (once per message), the reading measure,
  lerp, and the three semantics rules.
- `empty_state_adoption_test.dart` — `list` and `grid` render the
  module, their empty builders name no `Theme.of`, and the commons
  wrappers ARE the module.
