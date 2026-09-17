# CLAUDE.md — lib/shared/module/dialog

Typed modal dialog holding the text-field gold standard: themeable
style bag, context-resolved colors, style-gated haptics, localized
chrome, reduced motion.

Entry points on `GlobalDialog`:

- **`.show`** — full surface (title/message/content/icon, confirm +
  cancel + custom actions, auto-dismiss countdown). `responsive:
  true` clamps max-width + bucket-aware insets; `fullScreenOnCompact`
  pushes a fullscreen route on phones.
- **`.builder`** — bucket-aware insets/max-width over ANY widget,
  with the default chrome wrapped around bare content.
- **Quick forms** — `.confirm` (→ `bool`), `.info` / `.success` /
  `.error` / `.warning`, `.autoDismiss`. Text input: `showInputDialog` in `shared/common/dialogs/` (the old `.input` was removed — its `validator` was never wired)
  (countdown + progress bar or border trace).

## Contracts

- **Style is the themeable bag** (`DialogStyle`, every field
  nullable): `caller > GlobalDialogTheme.style > DialogStyle.defaults
  > context.<group>Colors`, materialized once via
  `style.resolve(context)` in `didChangeDependencies` — build reads
  the `ResolvedDialogStyle` only. Adding a themed field → bag,
  `mergedWith`, `copyWith`, `ResolvedDialogStyle`,
  `GlobalDialogTheme._lerpStyle`.
- **Type colors come from `context.statusColors`** (info/success/
  warning/error) + `primaryColors.primary` for custom — never
  `Colors.green` / `Colors.orange`.
- **Barrier + animation live in the bag** (`barrierColor`,
  `animation`, `animationDuration`, `animationCurve`). `resolve()`
  collapses to `DialogAnimation.none` + zero duration under
  `MediaQuery.disableAnimationsOf`.
- **The auto-dismiss countdown is semantic** — it measures wall-clock
  time until close and is NOT collapsed by reduced motion. Its label
  rides `DialogStrings.closingIn(seconds)` (Tr.plural — remote ICU
  templates still interpolate).
- **Haptics gate on `style.enableHaptic`** (resolved, default true):
  close-button tap.
- **Ink host**: a `MaterialType.transparency` sits INSIDE the opaque
  container (both border paths + the `.builder` chrome) — without it
  ripples paint on the route's transparent backdrop behind the
  background and taps show nothing.
- **Close button is an InkWell** with `Semantics(button:, label:
  CommonStrings.close)` — focusable, Enter/Space activation.
- **Loading blocks dismissal**: `isConfirmLoading || isCancelLoading`
  forces `canPop: false`, hides the close button, and locks the
  barrier.

## Showcase + tests

`/dialog-showcase` (anatomy only). Tests:
`test/dialog/global_dialog_test.dart` (resolve merge, reduced motion,
confirm plumbing, localized countdown en+ar, ink host, caller
override).
