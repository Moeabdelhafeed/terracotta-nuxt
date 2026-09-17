# CLAUDE.md — lib/shared/module/switch

Animated on/off switch (drag, outside/in-track/in-thumb labels, icons,
loading, pulse-on-mount, vertical) holding the text-field gold
standard: themeable style bag, style-gated haptics, localized
semantics, keyboard activation, hover/focus visuals, reduced motion.

> **Status: FINISHED (July 2026).** Module holds the gold standard
> (themeable `SwitchStyle` + `GlobalSwitchTheme`, style-gated haptics
> default true, localized ARB semantics with locale dependency,
> Enter/Space activation, hover/focus overlays, reduced motion,
> RTL-flipping thumb travel) and the
> `shared/common/selection_fields/switch/` catalog is complete:
> `SettingsSwitchRow` + six localized presets (dark mode,
> notifications, biometric, analytics, crash reports, haptics) —
> showcased under the Common Hub + playground. Deliberately NOT here:
> a checkbox-style toggle duplicate (this IS the one switch), form
> validation (switches apply instantly — a gated on/off belongs to a
> checkbox), further presets (copy a preset's 30-liner).

## Architecture

```
switch/
  global_switch.dart      — GlobalSwitch widget + ios/material/compact
                            factories (barrel: exports models + theme)
  switch_state.dart       — State (part file): toggle/drag, hover/focus
                            overlay, track/thumb/label surfaces
  switch_models.dart      — constants, SwitchSize/ThumbShape/TrackShape,
                            SwitchStyle (themeable bag) + ResolvedSwitchStyle
  theme/switch_theme.dart — GlobalSwitchTheme ThemeExtension

─── In core/theme/widget_themes/ ───
  global_switch_theme.dart — MyGlobalSwitchTheme.build (wired in theme.dart)
```

## Contracts

- **Fully controlled.** Displays `value` as passed; taps/drags report
  via `onChanged`, never mutate.
- **Style is the themeable bag** (`SwitchStyle`, every field nullable):
  resolution `caller > GlobalSwitchTheme.style > SwitchStyle.defaults >
  context.<group>Colors`, materialized once per build. The widget's
  `size` PRESET (SwitchSize) wins over the bag's dimensions. Content
  (icons, label text) + behavior (drag, debounce, loading, tooltip)
  stay widget-side — the bag owns only looks. Adding a themed field →
  `SwitchStyle`, `mergedWith`, `copyWith`, `ResolvedSwitchStyle`,
  `GlobalSwitchTheme._lerpStyle`.
- **Haptics gate on `style.enableHaptic`** (resolved, default `true`).
- **Semantics** announce the localized state (`SwitchStrings.on/off`,
  ARB-backed) with `toggled` + `enabled` + tap action; the state build
  registers a locale dependency so language flips re-resolve it.
- **Keyboard**: Enter/Space toggle via `FocusableActionDetector` +
  `ActivateIntent`; hover/focus paint the resolved overlay colors.
- **Reduced motion** collapses the toggle tween, disables drag
  (thumb-follow IS motion) and skips the mount pulse.
- **RTL**: thumb travel uses `AlignmentDirectional` — start→end flips
  with the layout direction.
- **iOS factory colors are deliberate** (`0xFF34C759`/`0xFFE9E9EA` ARE
  the Cupertino look) — the one sanctioned palette exception.

## Gotchas

- Drag updates write `_controller.value` directly — the thumb reads the
  controller (not the curved animation) so it tracks the finger 1:1.
- Both active+inactive gradients set → the track becomes a two-layer
  cross-fade Stack instead of an `AnimatedContainer`.
- The settings-row wrapper (`SettingsSwitchRow`,
  `shared/common/selection_fields/switch/`) keeps the inner switch
  `IgnorePointer`-wrapped with haptics OFF — the row's InkWell owns
  tap + haptic.

## Showcase + tests

`/switch-showcase`. Tests: `test/switch/global_switch_test.dart`
(resolve merge order, size preset, toggle, keyboard Space, disabled,
localized semantics).
