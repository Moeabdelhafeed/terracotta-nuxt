# CLAUDE.md — lib/shared/module

Reusable UI primitives. Each subfolder = one widget family. Adopters consume; this directory is the canonical implementation.

## Module pattern

Every UI module in `<name>/` follows:

1. **`<name>_models.dart`** — Constants (`kFoo`), enums, `@immutable` style/config classes with `copyWith`. No widgets.
2. **`global_<name>.dart`** — Widget. Imports + re-exports the models file:
   ```dart
   import '<name>_models.dart';
   export '<name>_models.dart';
   ```
3. Showcase page lives in `lib/features/showcases/<name>_showcase/views/`.

### Naming conventions

- Widget classes: `Global<Name>` (`GlobalCheckbox`, `GlobalAvatar`).
- Model constants: `kCamelCase` (`kAvatarDefaultSize`).
- Style classes: `<Name>Style` with `const` constructor + sensible defaults.
- Enums: `<Name>Variant`, `<Name>Shape`, etc.

### Content-module variant (`markdown/`, `html/`)

Content-rendering modules split their config across more files:

- `<name>_options.dart` — config / behavior flags
- `<name>_theme.dart` — visual styling
- `<name>_source.dart` — sealed source-spec hierarchy (asset / file / url / bytes)
- `<name>_loader.dart` — source → bytes resolution

The widget file (`global_<name>.dart`) imports + re-exports all four.

### Exceptions

- `preferences_pickers/` — feature-bound preference pickers (not generic widgets); classes drop `Global<Name>` prefix. This is also the one folder where reading the DI catalog (`getIt<LanguagesService>`) is expected — `QuickPreferenceActions` (theme + language pair for an `AppBar.actions` slot, worn by the system pages AND by every `ShowcasePage`) lives here for that reason rather than widening the no-DI rule in `system_pages/`. **It owns no controls**: each of `PickerShell`'s six variants builds one of the app's own (`GlobalChip` / `GlobalRadio` / `GlobalSegmentedControl` / `GlobalDropdown` / `GlobalContainer.tile`), and the themeable bag `PickerStyle` is deliberately thin — no colour, no font, no duration, because the controls carry those. See [`preferences_pickers/CLAUDE.md`](preferences_pickers/CLAUDE.md).
- `toast/` — `GlobalToast` is a static utility facade (no widget), but kept here for discoverability.

## Adding a new module

See [`docs/contributing/adding-a-module.md`](../../../docs/contributing/adding-a-module.md) for the full workflow.

Hard rules:

- Never put a service / controller / data class under `module/<name>/` unless it's tightly UI-coupled and has no DI dependency. Pure data → `lib/data/repositories/` or `lib/data/services/`; pure state → `lib/core/state/` or a cubit under `lib/data/blocs/`.
- **Commons dependency direction**: PRIMITIVE modules (text_field, buttons, checkbox, drop_down, list, grid, app_bar, popup, …) must never import `lib/shared/common/` — one-way dependency. COMPOSITE screen/flow modules (`system_pages/`, `feedback/`, `faq/`, `wizard/`, `media_picker/`, `pdf/`, `preferences_pickers/`, `update_gate/`, `maintenance/`, `legal/`, `scanner/`, `stepper/`, `debug_overlay/`) MAY consume commons wrappers (EmailField, SearchTextField, action buttons, sheet/dialog helpers) — they are screens composed of primitives, and hand-rebuilding a common wrapper inside them is the drift the commons exist to prevent. No import cycles exist in this direction (commons depend only on primitive modules).
- No `getIt` lookups inside `module/` widget code. Accept dependencies via constructor params (see `PdfRecentDocsList.bookmarksCubit`, `GlobalSearchController.historyCubit`).
- `Semantics` wrap on every interactive surface.
- `style.enableHaptic` gating for haptic feedback.
- RTL-aware geometry via `Directionality.of(context)`.
- `context.spacing` / `context.radii` / `context.iconSizes` for layout (no raw numbers).
- `context.<group>Colors.<role>` for colors (never `Colors.X` outside showcase demo content).
- `AppDurations.X` for animation durations.

## Per-module gotchas

The "stuff that bites you" reference, ordered by frequency. For the full API, read the module's own doc-comment.

### `GlobalScaffold` (`scaffold/`)
- Requires `BreakpointsProvider` ancestor (already wired in `MaterialApp.builder` via `MyApp`).
- Auto-switches surface: bottom bar (compact) → rail (medium) → drawer (expanded+).
- **`GlobalNavStrategy` resolves on BOTH axes.** A short window takes `forShort` (a plain `rail` by default) whatever its width. Width alone got a landscape phone wrong at both ends: a small one (568×320) is compact by width and kept a bottom bar — 56 points of a 320-point screen, on the axis there is none of — and a big one (874×402) is `expanded` by width and got the *extended* rail, 256 points of nav across 874. A bar costs vertical room, a rail costs horizontal room, and a short window has none of the first and plenty of the second. `forShort: null` goes back to width alone; `GlobalNavMode.none` is never overruled, because "no navigation" is a decision rather than a layout.
- Do NOT nest `GlobalScaffold` — one per route. Sub-pages use plain `Scaffold` or `GlobalContainer.shell`.

