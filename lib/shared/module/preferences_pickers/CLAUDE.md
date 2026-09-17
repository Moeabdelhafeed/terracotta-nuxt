# CLAUDE.md — shared/module/preferences_pickers

Not a widget family — a BINDING layer. Seven controls that read and
write the global `PreferencesCubit` directly, all rendering through
one `PickerShell<T>` with six variants.

```
preferences_pickers/
  picker_item.dart          — PickerItem<T>, one option
  picker_options.dart       — PickerOptions: which variant, what title
  picker_style.dart         — PickerDefaults · PickerStyle · Resolved…
  theme/picker_theme.dart   — GlobalPickerTheme + the resolve
  picker_shell.dart         — PickerShell<T>, the six variants
  theme_mode_picker.dart · language_picker.dart · font_scale_picker.dart
  saturation_picker.dart (+ DynamicColorToggle)
  reset_preferences_button.dart · quick_preference_actions.dart
```

This is the documented exception to two module rules: the classes drop
the `Global` prefix, and it is the one folder allowed to read the DI
catalog — for `LanguagesService`, and nowhere else.
`test/preferences_pickers/picker_adoption_test.dart` pins that down.

## It owns no controls

Every variant is one of the app's own:

| variant | what it builds |
| --- | --- |
| `pillRow` | `GlobalChip`, in its CHOICE role |
| `list` | `GlobalRadio` rows, label leading |
| `segmented` | `GlobalSegmentedControl` |
| `dropdown` | `GlobalDropdown` |
| `sheet` / `dialog` | `GlobalContainer.tile` → a sheet or a dialog of the `list` |

**It used to hand-roll four of those.** A pill out of `Material` and
an `InkWell` with `circular(999)` written in. A radio out of an
`AnimatedContainer` and two circles. A row out of a bordered
`Container`. And Material's own `DropdownButtonFormField`, where
`GlobalDropdown` is a whole themed module with search, validation and
its own popup surface. So a house rebranding the chip, the radio, the
tile and the dropdown reached every one of them in the app **except
the ones on its settings page** — which is the screen the rebrand
exists to be seen on.

The other adoption guards never caught it because each is keyed to the
module it polices, and a hand-rolled pill matches none of their
patterns. This folder drifted the furthest precisely because nothing
was looking.

## The bag

- **All-nullable `PickerStyle`**, floor in `PickerDefaults`, app-wide
  layer in `MyGlobalPickerTheme.build(tokens:)`
  (`core/theme/widget_themes/global_picker_theme.dart`, wired in
  `theme.dart`). Preset: `airy`.
- **It is THIN, and stays thin.** No colour, no font, no duration —
  the guard fails on any of them. Every control a picker draws carries
  its own bag, so a field here for a chip's fill or a radio's dot
  would be a second place for the same answer to live, and the two
  disagree the first time one is touched. What is left is the
  picker's OWN: the spacing between options, the header's glyph plate,
  the summary tile's corner, whether rows are ruled.
- **A picker should not own a look.** That is the whole design of this
  folder after the pass.

## Fixed on the way

- **The list variant announced NOTHING.** `_RadioMark` was a drawn
  circle inside a bare `InkWell`: it looked exactly like a radio group
  and reported no role, no selected state and no group — on the
  settings page, and on the quick actions every system page carries,
  including the one that reports a failed boot. Each row is a
  `GlobalRadio` now: selected, `inMutuallyExclusiveGroup`, named by
  its option.
- **The section title is a HEADER** to a screen reader; it was a bare
  `Text`.
- **The language row drew its own check mark**, and once the row
  became a radio that mark said the same thing twice — and was heard
  twice. It contributes the flag, the name and the locale code; the
  shell owns the mark, the padding and the rule.
- **Nothing read reduced motion**, and nothing used a single token:
  every number was written in (`999`, 28, 22, 18, 16, 14, 12, 10, 8,
  6, `fontSize: 12/13`, `140ms`). They are bag fields or
  `context.spacing` / `radii` now.
