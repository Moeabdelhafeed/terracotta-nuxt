# CLAUDE.md — shared/module/feedback

A drop-in feedback / bug-report screen. The form, the attachments, the
diagnostics block and the result.

```
feedback/
  feedback_style.dart          — FeedbackDefaults · FeedbackStyle · Resolved…
  theme/feedback_theme.dart    — GlobalFeedbackTheme + the resolve
  feedback_screen.dart         — FeedbackScreen
  feedback_button.dart         — the FAB / entry point
  feedback_capture.dart        — FeedbackCaptureBoundary + the screenshot
core/feedback/
  feedback_options.dart · feedback_payload.dart · feedback_strings.dart
  feedback_submitter.dart · feedback_diagnostics.dart · feedback_type.dart
```

## Options ask, style looks

`FeedbackOptions` says what the form ASKS — which types, which fields,
how many attachments, how long the cooldown, which submitter. It is
behaviour, and it lives in `core/feedback/` beside the payload and the
submitter, which is right.

`FeedbackStyle` says how the form LOOKS, and it had no home at all:
twenty-odd gaps were `SizedBox(height: 16)`, the thumbnail was `72`,
its corner was `8`, and the padding was `EdgeInsets.all(16)` — a
thousand-line screen with no rebrand hook of any kind.

- **All-nullable `FeedbackStyle`**, floor in `FeedbackDefaults`,
  app-wide layer in `MyGlobalFeedbackTheme.build(tokens:)`
  (`core/theme/widget_themes/global_feedback_theme.dart`, wired in
  `theme.dart`). Preset: `compact`.
- **Resolved ONCE per build and handed down.** Every leaf reading the
  theme itself is the drift the bag exists to stop — the same call the
  audio player makes with its own.
- **It carries no colours.** The one colour this screen owns sits ON a
  screenshot — white on a scrim — which is not a palette decision; the
  rest comes from `context.<group>Colors` at build time.

## Fixed on the way

- **The attachment row was invisible to a screen reader.** A
  screenshot thumbnail is an image the reader cannot see, and the
  remove button on it was a bare `InkWell`: no name, no role, nothing
  to act on. Each tile is one node now — what it is, which of how
  many, and a `Remove` custom action — and it takes the caller's own
  word for "attachment", so a reader hears one term for one thing.
- **The remove button did not mirror.** It was pinned to the PHYSICAL
  right, so in Arabic it sat on the far side of the thumbnail from
  where the eye starts. `PositionedDirectional`.
- **Every gap in the form is a bag field.** They were bare
  `SizedBox`es, which is why the form could not be tightened for a
  sheet without editing the widget.

## Built from the app's own parts

- **The bar is `GlobalAppBar`.** It was Material's, so this was the
  one page in the app wearing Material's title size and surface — the
  reason the heading looked a size off from every other screen.
- **Picking goes through `MediaPickerService`**, the app's own wrapper
  over the plugin, which owns the try/catch and the quality. The
  screen was constructing a raw `ImagePicker()` beside it.
- **The diagnostics block is ONE container.** It wrapped a
  `GlobalExpandableContainer` — which draws its own fill, corner and
  border — inside a raw `Container` that drew a second set. A rebrand
  moved the inner one and left the outer on its own numbers.
- **The email field was already `EmailField`** from the commons, with
  a deliberate note about preserving the screen's own `emailInvalid`
  message over the wrapper's default.

`test/feedback/feedback_adoption_test.dart` fails on any of these
coming back.

## The attachments ARE the media picker

The row used to be its own thumbnail strip, its own remove button and
its own three source buttons — a second, smaller media picker living
inside the feedback screen. It is `GlobalImagePicker` now, so the
previews, the cap, the remove, the reorder, the validators and the
semantics all come from the module that owns them.

**The bridge is `PickerItemBytes`.** Feedback carries BYTES the whole
way to the submitter — the payload holds no file paths — and the
picker speaks that variant natively, so nothing is written to disk
just to be shown.

What the screen keeps is the BUDGET. A screenshot straight off a
modern phone is several megabytes, and `maxAttachmentBytes` is what
keeps a bug report postable; the picker has no per-attachment budget
of its own, so the screen compresses anything over it.

One thing does not map: the picker always offers the gallery — there
is no `allowGallery` to turn off — so `FeedbackScreenshotMode.camera`
reads as "camera TOO" rather than "camera only". That is the honest
mapping and the harmless direction to be wrong in.

## How many attachments

`FeedbackOptions.maxAttachments` (3) is the caller's limit, and
`feedback_max_attachments` is the REMOTE one — resolved remote-first,
exactly as the cooldown is. Zero or less means "no remote opinion",
so a config that never sets the key changes nothing.

It was the one feedback setting that could only move in a release:
`feedback_enabled`, the endpoint, the support email, the diagnostics
default and the cooldown were all remote, and the cap was not — even
though "send us more screenshots" is precisely what an operator wants
to say mid-incident.

The number reaches `GlobalImagePicker.maxImages`, so the picker stops
offering the add tile at the limit rather than the screen refusing a
pick after the fact.

## The picker hands back MIXED items

A freshly picked image comes back as a `PickerItemFile` — the plugin
hands over a path — while what is already attached comes back as the
`PickerItemBytes` this screen put in. The first mapping kept only the
bytes variant, so every gallery pick was silently dropped: the sheet
closed and nothing appeared.

The raw items go up to the screen, where reading a file can be
awaited. `PickerItemUrl` is skipped on purpose: feedback posts BYTES
to the submitter, and this screen is not going to fetch somebody
else's image to do it.

The type is sealed, so a fourth variant stops the switch compiling —
which is better than another silently dropped attachment.

## Nothing screenshots anything by itself

Two designs were tried, and both were wrong.

`FeedbackScreenshotMode.captureCurrent` was a button INSIDE the form,
so the only screen it could ever photograph was the feedback form —
a picture of what the reader is looking at instead of what they are
reporting.

Taking the shot on the way IN was better and still wrong: the page a
reader came from is not necessarily the page with the problem on it.
People open feedback from a settings row, a drawer, a dev hub. An
automatic picture of an innocent screen is worse than no picture — it
looks like evidence and is not.

**An attachment is the reader's choice, always.** The capture
machinery is deleted rather than left behind a flag —
`FeedbackCapture`, `FeedbackCaptureBoundary`, the `RepaintBoundary`
`MyApp` mounted for it, its two strings and their ARB keys.
`test/feedback/feedback_adoption_test.dart` fails if any of it comes
back.

## What was already right

Worth saying, because a gold pass is not an excuse to rewrite what
works:

- `Image.memory` for a thumbnail is allow-listed in
  `test/image/image_adoption_test.dart` with a reason — the bytes were
  just captured and there is no URL to hand `GlobalImage`.
- The submitter already returns a `FeedbackResult` rather than
  throwing, already queues offline through `OfflineActionQueue`, and
  the screen already has a cooldown.
- The type chips are `GlobalChip`, the toggle is `GlobalSwitch`, the
  fields are the commons' wrappers, and the screen scrolls through
  `GlobalScrollable`.