### `GlobalBreadcrumbs` (`breadcrumbs/`)
- **NOT the crash trail.** `UiWatchdog.breadcrumb` and the crash reporter's breadcrumbs log where the APP has been; this says where the READER is. Same word, nothing else in common.
- Visual config is the **themeable bag** `BreadcrumbsStyle` (all fields nullable). App-wide defaults via `GlobalBreadcrumbsTheme` (`MyGlobalBreadcrumbsTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `BreadcrumbsDefaults`. See [`breadcrumbs/CLAUDE.md`](breadcrumbs/CLAUDE.md).
- **Overflow is the whole problem** — five crumbs at 13pt already overrun a 400dp phone. `collapse` (default: first + `…` + last few, the `…` holding what it swallowed), `scroll`, `wrap`, `lastOnly`. The budget is read from the WINDOW, not guessed.
- **`lastOnly` shows the PARENT**, not the current page: "up" is all a one-crumb trail can usefully say.
- **The current crumb is a HEADER, not a button** — it is where the reader already is. The trail itself is one landmark; the separators are excluded.
- **`.fromRouter` is opt-in and shallow.** It needs a slug→label map, and it is only as deep as the router is nested — most of this app's routes are flat, so it yields one crumb for them.

### `GlobalPane` (`pane/`)
- Fixed-fraction list+detail today (no resize drag handle yet). Use `paneRatio` to tune (default 0.35).
- Compact pushes detail on top; medium+ shows both side-by-side.

### `GlobalContainer` (`container/`)
- Three static factories: `.shell` (bucket-clamped full-height shell), `.prose` (reading width), `.form` (narrower form width).
- Always wrap top-level page content in `.shell`. Showcases already do this via `ShowcasePage`.
- Visual config is the **themeable bag** `ContainerStyle` (all fields nullable). App-wide defaults via the `GlobalContainerTheme` ThemeExtension (`MyGlobalContainerTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `ContainerDefaults`. See [`container/CLAUDE.md`](container/CLAUDE.md).
- **The BOX stays in the bag** (`width` / `height` / `padding` / `margin`) where other modules push layout onto the widget — a container IS its box.
- **`shadow: null` asks for the house shadow; `shadow: const []` is a FLAT container.** Collapsing the two makes flat impossible to ask for.
- **The fill is `backgroundColors.container`, not `surface`** — a container sits above the page. It was `isDark ? surfaceContainerHigh : surface`, Material's scheme plus a brightness branch the palette already does.
- **A tappable container is one button node with NO label of its own** — `container: true` merges the title, badge and body into it, so an explicit label says everything twice. A decorative one gets no node at all.

### `GlobalList` / `GlobalGrid` (`list/`, `grid/`)
- Visual config is the **themeable bag** `ListStyle` / `GridStyle` (all fields nullable, with `ScrollableStyle` and `ScrollInStyle` as sub-bags). App-wide defaults via **ONE** `GlobalCollectionTheme` for both (`MyGlobalCollectionTheme.build`, wired in `theme.dart`); per-call `style:` wins; floors in `ListDefaults` / `GridDefaults`. Presets: `ListStyle.feed` / `.bare`, `GridStyle.gallery` / `.bare`. See [`list/CLAUDE.md`](list/CLAUDE.md).
- **One extension for two modules**, because they share their controller, selection, chrome and pagination vocabulary — two would be two rebrand hooks that can disagree.
- **The flat chrome params are a shorthand**, not a second home: `edgeFade` / `showScrollToTop` / … merge on top of `style.scrollable` so the resolve sees them.
- **Neither read reduced motion, and neither had one `Semantics` node.** Both now: the change animation resolves to zero, a selected row says so, and a page button is a named button that knows whether you are on it.
- **They had NO tests at all** — 6 000 lines, 288 parameters. The characterisation suite (`test/list/`, `test/grid/`) came first and caught two regressions during the pass.
- **`swipeActions` is LIST-only** — a pane behind each side of a row, per item, with `leading` / `trailing` DIRECTIONAL and every action mirrored as a `CustomSemanticsAction` (a swipe is invisible to a screen reader). A grid has no spare horizontal axis, and neither does a horizontal list; both are refused rather than half-working.
- **`selectOnTap` owns the ANCHOR**, on both modules — tap toggles, Shift+tap takes the run, Ctrl/Cmd+tap adds without moving it, Shift+arrow extends (in the grid: sideways by a tile, vertically by a ROW), long-press-and-drag paints and auto-scrolls at the edge. `selectRange` was on the controller from the start and nothing drove it, so every screen wrote the same anchor field.
- **`stickyHeader` on both** — `headerSlivers` is the other way, and those SCROLL unless each pins itself.

### `GlobalGrid` / `SliverGlobalGrid` (`grid/`)
- Column count is `ResponsiveValue<int>` (per bucket).
- Paginated data → pass `PaginatedResult<T>` via `controller.loadMore`. Items must be stable-identity (override `==`/`hashCode` or use Freezed).
- A-Z scrubber requires `itemLetter:` + items pre-sorted.
- Selection mode: `selectionEnabled: true` + listen to controller's selection stream.
- Pinch-zoom changes column count live — handle reflow in your itemBuilder.

### `GlobalList` / `GlobalListController` (`list/`)
- Mirrors `GlobalGrid` features. Controller-driven: `add/remove/replace/insertAt/animateChange`.
- For async pages, use `controller.loadPage(() async => fetchPage(n))` — handles loading/error/empty.

### `GlobalTextFormField` (`text_field/`)
- For purpose-shaped fields use the app-owned wrappers in `lib/shared/common/text_form_fields/` (`EmailField`, `PasswordField`, `OtpField`, `SearchTextField`, …). They set keyboard, validators, formatters. Module code composes the raw `GlobalTextFormField(...)` directly (don't import the common wrappers into `module/`). Wrapper contract + catalog → [`../common/text_form_fields/CLAUDE.md`](../common/text_form_fields/CLAUDE.md).
- Eight grouped params: `style` (themeable), `behavior`, `validation`, `features`, `slots`, `callbacks`, `sizing`, `messages`. Full usage recipes per feature → `text_field/CLAUDE.md` § Usage recipes.
- Validation: sync `validator` gates a debounced `asyncValidator` (server checks, suffix spinner). ALL errors render in the message column (icon + status color — never Material's plain string). Inside a `Form` keep `deferToParentForm: true` (default); standalone fields set `false` (internal triggers drive validation). `mode: onSubmit` fires on keyboard submit + always on `Form.validate()`.
- Sizing: `sizing: TextFieldSizing(height/min/max, width/min/max, fitWidthToContent, isCollapsed)` — an external `SizedBox` can NOT shrink the field; tell it its height.
- Status rows: `messages: [FieldMessage.success/warning/info/error(...)]` — sorted column under the field.
- Slots size to content (no 48×48 min) — pad bare prefix icons with `EdgeInsetsDirectional.only(start: 12, end: 8)` or they hug the border.
- Pair with `GlobalSearchController(historyCubit: getIt<SearchHistoryCubit>())` for debounce + persistent recents.
- Validators in `core/utils/validators/` (`Validators.validateEmail`, `.validateRequired`, `.validatePhoneNumber`, …). No combine helper — compose with a closure: `(v) => Validators.validateRequired(v) ?? Validators.validateEmail(v)`.
- Inline ghost completion: `features: TextFieldFeatures(suggestions: SuggestionsConfig(items: [...], showInlineCompletion: true))` — Tab / →  accepts.
- Visual config is the **themeable bag** `TextFieldStyle` (all fields nullable). App-wide defaults via the `GlobalTextFieldTheme` ThemeExtension (`MyGlobalTextFieldTheme.build`, wired in `theme.dart`); per-call `style:` overrides win; hard-coded floor in `TextFieldDefaults`. See `text_field/CLAUDE.md`.

### `GlobalDropdown` (`drop_down/`)

- **Composition, not a custom field**: trigger IS a `GlobalTextFormField` in read-only picker mode; overlay IS a `GlobalPopupController`. Style the trigger with `style:` (TextFieldStyle), the open surface's rows with `dropdownStyle:` (DropdownStyle, themeable via `GlobalDropdownTheme`).
- **Grouped configs** mirror the text field: `behavior:` (search/inline/dense/caps), `chips:` (chip trigger), `slots:` (prefixIcon/itemBuilder/emptyBuilder/onCreateNew/infoLabel), plus `sizing`/`popupOptions`/`messages`. Full contract → [`drop_down/CLAUDE.md`](drop_down/CLAUDE.md).
- **Fully controlled** — displays `selectedValue(s)` as passed, reports via callbacks, never mutates. The `FormField` wrappers seed from `initialValue` ONCE (standard Flutter semantics).
- **Wrapper validation** via `validation: DropdownValidation(...)` — `ValidationMode` reinterpreted: `onFocusLoss` = overlay closed, `onInteraction`/`realTime` = selection change, `onSubmit` = `Form.validate()` only. `revalidateKey` re-validates on rules change.
- **Chip mode** (`chips.display`) keeps a custom wrap-height trigger but renders the same message column; `messages` work in both trigger kinds.
- One `GlobalDropdownController` per dropdown — second attach asserts.

### `GlobalDateTimePicker` / `GlobalDateTimeRangePicker` / `GlobalInlineCalendarRangePicker` (`date_time_picker/`)

- Visual config is the **themeable bag** `DateTimePickerStyle` (all fields nullable) — ONE bag for the whole family, because a calendar inside an overlay inside a range picker has to agree with the calendar beside it. App-wide defaults via `GlobalDateTimePickerTheme` (`MyGlobalDateTimePickerTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `DateTimePickerDefaults`. Presets: `compact`, `circular`, `flat`. See [`date_time_picker/CLAUDE.md`](date_time_picker/CLAUDE.md).
- **`surface:` says WHERE it lives** (`wheel` / `material` / `input` / `calendar` / `overlay`), `style:` says how it looks. The enum used to be called `PickerStyle`, which put two unrelated `style` words on one widget.
- **Bounds default to a year EITHER SIDE of today.** They defaulted to today, so the calendar could not show last month and the range picker's own "Last 7 days" preset selected a span drawn entirely disabled.
- **The arithmetic is pure and tested** — `PickerMath` (month lengths, 12-hour clock, minute snapping), `CalendarGrid` (the 7-column grid, RTL-mirrored), `OverlayPlacement` (above / below). None of it could be tested inside the widgets, so every bug in it used to surface only on a device.
- **`PickerAnchor` is the one trigger-plus-panel.** Its measuring key rides the `CompositedTransformTarget`, so a custom `triggerBuilder` still opens the panel — both pickers used to put it on the default trigger's inner container and a custom one never opened at all.
- **`minuteInterval` asserts it divides 60**, and a value off the interval is snapped: :07 on a 15-minute wheel used to read "00" and report :07.
- **The dialogs are OURS** (`PickerDialogs`) — `showDatePicker` / `showTimePicker` / `showDateRangePicker` are gone, along with the `Theme` wrapper that was the only way to style them. Date and time come in ONE dialog, and a header icon toggles the grid for a masked text field.
- **An anchored panel FLIPS rather than shrinking**, and its height is measured from its content — a calendar near the bottom of a screen keeps every row.
- **Two layouts ride the bag**: `timeLayout` (`wheels` / `dial` — a clock face, built here rather than borrowed from `showTimePicker`) and `rangeLayout` (`dialog` / `fullScreen` — a route with a `GlobalAppBar` carrying the span).
- **In Arabic**: the chevrons mirror themselves (`matchTextDirection`), the weekday strip is narrow names, and every number goes through `AppNumbers` — plain `ar` writes ASCII digits.
- **`calendar: PickerCalendar.hijri`** makes the same grid count in the civil Islamic calendar. Only the counting changes — the value is a `DateTime` either way — and the WHEELS stay Gregorian.
- **`monthFlow`** is `paged` (one month, neighbours peeking in dimmed at the edges) or `list` (every month stacked and scrolled, which is what the full-screen range uses). Both grids size to their contents, cap against the window, and fade where they are cut off.

### `GlobalSlider` (`slider/`)

- Visual config is the **themeable bag** `SliderStyle` (all fields nullable, including the `SliderTickStyle` / `SliderIndicatorStyle` sub-bags). App-wide defaults via `GlobalSliderTheme` (`MyGlobalSliderTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `SliderDefaults`. Presets: `bare`, `prominent`, `stepped`. See [`slider/CLAUDE.md`](slider/CLAUDE.md).
- **All six `paint` methods declared a `textDirection` and read it in none.** A gradient track drew its fill on the side the value was NOT in Arabic, and every passed tick was drawn as unreached. The RTL arithmetic is `SliderMath.activeSpan` / `tickIsActive`, pure and tested.
- **`showTicks` is separate from `tickStyle`** — `tickStyle != null` was the only switch, so a house that styled ticks put them on every slider in the app with no way to say no.
- **It had no `Semantics` and no haptics.** One group node now carries the label; the badge and the end chips are `ExcludeSemantics` because Material's own node already says the value; `semanticFormatter` announces what the badge cannot. Haptics tick per DIVISION, never on a continuous slider.
- **Numbers go through `AppNumbers`** — `toStringAsFixed` writes ASCII digits whatever the locale is.
- **Segments CUT the track** (`segments:`, boundary values on the widget; `segmentGap` on the bag). Lifted out of the video player's seek bar, which now imports `SliderSegmentedTrackShape` and is 115 lines shorter. The player pins its copy left-to-right because a TIMELINE does not mirror; an ordinary slider does.
- **`secondaryValue:` is the buffered fill.** Material has always had `secondaryTrackValue`; this module never passed it on, so every load-ahead bar in the app was a `Stack` of two widgets.
- **`stepLabels:` puts one word under each tick** — and that word is what a screen reader announces, so a reader hears "Great" rather than "5".
- **Commons**: `selection_fields/slider/` — `SettingsSliderRow` / `SettingsRangeRow`, a `SliderFormField` (every other selection control had one and the slider did not), and nine localized presets. See [`slider/CLAUDE.md`](slider/CLAUDE.md).
- **Nothing outside the module builds a raw `Slider`.** `FontScaleSlider` was one over a hand-rolled min/value/max row with no `Semantics` and `'70%'` / `'200%'` hard-coded; it and two showcase playgrounds went through `GlobalSlider`. Chrome on its own surface (video timeline, audio seek bar, scanner zoom, PDF page jumper) and the debug overlay are exempt WITH REASONS — `test/slider/slider_adoption_test.dart` fails on a new one.
- **`onChangeStart` / `onChangeEnd` carry the value.** They were `VoidCallback`s and dropped what Material handed them, so "commit on release" needed the caller to keep its own copy.

### `GlobalStepper` (`stepper/`)

- Visual config is the **themeable bag** `StepperStyle` (all fields nullable). App-wide defaults via `GlobalStepperTheme` (`MyGlobalStepperTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `StepperDefaults`. Presets: `bare`, `prominent`. See [`stepper/CLAUDE.md`](stepper/CLAUDE.md).
- **A stepper with no `onStepTapped` is a REPORT** — no focus, no button semantics. With one, TAB reaches the run ONCE and the ARROWS walk it (a roving tab stop, like a radio group); Enter / Space commit, Home / End jump. Arrows move the KEYBOARD, not the step: firing `onStepTapped` for every step passed through is a page transition each time in a wizard.
- **The horizontal run mirrors in Arabic; the vertical, timeline and alternating ones do not** — only a horizontal axis has a reading direction.
- **`surfaceColor` is the PAGE, not the card.** The connector runs behind the indicator, so an interior that does not match what is behind it draws the line through the middle of the circle. It is the one field to set when a stepper sits on a tinted surface.
- **`connectorColor` is still nullable AFTER resolution** — unset means each connector takes the colour of the steps it joins, which is not one colour.
- **`StepperConnectorStyle.none` draws nothing.** It used to fall through to the solid branch and draw a line.
- **Connectors meet the indicator's resting edge**, and `connectorInset` moves them (positive = gap, negative = under). The lane is centre-to-centre, so a zero inset is what keeps a line out from under a translucent `stepBuilder` indicator.
- **The sequential-fill delays are cancellable `Timer`s**, not `Future.delayed` — a stepper torn down mid-jump left pending callbacks.
- **Reduced motion is honoured separately from `style.animated`** — the flag is the caller's answer, `MediaQuery.disableAnimationsOf` is the reader's. Either zeroes every duration, the sequential connector delays with them.
- **`scrollable` centres the active step**, on a caller's move, a tap, the keyboard, and on the first frame for a stepper that opens mid-run.
- **Indicator digits go through `AppNumbers`** — they were raw, so Arabic read `1 2 3` beside `١ ٢ ٣`.
- `GlobalWizard`'s `numbered` and `vertical` variants build one, so the theme reaches those too.

### `InPageHero` (`in_page_hero/`)

- Visual config is the **themeable bag** `InPageHeroStyle` (all fields nullable). App-wide defaults via `GlobalInPageHeroTheme` (`MyGlobalInPageHeroTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `InPageHeroDefaults`. Presets: `snappy`, `lifted()`. See [`in_page_hero/CLAUDE.md`](in_page_hero/CLAUDE.md).
- **Not a route `Hero`** — both endpoints live in ONE tree the whole time, indexed so a tag can have three stops or ten. The inactive one is measured but not painted, because a flight needs a rect at both ends.
- **The bag resolves in `didChangeDependencies`, never `initState`** — the theme and reduce-motion are inherited reads, and the collapse controller's duration comes from them.
- **Reduced motion skips the flight WHOLE**, not quickly: an overlay that inserts and removes itself in one frame still flickers.
- **`flyTo` returns a future that completes on landing.** It returned nothing, so callers guessed with a `Future.delayed`.
- **`InPageHeroPart.morph(id:, restingT:, builder:)` builds a part from the flight's progress** — an `AnimatedIcon` that genuinely morphs, or text whose `fontSize` is lerped so it never softens. A crossfade cannot morph two arbitrary glyphs; nothing corresponds between their outlines.
- **`InPageHeroPart(id:)` makes a piece INSIDE the box travel on its own** — measured at both ends and drawn over the flight — instead of dissolving in the crossfade. Both ends or nothing; it is scaled rather than re-laid out, so it suits an icon or a thumbnail more than resizing text.
- **A `BoxShape.circle` is lerped as a huge radius** — `BoxDecoration.lerp` of a circle against a rounded rectangle asserts.

### `GlobalPageView` / `GlobalCarousel` / `GlobalCarouselView` (`page_view/`, `carousel/`, `carousel_view/`)
- Visual config is the **themeable bag** `GlobalPageViewStyle` (all fields nullable) shared by all THREE. App-wide defaults via `GlobalPageViewTheme` (`MyGlobalPageViewTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `PageViewDefaults`. Presets: `numbered`, `bare`. See [`page_view/CLAUDE.md`](page_view/CLAUDE.md).
- **The bag carries NO dot colours** — those belong to `GlobalIndicatorTheme`, beside every other dot in the app. This bag says WHICH indicator and WHERE, and passes `dotStyle` through.
- **ONE `PageIndicatorOverlay` for the three.** Each carried its own copy — same thirty lines, own hard-coded pill radius — and three copies drift the moment one is touched. `test/indicator/indicator_adoption_test.dart` fails if a module builds its own dots again.
- **Reduced motion collapses the transition to a plain `slide`, not to "none"** — moving between pages IS the control; what goes is the spinning and folding. The story pace is NOT zeroed: that is the content's clock.
- **It had no semantics and stole the focus.** One node now saying `Page 2 of 5` with working increase / decrease actions, and no `autofocus`.
- **`autoPlay` + `GlobalPageViewController`** — the deck turns itself (holding for a finger, for being scrolled off screen, and for the caller), and the controller speaks LOGICAL pages: Flutter's `PageController` counts virtual ones, so `jumpToPage(2)` on a looping deck landed a thousand laps away.
- **The arrow keys mirror in Arabic** — a horizontal deck advances leftward there, so LEFT is "next". A vertical deck keeps its keys.
- **Both carousels got the same pass**: no autofocus, one `Semantics` node each with working increase / decrease, mirrored arrows, gated haptics, the shared controller, off-screen holds, and the `positions.length` guard `GlobalCarouselView` was missing at three sites.
- **`GlobalCarouselView` used to land on the wrong item** with uneven `flexWeights` — `maxScrollExtent` moves mid-scroll as the hero slot grows, so an offset computed up front meant a different item on arrival. It drives `CarouselController.animateToItem` now, and the index readback replicates the framework's own `pixels / (viewport * weights.first / weights.sum)` instead of assuming the last item sits at the end of the scroll.

### `GlobalDotIndicator` / `GlobalStoryIndicator` (`indicator/`)

- Visual config is the **themeable bag** `DotIndicatorStyle` (all fields nullable), with `StoryIndicatorStyle` beside it for the story bar. App-wide defaults via `GlobalIndicatorTheme` (`MyGlobalIndicatorTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `IndicatorDefaults`. Presets: `subtle`, `pill`, `outlined`. See [`indicator/CLAUDE.md`](indicator/CLAUDE.md).
- **The row MIRRORS in Arabic** — dot one on the right, because the pages it names live in a scrollable and scrollables reverse. It used to mirror for the `Row`-based effects and NOT for the absolutely-positioned ones (`worm` / `slide` / `jumping`): one widget, two answers. A vertical row does not mirror — a `RotatedBox` runs it top-to-bottom in every language.
- **The ROW is the semantics node, not the dots** — fifteen effects draw a different number of boxes for the same five pages. No `onTap` means a read-only report that takes no focus; with one it is an ADJUSTABLE (`value` / `increasedValue` / `decreasedValue` together, or Flutter asserts) and the arrows, Home and End move a page.
- **`GlobalPageCounter` is the other way to say a position** — "3 / 5", for counts a dot row cannot show. It was a raw `Text` in the page view, the carousel and the carousel view; `test/indicator/indicator_adoption_test.dart` fails on a new one.
- **Reduced motion collapses every effect to an instant change** — a dot row re-animates on every page turn.
- **`GlobalStoryIndicator.player` RUNS the story** — `StoryPlayerController` gives per-segment durations, `pause`/`play` that hold where they stopped, `holdFor` for an interruption that resumes itself, and a `previous()` that restarts the current segment first. It ticks on the vsync; every caller that drove the bar itself used a `Timer` and moved the fill in visible jumps.
- **The story bar is deliberately WHITE**, not a palette colour: it sits over photographs, the same call `video/` and `scanner/` make.
- `GlobalPageView`, `GlobalCarousel` and `GlobalCarouselView` pass a `DotIndicatorStyle?` straight through, so an unanswered field falls to the theme.

### `GlobalDialog` (`dialog/`)
- Use `GlobalDialog.builder(context, builder: ...)` not raw `showDialog`. Centralizes dismiss + theme + `fullScreenOnCompact`.
- Always returns `Future<T?>` — `null` on dismiss. Caller must handle null.

### `GlobalBottomSheet` (`sheet/`)
- `GlobalBottomSheet.show(responsive: true)` flips to side-sheet on medium+. Use for forms, picker overlays, action lists.

### `GlobalPopupMenu` (`popup_menu/`)
- `GlobalPopupMenu.showAt(anchor: globalKey, bottomSheetOnCompact: true)` — auto-falls back to bottom sheet on small screens.

### `GlobalRefreshable` (`refreshable/`)
- Visual config is the **themeable bag** `RefreshableStyle` (all fields nullable). App-wide defaults via `GlobalRefreshableTheme` (`MyGlobalRefreshableTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `RefreshableDefaults`. Presets: `material`, `cupertino`, `quiet`. See [`refreshable/CLAUDE.md`](refreshable/CLAUDE.md).
- **`cupertino` now MEANS cupertino.** `RefreshIndicator.adaptive` reads the platform off the ambient `Theme`, so the variant handed back Material's spinner on every device that was not an iPhone. The module overrides `Theme.platform` for the indicator alone — the child gets the real theme back, or every scrollable and switch beneath it would change behaviour.
- **`adaptive` is resolved once**, in the resolve, so nothing downstream asks the platform again.
- **The haptic fired once per app**, not once per pull: the flag was cleared only when a refresh completed, so a part-way pull that was let go silenced every pull after it.
- **A word in `semanticsValue` throws** — Material's indicator is a progress node and its value must be a number. The announcement comes from the module's own live region instead.
- **Reduced motion zeroes the illustration fade, NOT `minShowDuration`** — that one is a floor on how long the indicator is readable, not an animation.
- **A failing `onRefresh` used to vanish** — it escaped into the zone and the screen looked untouched, indistinguishable from a refresh that changed nothing. `onError` takes it; without one it goes to `FlutterError.reportError`, never nowhere.
- **A screen reader could not refresh at all** — a name is not an action, and pulling is not available to one. Every instance carries a `CustomSemanticsAction` now.
- **`GlobalRefreshableController`** refreshes from outside the tree (after sign-in, from a toast's Retry, on resume). `indicatorBuilder` draws a caller's own indicator from a `RefreshPull`; `minRefreshInterval` + `onSkipped` throttle; `lastUpdatedBuilder` gets the last COMPLETED refresh.

### `GlobalCardStack` / `GlobalLayeredStack` (`card_stack/`, `layered_stack/`)
- Visual config is the **themeable bag** `StackStyle` (all fields nullable), shared by BOTH. App-wide defaults via `GlobalStackTheme` (`MyGlobalStackTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `StackDefaults`. Presets: `flat`, `notifications`, `decisive`. See [`card_stack/CLAUDE.md`](card_stack/CLAUDE.md).
- **A queue you CONSUME vs a pile you LOOK at.** The card stack's index moves because a card LEFT — swipe past the threshold and it is removed, undo rewinds it. The layered stack removes nothing; its index moves because the CALLER said so. Same depth drawn, opposite contract.
- **ONE bag, in `card_stack/`**, because the depth vocabulary is the one thing they genuinely share — each had its own `scaleStep`, peek offset and layer cap, so deepening one left the other on its own numbers. The swipe fields mean nothing to the pile, the same way the page family's bag carries fields only one of its three widgets reads.
- **Neither had a single `Semantics` node.** A swipe is not a gesture assistive tech can make and a deck has no other affordance, so every allowed direction is now a `CustomSemanticsAction` (with undo beside it); `directionLabels` is where a caller puts the MEANING, since the module can only honestly say "Swipe left". The pile is an ADJUSTABLE only when something can drive it — otherwise it is a report.
- **`loop` + `undo` dealt a DUPLICATE**: a looping dismissal returns the card to the bottom of the deck, but it was still recorded, so undo inserted a second copy and the deck grew by one every time.
- **A FLICK dismisses** (`flingVelocity`). Distance was the only test, so the short fast flick people actually make snapped back — and a flick picks its axis by SPEED, not by how far the finger drifted.
- **The layered controller could not count its deck** — `next()` walked past the end forever while the widget clamped on the way out, and `loop` never wrapped for a controller at all. It clamps or wraps at the source and reports `canGoNext` / `canGoPrevious`.
- **Reduced motion flattens the motion, not the deck**: no tilt, no travel, but the card still leaves (it is the control), the depth stays (it is layout), and the flick still counts (an input, not an animation).
- **The peek mirrors in Arabic** — `right` is the reading end. The card stack's peek was a bare vertical offset before, so a deck could not fan the way a pile could.
- **A rebuild UNDID a swipe**: `didUpdateWidget` compared items with `identical`, so a caller who builds their list in `build()` reset the deck on every unrelated `setState` (measured: `remaining` 2 back to 3, history wiped). `listEquals` now.
- **Neither took a keyboard** — arrows deal the top card (Ctrl/Cmd+Z rewinds) and move a layer on the pile, mirrored in Arabic on the horizontal axis only, never autofocus. A pile nothing can drive takes no tab stop, same call its semantics node makes.
- **An empty deck drew a blank box** — `GlobalEmptyState` now, `emptyBuilder` for a caller's own. `tapToAdvance` was silently dead when a controller was passed. `onUndo` / `onIndexChanged` are the callbacks that did not exist. `undoLimit` caps a history that grew forever.
- **The card pivots below its centre** (`rotationAnchorY`), applied separately from the scale — one transform would pivot the scale about that point too, which is a card growing out of the floor.
- **Nineteen hundred lines, no tests.** `test/stack/` came with the pass, including the pure geometry (`scaleAt` / `opacityAt` / `peekAt`) and an overflow sweep of both showcases.

### `LegalIndexPage` / `LegalScreen` (`legal/`)
- Visual config is the **themeable bag** `LegalStyle` (all fields nullable), shared by both. App-wide defaults via `GlobalLegalTheme` (`MyGlobalLegalTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `LegalDefaults`. Preset: `compact`. See [`legal/CLAUDE.md`](legal/CLAUDE.md).
- **The About page was the least finished screen in the app** — the one an adopter shows a lawyer and a reviewer. Its own chrome was hard-coded English (`'About'`, `'Legal & Information'`, `'App'`, `'Version … • Build …'`) on a page whose entire list is localized document titles; `LegalStrings.titleAbout` already existed and was not being used.
- **`showLicensePage(applicationName: 'App')`** — Flutter's own licence page, the one screen nobody wrote, introduced the app as "App". It takes the real name and version from `PackageInfo` now.
- **The tile was `Material` + `InkWell` + `Container`** drawing its own fill, ripple, border and corner. `GlobalContainer` does all four and is one button node.
- **`markBuilder` is the seam an adopter fills** — the default mark is unmistakably a placeholder, and it lives on the bag so a house replaces it once from the theme rather than editing the page.
- The doc comment promised a `GlobalGrid` split on tablets; there was never one in the build. `LegalScreen` was already going through its modules and was left alone.

### `FeedbackScreen` (`feedback/`)
- Visual config is the **themeable bag** `FeedbackStyle` (all fields nullable). App-wide defaults via `GlobalFeedbackTheme` (`MyGlobalFeedbackTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `FeedbackDefaults`. Preset: `compact`. See [`feedback/CLAUDE.md`](feedback/CLAUDE.md).
- **`FeedbackOptions` ASKS, `FeedbackStyle` LOOKS.** The options are behaviour and live in `core/feedback/` beside the payload and the submitter; the look had no home at all — twenty-odd gaps were `SizedBox(height: 16)`, the thumbnail was `72`, its corner `8`, on a thousand-line screen with no rebrand hook.
- **Resolved ONCE per build and handed down** — every leaf reading the theme is the drift the bag exists to stop.
- **The attachment row was invisible to a screen reader**: a thumbnail is an image the reader cannot see, and the remove button on it was a bare `InkWell` — no name, no role, nothing to act on. One node per tile now, with a `Remove` custom action, named with the caller's own word for "attachment".
- **The remove button did not mirror** — pinned to the physical right, so in Arabic it sat on the far side of the thumbnail from where the eye starts.
- `Image.memory` stays (allow-listed with a reason: the bytes were just captured, there is no URL for `GlobalImage`), and the submitter already returned a result rather than throwing.

### `GlobalMarkdown` (`markdown/`)
- Visual config is the **themeable bag** `MarkdownStyle` (all fields nullable). App-wide defaults via `GlobalMarkdownTheme` (`MyGlobalMarkdownTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `MarkdownDefaults`. Preset: `compact`. See [`markdown/CLAUDE.md`](markdown/CLAUDE.md).
- **`MarkdownOptions` is BEHAVIOUR, `MarkdownStyle` is LOOK.** They were one class, and the look half was unreachable: the sheet came from a static `MarkdownTheme.build(context)` with every spacing written into it, identical for every app that forks this template.
- **The bag carries no colours and no text styles** — those come from the palette and the type scale when the sheet is built, so a document tracks role, brightness, saturation and the reader's font size. `styleSheetBuilder` gets the last word and is handed the sheet the bag produced.
- **A failed load rendered NOTHING.** Missing asset, unreadable file, URL the network never answered — all came back as the empty string, and empty renders `SizedBox.shrink()`. A missing legal document and a blank one were the same blank screen. `MarkdownLoadResult` is sealed now, the default failure state is `GlobalEmptyState` with a Retry that goes past the cache, and **only successes are cached**.
- **A caller's `future` loader could throw straight out** and take the `FutureBuilder` with it. An **empty** document is still empty, not an error.
- `semanticLabel` names the document with `explicitChildNodes`, so headings, links and code blocks inside stay reachable.

### `GlobalShareButton` / `GlobalShare` (`share/`)
- Visual config is the **themeable bag** `ShareButtonStyle` (all fields nullable). App-wide defaults via `GlobalShareTheme` (`MyGlobalShareTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `ShareDefaults`. Preset: `quiet`. See [`share/CLAUDE.md`](share/CLAUDE.md).
- **The VARIANT and the LABEL are NOT in the bag** — both used to be. A theme that can turn every share control in the app into a floating action button is not a theme, and what a button says is content. `.icon` / `.fab` / `.tile` constructors pick the shape.
- **The FAB had no name.** Material publishes its own semantics node with the button flag and the tap, so a `Semantics` wrapper above it is a SECOND node — the label on one, the action on the other, and a reader hears nothing. `MergeSemantics` joins them.
- **A failed share went nowhere** — logged at warning and dropped, indistinguishable from a cancelled one. It goes to `FlutterError.reportError` without an `onError`, the same call the refreshable makes.
- **`GlobalShare` is the static facade** (`text` / `uri` / `files` / `run`) for a swipe action or a menu item with no widget to hang off.

### `GlobalAutoScroller` (`auto_scroller/`)
- Visual config is the **themeable bag** `AutoScrollerStyle` (all fields nullable). App-wide defaults via `GlobalAutoScrollerTheme` (`MyGlobalAutoScrollerTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `AutoScrollerDefaults`. Presets: `ticker`, `ambient`. See [`auto_scroller/CLAUDE.md`](auto_scroller/CLAUDE.md).
- **The bag carries no COLOURS — it paints nothing.** What a house sets once here is a PACE: a ticker drifting at 60 on one screen and 18 on another is the drift it exists to stop, and the speed used to be a widget param with a baked-in default.
- **Not the marquee, and not `autoPlay`.** `GlobalMarquee` owns its child, MEASURES it, and stays still when the content fits. This owns nothing and never measures — it advances a caller's own `ScrollController`, which the caller MUST forward or it is an expensive no-op. The page family's `autoPlay` jumps whole pages on an interval instead of scrolling by pixels.
- **Reduced motion resolves the speed to ZERO, not slower** — this is motion with no other purpose, so a reader who asked for less of it has asked for none of this. `respectReducedMotion: false` is for a scroller that IS the content (a kiosk display nobody is holding).
- **A `Future.delayed` per touch outlived the widget** — resume-after-release scheduled one on every pointer-up and a future cannot be called off, on a control whose whole job is to be touched. Cancellable `Timer` now. (The carousel had the identical bug.)
- **A hold banked up pixels**: the elapsed clock ran while the drive was stopped, so a rail held for a minute jumped a minute's worth on release. The clock resets when the drive restarts, and `_syncTicker` is the only place it starts or stops.
- **Six flags hold it** — a finger, a resting pointer (`pauseOnHover`), being off screen (`pauseWhenOffscreen`; `TickerMode` only covers a covered ROUTE), a screen reader, the caller's controller, and the READER's own semantics pause. They overlap, so one bool could not say it.
- **A covered route banked up pixels.** `TickerMode` MUTES a ticker instead of stopping it and `Ticker.elapsed` keeps counting real time, so returning after three seconds handed the first frame three seconds of travel (310 px at 100 px/s, measured). Every tick delta is clamped — it catches mute, a debugger pause and a janked frame alike.
- **The builder is `(context, controller, still)`.** Reduced motion parking the speed at zero put the content of a `NeverScrollableScrollPhysics` list out of reach of every gesture, and only the CALLER can hand the physics back.
- **WCAG 2.2.2**: a moving rail publishes Pause / Resume as a `CustomSemanticsAction`, and `pauseWhenAccessibleNavigation` (on) holds it outright while a screen reader runs. The reader's hold is separate from the caller's — a programmatic resume must not undo it.
- **`GlobalAutoScroller.looping(itemCount:, itemExtent:, itemBuilder:)` is the SEAMLESS wrap.** `wrap` jumps to `minScrollExtent` visibly; an endless ticker needs the content repeated, which a driver owning no content cannot do. This builds the list itself, 200 laps of it, and corrects by exactly one lap. `itemExtent` is required because `ListView.builder` only ESTIMATES its extent, and a lap from a moving number does not line up.
- Also `edgeEaseDistance` (tapers into a `bounce` turn, to a FLOOR — easing to zero never arrives; skipped for `wrap`), `startDelay`, `onEdge` (once per arrival, not per frame).

### `GlobalScrollable` (`scrollable/`)
- Visual config is the **themeable bag** `ScrollableStyle` (all fields nullable, with `EdgeFadeStyle` as a sub-bag). App-wide defaults via `GlobalScrollableTheme` (`MyGlobalScrollableTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `ScrollableDefaults`. Presets: `page`, `article`, `bare`. See [`scrollable/CLAUDE.md`](scrollable/CLAUDE.md).
- **`EdgeFadeStyle` moved here from `list/`.** The text field, the slider, the breadcrumbs and the dropdown were all importing the LIST module to say how their scroll edge should look. `list_models.dart` re-exports it, so old imports still compile.
- **`list/` carried a SECOND copy of the fade AND the overlays** — six hundred lines duplicating this folder while `grid/` used the originals, so the same `EdgeFadeStyle` drew a different edge depending on which widget you handed it to. `test/scrollable/scrollable_adoption_test.dart` fails on a new copy.
- **A horizontal scrollable STARTS on the right in Arabic** — the fade band, the progress fill and the floating button were all pinned left whatever the language. A vertical fade does not mirror.
- **A `shader` fade is skipped entirely while neither band shows** — it is a viewport-sized saveLayer per paint, and `ShowcasePage` puts one on every page. Only that mode short-circuits: the other three need frames to animate their bands out. `blur` is the expensive mode (`blurStrips` layers per band, each a saveLayer plus a backdrop read) — panel, not page shell.
- **Scrolling no longer rebuilds the content**, and the content sits behind a `RepaintBoundary` so the progress strip does not re-rasterise the list with it. The overlays `setState` on every pixel and the child sat inside their `Stack`; the position lives in a `ValueNotifier` only the overlays listen to.
- **The wheel knobs are STYLE** (`smoothWheelScroll` / `wheelMultiplier` / `wheelSmoothness`) — they were flat widget params, so how scrolling feels could not be set once. Reduced motion turns the smoothing OFF rather than shortening it.
- **The scroll-to-top button had no name** — a bare `InkWell`, the one control floating over every long page. Hidden chrome is out of the semantics tree and refuses taps.
- Page-level scroll shell. Wrap `CustomScrollView` under `.custom` for slivers (which skips smooth wheel — slivers have nowhere to put the deeper `Listener`).
- Physics presets via `ScrollableMode` on the bag; nested handoff via `passThroughAtEdge`.
- **`ScrollInStyle` is the second bag here** — how a row ARRIVES, driving `GlobalList` / `GlobalGrid` entrances, on the same theme extension (`scrollInStyle`). Presets: `subtle`, `wave`. `animation` is the switch and the theme leaves it unset: a house sets the rhythm, never turns an entrance on for a list that never asked. **Reduced motion PLACES the row** instead of shortening it, and drops the cascade with it — nothing here read the setting at all before.
- **`ListItemAnimation.slideFromStart` / `slideFromEnd` mirror in Arabic; `slideFromLeft` / `slideFromRight` keep their side** — the same split the navigation transitions make. Resolved once at build time via `resolveDirection`, so every switch downstream sees only physical members.
- **Everything that scrolls a PAGE or a PANEL goes through it.** Eleven bodies were converted in the sweep (the system pages, the update gate, legal, FAQ, feedback, the wizard, settings). Virtualised item lists (`GlobalList`/`GlobalGrid`'s job), chrome strips, overlay bodies, content-package internals and the two screens that run without a theme stay raw — each listed with a reason in `test/scrollable/scrollable_adoption_sweep_test.dart`, which fails on a new one.
- **`cacheExtent` is `.custom` only.** A `SingleChildScrollView` caches nothing; the box constructor asserts instead of ignoring it in silence.

### `GlobalFilledButton` / `GlobalOutlinedButton` / `GlobalTextButton` / `GlobalIconButton` (`buttons/`)
- Each accepts `ButtonStateStyle` (normal/disabled/loading) + `ButtonLoadingStyle` (indicator type + position).
- `isLoading: true` + `result: ButtonResult.success` shows checkmark briefly; `onResultShown` resets.
- For social/sign-in/action variants, use pre-built classes under `lib/shared/common/buttons/`.

### `GlobalToast` (`toast/`)
- Static facade — `GlobalToast.s('Saved')`, `.e('Failed')`, `.w('Slow connection')`, `.i('Info')`.
- Requires `GlobalToast.navigatorKey = getIt<NavigationService>().navigatorKey` set in bootstrap (already wired) — a typed `GlobalKey`, since the module needs only that and must not import the data layer.
- Visual config is the **themeable bag** `ToastStyle` (all fields nullable). App-wide defaults via `GlobalToastTheme` (`MyGlobalToastTheme.build`, wired in `theme.dart`); per-call wins; floor in `ToastStyle.defaults`. Severity colours come from `context.statusColors`, never constants. See [`toast/CLAUDE.md`](toast/CLAUDE.md).
- **No package**: `ToastOverlay` is our own overlay engine (insert / stack / animate / time out / dismiss).
- Every toast **announces itself** to assistive tech; errors interrupt, everything else is polite.
- `onTap:` makes the whole toast a target and closes it after running; the close button and action keep their own taps.
- Notification-shaped toasts are `NotificationToast` (`shared/common/toasts/`) — it knows the notification domain, which this module deliberately does not.
- **Never use `ScaffoldMessenger.showSnackBar`** — `test/toast/no_snackbars_test.dart` fails the build. Two allow-listed exceptions, each with a reason.

### `GlobalBanner` (`banner/`)
- Visual config is the **themeable bag** `BannerStyle` (all fields nullable). App-wide defaults via the `GlobalBannerTheme` ThemeExtension (`MyGlobalBannerTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `BannerDefaults`. See [`banner/CLAUDE.md`](banner/CLAUDE.md).
- `resolve` takes `type:` — three colours are a function of it, so `defaults` carries none.
- Status colours come from `context.statusColors`. Material's green and orange were written in as hex, so a success banner ignored the palette and dark mode both.
- Reduced motion resolves the animation to `none`, not to a shorter one.
- The collapse chevron is a named button that renames itself as it flips; the live-region wrapper uses `explicitChildNodes` so its controls survive.
- Layout is `Row(icon, Column(Row(title, actions, controls), message))` — the message runs the full width under the actions. The glyph centres on a single line, and a long title marquees.
- Five entrances, all of which collapse the banner's height when hidden; swipe-to-dismiss (excluded from semantics, since a drag detector swallows every child node); a countdown line for `autoDismissDuration`; re-showing restarts the clock.
- Canonical wrappers live in `shared/common/banners/` — `OfflineBanner`, `UpdateAvailableBanner`, `MaintenanceBanner`.

### `GlobalIcon` (`icon/`)
- Visual config is the **themeable bag** `IconStyle` (all fields nullable). App-wide defaults via the `GlobalIconTheme` ThemeExtension (`MyGlobalIconTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `IconDefaults`. See [`icon/CLAUDE.md`](icon/CLAUDE.md).
- The glyph takes the ambient `IconTheme` BEFORE the palette — an icon in a button or app bar must follow that surface. The app's `ThemeData.iconTheme` is palette-built, so this is not a bypass.
- **RTL mirroring is opt-in** (`mirrorInRtl: false`). It used to mirror every glyph, so Arabic showed a backwards house. Glyphs carrying `matchTextDirection` are skipped — Flutter already flipped those, and flipping again undoes it.
- The badge slot is positioned by `GlobalBadge`; the module's own `IconBadge` constructors (with `Colors.red` baked in) are gone. Use `GlobalBadge.standalone(count: 3)`.
- `enabled: false` dulls the glyph, refuses the callbacks and tells a screen reader; `semanticLabel` names one without the tooltip that would make it interactive; `badgeCount:` / `badgeLabel:` / `badgeDot:` build the badge; every factory takes a `style:` merged over its own bag.
- The default size is `tokens.iconSizes.lg`, so icons grow with the window. `opacity` folds into the colours (no `saveLayer`) unless a gradient is involved. The stroke is one stroked-text glyph, not eight stamped copies.
- **Nothing under `lib/shared` may hand-roll a glyph in a decorated box** — thirteen did. `test/icon/icon_adoption_test.dart` fails on a new one; four module-own surfaces are allow-listed with reasons, `debug_overlay/` is exempt. Bare Material `Icon` is fine and untouched.

### `GlobalImage` (`image/`)
- Visual config is the **themeable bag** `ImageStyle` (all fields nullable). App-wide defaults via the `GlobalImageTheme` ThemeExtension (`MyGlobalImageTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `ImageDefaults`. See [`image/CLAUDE.md`](image/CLAUDE.md).
- The widget keeps SOURCE + layout (`width` / `height` / `aspectRatio`) + behaviour; the corner, frame, tint and error plate live in the bag. There were twenty-seven flat visual params forwarded through five factories.
- **RTL mirroring is opt-in** (`mirrorInRtl: false`). It used to mirror every picture, so Arabic showed mirrored photos and logos.
- The corner resolves against the ambient direction ONCE — the frame, the content clip and the inner shadow all read the same resolved value. It was hard-coded LTR in three places.
- `semanticLabel` decides the node: named → image, unnamed → decoration (out of the tree), plus `onTap` → button. There was no label parameter at all before.
- Prefer `AssetRef`-based sources over raw paths. Handles network/file/memory/asset uniformly.
- **Nothing else may draw a picture with a raw `Image.*` / `CachedNetworkImage`** — fourteen did. `test/image/image_adoption_test.dart` fails on a new one; five byte-producing sites (PDF pages, video frames, screenshots, link previews, mid-crop bytes) are allow-listed with reasons, `debug_overlay/` is exempt.
- `cacheNetwork: false` is the one escape hatch — markdown and HTML expose `cacheNetworkImages`, which is why it exists.

### `GlobalAvatar` (`avatar/`)
- Name-based color generation when `name` set + no `backgroundColor`. `style.statusDot` adds pulsing presence indicator.

### Media pickers (`media_picker/`)
- Four pickers over one contract: image, video, file, attachment. Visual config is the **themeable bag** `MediaPickerStyle` (all fields nullable). App-wide defaults via `GlobalMediaPickerTheme` (`MyGlobalMediaPickerTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `MediaPickerDefaults`. Presets: `avatar` / `composer` / `formField`. See [`media_picker/CLAUDE.md`](media_picker/CLAUDE.md).
- **`GlobalImagePicker` took thirty-three parameters.** Nine were visual or "which affordance" and each of the four pickers carried its own copy of the same numbers — `circular(14)` eight times. A tile in one picker and a tile in another are the same tile; the bag is what makes that true.
- **The cache is PASSED IN** (`recentCache:`), never looked up. The module used `getIt<RecentUploadsCache>()` in four files, which is the one hard rule this directory has.
- **`PickerInteractable.label` is required.** The module had not one accessible name in seven thousand lines.
- **Colours resolve from the palette, except what floats over MEDIA** — dot scrims, lightbox chrome and the upload ring stay white-on-black, the same call the video module makes.

### `GlobalAnimation` (`animation/`)
- Visual config is the **themeable bag** `GlobalAnimationStyle` (all fields nullable). App-wide defaults via the `GlobalAnimationTheme` ThemeExtension (`MyGlobalAnimationTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `GlobalAnimationStyle.defaults`. See [`animation/CLAUDE.md`](animation/CLAUDE.md).
- **It keeps the `Global` prefix on its bag** where the others drop it — Flutter's `material.dart` already exports an `AnimationStyle`.
- **Reduce motion stops an animation starting ITSELF**, and does not disable the controls. Flutter already pauses GIFs under `disableAnimations`, so before this a Lottie beside one kept playing. `respectReducedMotion: false` is for animations that ARE the content, never for decoration.
- **`TickerMode` is how a GIF pauses**, holding the frame it is on. Rebuilding it with a new key restarts decoding, which is "stop and start over", not "pause".
- **Speed is a DIVISOR of the duration** — zero and negatives throw out of the controller, so they are clamped on the way in. GIFs ignore speed entirely; the frame delays are in the file.
- The error plate degrades to the GLYPH alone below `errorPlateMinHeight`, because a 40dp animation cannot hold a headline and a retry line.
- **`semanticLabel` decides the node**: named → content, unnamed → decoration and out of the tree. The transport row and the error plate stay reachable either way.
- **A player scrolled out of view pauses** (`pauseWhenOffscreen`, on) — `TickerMode` only covers a covered ROUTE. One paused by hand stays paused when it scrolls back.
- **`AnimationHandle` is the control surface** (`GlobalAnimationState` implements it), with `onStateChanged` / `stateStream` carrying an `AnimationStateSnapshot`. A GIF reports no progress and no duration — Flutter's decoder owns its clock.

### `GlobalAudio` / `GlobalVideo` (`audio/`, `video/`)
- Use `getIt<AudioPlayerManager>()` / `getIt<VideoPlayerManager>()` to enforce concurrent-player caps. Don't construct raw `AudioPlayer`/`Player` in widgets.
- DSP utilities (FFT band extraction, waveform decode) live in `lib/core/audio/`, not the module.
- **`GlobalAudioPlayer`**: visual config is the themeable bag `AudioStyle` (all fields nullable), app-wide via `GlobalAudioTheme` (`MyGlobalAudioTheme.build`, wired in `theme.dart`), floor in `AudioDefaults`. The resolve happens ONCE per build and is handed down — `AudioWaveform` takes a RESOLVED bag, because each variant used to answer the leftover colours itself out of `Theme.of` and a waveform could disagree with the player around it. **A tooltip is not a label**: `_CircleIcon.label` is required, since a tooltip is what a pointer discovers and these readers have none. See [`audio/CLAUDE.md`](audio/CLAUDE.md).
- **`GlobalVideo`**: visual config is the themeable bag `VideoStyle` (all fields nullable), app-wide via `GlobalVideoTheme` (`MyGlobalVideoTheme.build`, wired in `theme.dart`), floor in `VideoStyle.defaults`. **The `show*` / `enable*` flags are STYLE**, not widget arguments — which chrome an app offers is a decision about the app, and a theme is the only place that can say it once. **Controls do NOT take the palette's text colours** — they float over arbitrary pixels, so white-on-scrim; only the seek-bar accent is brand. See [`video/CLAUDE.md`](video/CLAUDE.md).

### `GlobalScanner` (`scanner/`)
- Visual config is the **themeable bag** `ScannerStyle` (all fields nullable). App-wide defaults via `GlobalScannerTheme` (`MyGlobalScannerTheme.build`, wired in `theme.dart`); per-call `style:` wins; floor in `ScannerDefaults`. Presets: `minimal` / `focused` / `wide`. See [`scanner/CLAUDE.md`](scanner/CLAUDE.md).
- **Only the viewfinder is a palette colour.** The controls sit on camera pixels, so they are white-on-scrim — the same argument the video module makes.
- **The box RESTRICTS reads** (`restrictToViewfinder`, on). The rect comes from `ResolvedScannerStyle.viewfinderRect`, which the painter and the plugin's scan window both use — a box drawn over a frame scanned edge to edge is a box that lies.
- **The camera's state is read from the controller**, never mirrored: a front camera has no torch, and a local flag said "on" over a light that never came on. Controls that cannot work are not drawn.
- **The lifecycle is the CALLER's** whenever a controller is passed in, which this module does — so it stops on background and restarts on resume. Nothing did, and a scanner came back to a frozen preview.
- **`single` stops the camera before it reports**, and refuses everything after: `noDuplicates` only suppresses the same code, so a second one entering frame during the pop reported over the first.

### `GlobalPdfViewer` (`pdf/`)
- Visual config is the **themeable bag** `PdfStyle` (all fields nullable). App-wide defaults via the `GlobalPdfTheme` ThemeExtension (`MyGlobalPdfTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `PdfStyle.defaults`. See [`pdf/CLAUDE.md`](pdf/CLAUDE.md).
- Persist-key driven; saves last-read page + bookmarks via `PdfBookmarksCubit`. Pass `bookmarksCubit:` to `PdfRecentDocsList` from `getIt`.
- **`initialPage` and `heroTag` are on the WIDGET, not the style** — where a reader is in a document, and a document's identity, are not how viewers look.
- **The compact preview flies into the viewer by DEFAULT.** Both ends derive the tag from the document. Two previews of the same document on one screen need `enableHero: false` or their own tag, because `Hero` requires uniqueness within a route.
- **The bottom bar fits itself**: controls are declared as GROUPS, each shown whole or moved into the overflow menu whole. Nothing is hidden, only moved. A narrow bar shrinks what a button paints, never its 48dp target.
- **`panEnabled` is ON, and embedded viewers should turn it OFF** — a drag belongs to the document or to the page around it, never both.
- **The module owns the download**: one fetch per persist key, shared by every viewer over it, so a compact card and the fullscreen route it opens do not each hit the network.
- `GlobalPdfViewer.openFullscreen` is the route a card opens; `pickFromDevice` / `openFromDevice` are the device picker; `PdfCache` clears what outlives a viewer.
- Night mode is invert composed with a half-turn hue rotation (iOS's "Smart Invert"), so text reads without turning every photograph into a negative.
- Keyboard shortcuts (⌘F, arrows, +/−, ⌘0, R, ⌘P, Esc) are on for every platform, not just desktop.

### `GlobalAppBar` / `GlobalSliverAppBar` (`app_bar/`)
- Visual config is the **themeable bag** `AppBarStyle` (all fields nullable), shared by both widgets. App-wide defaults via the `GlobalAppBarTheme` ThemeExtension (`MyGlobalAppBarTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `AppBarDefaults`. See [`app_bar/CLAUDE.md`](app_bar/CLAUDE.md).
- `toolbarHeight` is CALLER-ONLY — `preferredSize` has no `BuildContext`, so theming it would paint one height while the Scaffold laid out another. The theme asserts against it.
- Colors resolve from `context.<group>Colors`, and the variant participates: transparent/gradient bars go transparent + white because there is no surface behind them.
- Scroll-aware coloring: `GlobalSliverAppBar` with `pinned: true` + `floating: false` defaults.
- `searchMode` renders a deliberately bare field — the module can't import commons. For debounce / recents / suggestions / scopes use `SearchAppBar` (`shared/common/app_bars/`) or pass a `SearchTextField` through the `searchField` slot.

### `GlobalTabBar` / `GlobalTabView` (`tab_bar/`)
- Visual config is the **themeable bag** `TabBarStyle` (all fields nullable). App-wide defaults via the `GlobalTabBarTheme` ThemeExtension (`MyGlobalTabBarTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `TabBarDefaults`. See [`tab_bar/CLAUDE.md`](tab_bar/CLAUDE.md).
- `height` is CALLER-ONLY — same reason as the app bar's `toolbarHeight`. The theme asserts against it. Use `style.preferredHeightFor(tabs)`.
- Colours are set on `TabBar` (`labelColor` / `unselectedLabelColor`), never on the glyphs — that is what crossfades a tab mid-swipe.
- A disabled tab is refused in `onTap` (`index =`, not `animateTo`). `IgnorePointer` inside a `Tab` does nothing: `TabBar`'s InkWell sits above the child.
- Tabs rebuild against `controller.animation`, which is what makes `activeIcon` / `activeCustomIcon` work at all.
- **Segmented controls are NOT here.** `GlobalSegmentedControl` (generic, themeable, tested) lives in `segmented_control/`; this module used to export a second class under the same name, which made importing both an ambiguous-import error. Vertical side-panel tabs are `GlobalNavigationRail(extended: true)`.

### System pages (`system_pages/`)
- Use `SystemPageAppBar(title:)` — never a hand-rolled `GlobalAppBar`. A system page can be the FIRST screen someone sees (dead deep link → 404, failed boot → error, pre-launch → coming-soon), so its bar must offer language + theme via `QuickPreferenceActions` or the user is stuck with whatever the device guessed. Guard: `test/system_pages/system_page_app_bar_test.dart` asserts all three pages use it.
- Don't pass `showBack: Navigator.of(context).canPop()` — `GlobalAppBar` already drops the leading widget when the route can't pop.

### `GlobalDrawer` (`drawer/`)
- Visual config is the **themeable bag** `DrawerStyle` (all fields nullable). App-wide defaults via the `GlobalDrawerTheme` ThemeExtension (`MyGlobalDrawerTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `DrawerDefaults`. See [`drawer/CLAUDE.md`](drawer/CLAUDE.md).
- `scrimColor` is CALLER-APPLIED — the backdrop is `Scaffold.drawerScrimColor`, which the scaffold paints, not the drawer. `GlobalDrawer.scrimOf(drawer)` is the seam.
- Background is `backgroundColors.container`, not `surface`: a drawer sits above the page.
- Mini mode owns its width; a caller's `width` is ignored there.
- The staggered entrance is SKIPPED under reduced motion, not shortened.

### `GlobalDivider` (`divider/`)
- Visual config is the **themeable bag** `DividerStyle` (all fields nullable). App-wide defaults via the `GlobalDividerTheme` ThemeExtension (`MyGlobalDividerTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `DividerDefaults`. See [`divider/CLAUDE.md`](divider/CLAUDE.md).
- `style:` is the BAG; the line kind is `lineStyle:`. The enum used to own the bag's name.
- A rule takes `textColors.secondary` at half strength — an outline is a control's border and reads heavier.
- A plain rule is decoration and says NOTHING to a screen reader; only a labelled or tappable one earns a node.
- It does NOT report a value — `GlobalDivider.progress` was a weaker `GlobalProgress(type: linear)` and is gone.
- **Nothing else may name a Material `Divider` / `VerticalDivider`.** Ten module sites and the commons `ShowcaseDivider` went through `GlobalDivider`; `test/divider/divider_adoption_test.dart` fails on a new one. `debug_overlay/` is exempt by agreement.

### `GlobalTooltip` (`tooltip/`)
- Visual config is the **themeable bag** `TooltipStyle` (all fields nullable). App-wide defaults via the `GlobalTooltipTheme` ThemeExtension (`MyGlobalTooltipTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `TooltipDefaults`. See [`tooltip/CLAUDE.md`](tooltip/CLAUDE.md).
- Renders through the POPUP engine, not Material's `Tooltip`: Material clamps near a screen edge but never says by how much, so a bubble's arrow cannot be corrected there. The popup reports its own drift.
- `TooltipTrigger` picks the gesture — `hoverOrLongPress` (default), `hoverOnly` (leaves long-press to the host), `none` (semantics only).
- `find.byTooltip` will NOT find these; find by the announced tooltip instead.
- `resolve` takes `shape:` and `preferBelow:` — a bubble stands further off the child, and its arrow points back the way the tooltip came.
- The surface INVERTS against the page: high-contrast on light, raised container (plus a border) on dark.
- **Nothing else may use Material's `Tooltip` raw.** Eight modules did; `test/tooltip/global_tooltip_test.dart` fails on a new one.

### `GlobalEmptyState` (`empty_state/`)
- Visual config is the **themeable bag** `EmptyStateStyle` (all fields nullable). App-wide defaults via the `GlobalEmptyStateTheme` ThemeExtension (`MyGlobalEmptyStateTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `EmptyStateDefaults`. See [`empty_state/CLAUDE.md`](empty_state/CLAUDE.md).
- `resolve` takes `variant:` — glyph size, spacing and padding mean different numbers full-page and inline, so `defaults` deliberately carries no sizes.
- The entrance is armed in BUILD, not `initState`: reduced motion is a `MediaQuery` and cannot be read there.
- The fade sets `alwaysIncludeSemantics` — an `Opacity` at zero drops its subtree from the semantics tree entirely.
- `fullPage` needs bounded height — in an unbounded parent it collapses to its content and loses its centring (it does NOT throw); `compact` is the variant for a `Column` or a list.
- It ANNOUNCES itself once per message and replays its entrance when the message changes — a list going empty is otherwise silent to a screen reader.
- `list` and `grid` render it; the four canonical cases are commons wrappers in `shared/common/empty_states/`.

### `GlobalChip` (`chip/`)
- Visual config is the **themeable bag** `ChipStyle` (all fields nullable). App-wide defaults via the `GlobalChipTheme` ThemeExtension (`MyGlobalChipTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `ChipDefaults`. See [`chip/CLAUDE.md`](chip/CLAUDE.md).
- `resolve` takes `variant:` / `selected:` / `enabled:` — a chip's colours are a function of all three, and Material needs both fills at once to cross-fade them.
- Built on `RawChip`, which is the only one of Material's three that does selection AND deletion. A ✕ inside a `ChoiceChip` label is dead: the label sits under an `IgnorePointer`.
- The count pill is a `GlobalBadge`, washed neutral — a chip count is "how many", not "something is wrong".
- Three roles, picked by callback: `onSelected` = choice (button + selected state), `onPressed` = action (button, no state), neither = static label. Passing both asserts. `onDeleted` composes with any of them.
- **Nothing else may name a Material chip.** `faq/`, `wizard/`, `date_time_picker/`, `text_field/surfaces/` and `drop_down/surfaces/` all went through `GlobalChip`; `test/chip/chip_adoption_test.dart` fails on a new one. `debug_overlay/` is exempt by agreement.

### `GlobalRating` (`rating/`)
- Visual config is the **themeable bag** `RatingStyle` (all fields nullable). App-wide defaults via the `GlobalRatingTheme` ThemeExtension (`MyGlobalRatingTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `RatingDefaults`. See [`rating/CLAUDE.md`](rating/CLAUDE.md).
- Omitting `onChanged` IS display mode — it drops pointers, focus and semantic actions together.
- A POINTER ceilings to the star under it (`RatingPrecision.snapUp`); a keyboard step rounds. Tapping star three has to score three.
- Pointer offsets and arrow keys are both mirrored in RTL — `Row` puts star 0 at the right edge.

### `GlobalBottomNav` / `GlobalNavigationRail` (`bottom_nav/`, `navigation_rail/`)
- Both follow the `GlobalDestination` model, shared with the drawer — one destination list across surfaces.
- **`GlobalScaffold` is the ONLY thing that picks between them.** `BottomNavStyle.enableSideRail` used to ask the bar to swap itself past a width, which a widget in the `bottomNavigationBar` slot cannot do — it produced a rail covering the whole screen with the page collapsed behind it. Choosing the surface means rebuilding the Scaffold's structure (`bottomNavigationBar:` → `body: Row([rail, body])`), so it belongs to the scaffold.
- **The rail wears the BAR's bag**, via `railStyleFrom` / `railItemFrom` (`bottom_nav/bottom_nav_as_rail.dart`). `NavigationRailStyle` is pre-gold-standard — non-nullable fields, no theme extension — so without the mapping a rebrand moved the bar and left the rail on Material's numbers.
- Visual config is the **themeable bag** `BottomNavStyle` (all fields nullable). App-wide defaults via the `GlobalBottomNavTheme` ThemeExtension (`MyGlobalBottomNavTheme.build`, wired in `theme.dart`); per-call `style:` wins; compile-time floor in `BottomNavStyle.defaults`. See [`bottom_nav/CLAUDE.md`](bottom_nav/CLAUDE.md).
- **The bar's surface is the CONTAINER**, not the surface — it sits above the page. Its shadow is the palette scrim, and a prominent item's glyph is `iconColors.onPrimary`; they were `Colors.black` and `Colors.white`.
- **`initState` cannot read the resolved bag** — it runs before `didChangeDependencies`, and resolving needs the palette. The bounce and hide controllers gate on the CALLER's bag, which is right: a theme should not switch on tap-bounce for a caller who never asked.
- **Every destination is one Semantics node** — labelled, positioned ("Tab 2 of 5"), selected, and carrying its badge in the label. There was none before.

### Debug chrome (`debug_overlay/widgets/debug_chrome.dart`)
- **`DebugChrome` holds the tokens every piece of harness UI shares** — a near-black translucent capsule, a thin flavour-tinted stroke, a soft drop shadow, white content. It reads as "this is the harness, not the app" at a glance, and does it WITHOUT touching the app's palette, which is the point: debug chrome has to stay legible over a half-finished theme.
- **It is deliberately outside the theme system.** No `context.<group>Colors`, no `ThemeExtension`. The accent is the FLAVOUR's banner colour (`DebugChrome.accent`), so dev / staging / uat / prod stay tellable apart on the one surface that exists to tell you where you are.
- **The widget inspector's buttons go through `DebugChromeButton`.** They were a Material `FloatingActionButton` in `colorScheme.primary` plus two `GlobalIconButton`s reading `Theme.of(context).colorScheme` — app theming, on the surface that sits outside it, so a purple FAB landed next to the black pill and neither looked deliberate.
- **`selected` FILLS the capsule** rather than tinting it. The framework's own select-on-tap toggle changed so little between states that it read as a button that did not react.
- **No `Tooltip` in any of it.** These render above the `Navigator`, so there is no `Overlay` ancestor and `Tooltip` asserts. The label goes to `Semantics` — which is what the framework's own inspector buttons do.
- Guards: `test/debug_overlay/debug_chrome_test.dart`, including a drift guard that the pill and the buttons paint the same surface.

### Canonical containers (`../common/containers/containers.dart`)
- **`GlobalContainer` is the source for rows and cards.** Material's `ListTile`, `Card`, `ExpansionTile` and `SwitchListTile` each draw their own surface from `Theme.of(context)` — a different corner, fill and shadow from every `GlobalContainer` beside them, and none of them move on a rebrand.
- The container already had the anatomy: with no `child` it builds `Row(leading, Column(title, subtitle), trailing)`, which IS a tile. What it lacked was a NAME (`GlobalContainer.tile`), a floor a finger can hit (`tileMinHeight`, 48dp) and slots that box an oversized glyph (`slotSize`, 40dp — the same thing `ListTile` does).
- Wrappers: `AppTile`, `AppNavTile` (chevron — three places had hand-rolled it), `AppSettingTile` (`SwitchListTile`), `AppCard`, `AppMediaCard`, `AppExpansionTile`, `AppSwipeTile`, `AppSelectableCard`. Every one takes `style:` through to `ContainerStyle`, so none is a wall.
- **`titleWidget` / `subtitleWidget` exist because `ListTile.title` is a Widget.** A tile factory that only takes a String is a wall — the FAQ list highlights the matched substring and had nowhere to put it.
- **Primitive modules use `GlobalContainer.tile` directly**, not the wrapper: `share/` is a primitive and primitives never import `shared/common/`.
- Guard: `test/container/container_adoption_test.dart`. `system_pages/error_app.dart` is allow-listed — it runs when `bootstrap()` itself threw, so it must not touch the palette, and every wrapper resolves colours through it.

### Loading + error overlays
- `LoadingCubit` (`core/loading/`) — push/pop scopes via `context.read<LoadingCubit>().show()/hide()`. Has debounce + minVisible to avoid flash.
- `GlobalErrorBoundary` (`core/error/`) — wrap risky subtrees with optional `fallbackBuilder`.
- `MaintenanceGate` (`core/maintenance/`) — already wraps `MaterialApp.builder`. Triggered by RC `force_maintenance` or API 503.