- **The sheet and the dialog triggers were two copies** of one
  collapsed tile, differing only in which surface they opened and
  which chevron they drew. They had already drifted apart on padding.
  One `_SummaryTrigger`.
- **`QuickPreferenceActions` still degrades to nothing.** It runs on
  the crash page, where DI and the root providers may never have come
  up, so a missing dependency has to mean "no buttons" rather than a
  second exception thrown by the screen reporting the first. Nothing
  added in this pass reads a palette before that check.

## Found on a device

- **The language rows showed empty boxes.** `_FlagBadge` drew the
  seed's emoji flag straight into a `Text`, and regional-indicator
  pairs TOFU on several newer iOS models.
  `LanguageDropdownField` had already hit this, written the reason
  down and switched to a flag IMAGE — and the picker was drawing the
  emoji anyway. It makes the same two calls now: `CountryFlagImage`
  recovered from the emoji (globe when there is no flag), and BOTH
  names — the localized one reads in the UI language, the native one
  lets a speaker self-identify, and the pair collapses when they
  match.
- **The ISO arithmetic has one home.** It was private to the commons
  dropdown; the picker needed the same six lines. It is
  `Language.flagIsoCode` on the model, and the guard fails if
  `0x1F1E6` appears anywhere else.
- **The sheet opened BARE** — no title, no icon, no close button:
  three unlabelled rows in a small panel, which reads as nothing
  having happened. It carries the picker's own heading now. (The flow
  itself was sound; the harness proves it opens, picks, closes and
  leaves the page intact.)
- **A caller's `itemBuilder` must not draw a mark.** The language row
  drew its own check circle, and once the shell rendered a real radio
  that mark said the same thing twice — and was heard twice.
  Whatever a caller draws, the MARK belongs to the shell.

## Found on a device, second round

- **A row did not PRESS.** `GlobalRadio` commits its choice through a
  `GestureDetector`, so the tap worked and nothing on screen said so —
  on a target the width of a settings row. The rows are
  `GlobalRadioTile` now, which is the radio module's own answer:
  an `InkWell` over the whole row, a tint while selected, a haptic,
  and the radio inside left non-interactive so there is still one
  target and one node.
- **`GlobalRadioTile` had no `semanticLabel`.** Its title can be a
  caller's own widget, so with a rich title the selected state landed
  on a node announcing the generic "Radio option". The parameter is
  new on that module, and a test caught the regression the moment the
  rows moved onto it.
- **The rules are OFF by default.** A radio row already ends where the
  next begins — the mark, the indent and the pressed tint all say so —
  and a rule between every pair of a three-option list is furniture.
  `PickerStyle.ruled` puts them back for a long list.
- **A LANGUAGE change never reached the pickers.** Every `buildWhen`
  watched its own field alone, so switching locale rebuilt nothing:
  every label comes from `PreferencesStrings`, and they all stayed in
  the old language until something unrelated moved state or the app
  was hot-reloaded. Each condition watches the locale as well, and
  `picker_localization_test.dart` fails on a `buildWhen` that does
  not.
- **The showcase passed English titles** over the localized ones the
  pickers ship, so the page read as English whatever the app's
  language was — and the strings that actually ship were the one thing
  it never showed. It passes only the variant now, and shows ALL SIX
  of them for every preference in one order. `style:` reaches the
  pickers too, which it never did.
- **The sheet is ours** — `GlobalBottomSheet`'s own responsive
  surface, not `showModalBottomSheet`; the test asserts no
  `BottomSheet` in the tree. What made it look like Material's was
  that it opened BARE: no title, no icon, no close button.

## Found on a device, third round

- **A caller's options REPLACED the picker's, wholesale.** It was
  `options ?? _defaults`, so `PickerOptions(variant: sheet)` — asking
  for nothing but a different shape — threw away the localized title,
  subtitle and icon the picker ships. That is why the sheet and the
  dialog opened with nothing at the top but a close button.
  `mergedOver` lays what a caller answered over the picker's own, so
  asking for a variant keeps the heading.
- **The theme picker hard-cut where the app-bar button reveals.**
  `QuickPreferenceActions` has always ridden `RevealThemeSwitcher`;
  the picker called `setThemeMode` outright, so the same change
  animated from one control and snapped from the other. It reveals
  now, growing out of the picker's middle — the honest origin for a
  list of rows, where a button can use its own centre. It resolves
  `system` through the platform first and skips the reveal when the
  painted brightness does not actually change: light → system on a
  light phone is a preference change with no visible one, and a 600ms
  wipe over an identical screen reads as a stutter.
- **The sheet opens FLOATING**, which is what the app's other
  pick-one-of-a-few sheets look like (`PickerOptions.sheetStyle`,
  compare the media source sheet). It took the sheet module's plain
  default before, so it was the odd one out beside any of them. The
  style lives on `PickerOptions`, not `PickerStyle`: it is another
  module's bag, and this module's own must not re-state one.

## The sheet's chrome is the SHEET's

The picker builds no header. It hands `GlobalBottomSheet.show` a
title, a subtitle and an icon, and the sheet draws the plate, the
heading, the drag handle and the close button itself — which is why
the heading vanished when a caller's `PickerOptions` replaced the
picker's localized defaults rather than merging over them.

What the picker DOES own is the content padding around the option
rows, and it was wrong. The sheet pads content by 20 on every side —
right for a form, wrong for a list of rows that already carry their
own padding. The two stacked: the first option sat 32 points below
the heading, and 20 more went dead under the last one, on top of the
home indicator's inset. Measured on a notched phone, before and
after: the sheet lost 40 points of height, the gap under the heading
went 64 → 44, and what is left below the last row is 34 — the device
inset, and nothing else. `picker_shell_test.dart` measures it.

## The sweep, and what it needed first

The module's biggest consumer did not use it. `settings_page.dart` —
the app's real settings screen, **846 lines** — hand-rolled a private
`_Section` card, a private `_PillRow` (a THIRD pill implementation,
after the one inside `PickerShell`), and a section class per
preference. Only font size, dynamic colour and reset came from here.
So every fix in this pass stopped at that file's door. It is **187
lines** now and every section is a picker.

Three things had to land before that was possible:

- **`AppRolePicker`, `RevealShapePicker`, `RevealDirectionPicker`.**
  `appRole` and the reveal pair had no picker at all — the settings
  page owned their only UI privately, which is what forced it to
  hand-roll in the first place. `picker_adoption_test.dart` now fails
  if any setter the cubit persists has no picker driving it.
  Choosing a shape PREVIEWS it, and snaps the stored direction to one
  that shape supports — otherwise the direction picker beside it shows
  a selection absent from its own options.
- **The theme picker reads the reader's reveal preference.** It always
  used the default circle while the settings page read
  `revealShapeKey` and `revealDirectionName`, so the same change
  animated differently depending on which control you touched.
- **The option list is ONE keyboard stop.** A radio group is a roving
  tab stop: TAB reaches it once, the arrows move the SELECTION (the
  choice follows focus — there is nothing to confirm), Home and End
  jump, and it stops at the ends rather than wrapping. Every row was
  individually focusable, so tabbing through a settings page walked
  every option of every preference. Never autofocus.

Past `PickerOptions.searchThreshold` (8) a sheet or dialog grows a
filter: a three-option theme picker with a search field looks like a
mistake, and a forty-locale list without one is a scroll.

## It had NO tests

Fifteen hundred lines behind every preference in the app, and not one.
`test/preferences_pickers/` covers the six variants each building the
right control, the choice actually reporting, the radio semantics, the
header, the three resolution layers, the theme lerp, reduced motion —
plus the adoption guard above, which also pins the DI carve-out and
the bag's thinness.

- Showcase: `/preferences-pickers-showcase`.
