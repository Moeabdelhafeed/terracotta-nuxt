# CLAUDE.md — lib/shared/module/text_field

Composable text input built on `TextFormField`. One widget, config
grouped into eight params — style (the themeable visual bag, resolved
through a popup-style theme/defaults merge), behavior, validation,
features, slots, callbacks, sizing, and a `List<FieldMessage>`.

Purpose-shaped fields (email, password, OTP, credit card…) are NOT
factories on this widget — they are app-owned wrapper widgets in
[`lib/shared/common/text_form_fields/`](../../common/text_form_fields/),
each composing these configs. This keeps domain shapes out of the
module and layered above it.

## Table of contents

- [Folder layout](#folder-layout)
- [Choosing an entry point](#choosing-an-entry-point)
- [Pre-built wrappers](#pre-built-wrappers)
- [Configs](#configs)
- [Usage recipes](#usage-recipes)
- [Caller gotchas](#caller-gotchas)
- [Pre-built surfaces](#pre-built-surfaces)
- [Resolved-style invariant](#resolved-style-invariant)
- [Theming](#theming)
- [Hard rules (project conventions)](#hard-rules-project-conventions)
- [Anti-flicker invariants (don't touch)](#anti-flicker-invariants-dont-touch)
- [Deferred TODOs](#deferred-todos)
- [Showcase](#showcase)

## Folder layout

```
text_field/
  text_field.dart                 — barrel (re-exports widget + models + formatters)
  global_text_field.dart          — declarative widget;
                                     owns the `part` graph below
  controller/
    text_field_state.dart         — State engine: lifecycle, focus, validation,
                                     suggestions overlay, build (part)
    text_field_state_features.dart — undo/redo, chips, voice handlers (part)
    field_validation_controller.dart — FieldValidationController (owned by State)
    undo_redo_stack.dart          — UndoRedoStack (pure, standalone)
    inline_ghost_controller.dart  — InlineGhostTextController (standalone)
    suggestion_filter.dart        — SuggestionFilter (pure list math)
  input_formatters/
    text_field_input_formatters.dart — sub-barrel; one formatter per file
                                     (currency / credit_card / mask / expiry /
                                     iban / color_hex)
  models/
    text_field_models.dart        — sub-barrel (+ re-exports popup types used
                                     by SuggestionsConfig.overlayOptions)
    text_field_enums.dart         — ValidationMode
    text_field_defaults.dart      — TextFieldDefaults: EVERY hard-coded
                                     constant (shape, borders, slots,
                                     fit-width, messages, timings)
    text_field_style.dart         — TextFieldStyle (themeable bag) +
                                     ResolvedTextFieldStyle
    text_field_border.dart        — TextFieldBorderStyle + TextFieldBorderSide
                                     (+ resolved forms)
    text_field_behavior.dart      — TextFieldBehavior (caller-only)
    text_field_validation.dart    — TextFieldValidation + FieldRequirement
    text_field_suggestions.dart   — SuggestionsConfig + Chips/Voice/Counters/
                                     Animations configs + TextFieldSpeechAdapter
    text_field_features.dart      — TextFieldFeatures
    text_field_slots.dart         — TextFieldSlots + TextFieldSuffix sealed union
    text_field_callbacks.dart     — TextFieldCallbacks
    text_field_sizing.dart        — TextFieldSizing (box geometry + density)
    text_field_messages.dart      — FieldMessage + FieldMessageType
  surfaces/
    text_field_state_panels.dart  — header / chips / counter / strength bar /
                                     requirements / inline suggestions / suffix
                                     composition (part)
    color_preview.dart            — TextFieldColorPreview (standalone widget,
                                     live #RRGGBB swatch)
  theme/
    text_field_theme.dart         — GlobalTextFieldTheme ThemeExtension

─── In core/theme/widget_themes/ ───
  global_text_field_theme.dart    — MyGlobalTextFieldTheme.build factory
                                     (wired into core/theme/theme.dart)
```

> The `text_field_state*.dart` + `surfaces/text_field_state_panels.dart`
> files are `part of '../global_text_field.dart'` — the State remains the
> lifecycle owner, split across part files by concern. The
> Flutter-independent logic lives in standalone classes (see
> [Engines](#engines-pure-unit-testable)).

## Choosing an entry point

| You want…                                                   | Use                                                                                                                                                                                    |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| A purpose-shaped field (email, password, phone, OTP, card…) | an app-owned wrapper from [`shared/common/text_form_fields/`](../../common/text_form_fields/) — `EmailField(...)`, `PasswordField(...)`, `OtpField(...)`, `CreditCardField(...)`, etc. |
| A custom field                                              | the `GlobalTextFormField(...)` constructor with grouped configs                                                                                                                        |
| App-wide visual rebrand                                     | `MyGlobalTextFieldTheme.build(...)` / a `GlobalTextFieldTheme` extension                                                                                                               |

Start with a wrapper. Drop to the raw constructor only when no wrapper fits.

```dart
GlobalTextFormField(
  controller: c,
  hint: 'Email',
  style: const TextFieldStyle(
    border: TextFieldBorderStyle(
      base: TextFieldBorderSide(color: Colors.purple),
    ),
  ),
  behavior: const TextFieldBehavior(keyboardType: TextInputType.emailAddress),
  validation: TextFieldValidation(validator: Validators.validateEmail),
);
```

## Pre-built wrappers

App-owned wrappers in
[`lib/shared/common/text_form_fields/`](../../common/text_form_fields/)
cover the common shapes — full wrapper/composite contract, catalog, and
add-a-field checklist in
[its CLAUDE.md](../../common/text_form_fields/CLAUDE.md):

- **Account** — `LoginForm` (the sign-in composite: `identifierType`
  email/phone/emailOrPhone/username × `showPassword` toggle covers
  classic, MENA either-way, magic-link and OTP flows; AutofillGroup with
  saved-credential hints, focus chain, keyboard-done `onSubmit`, emits
  `LoginFormData`; call `LoginForm.finishAutofill()` after success so
  the OS offers to save), `RegistrationForm` (sign-up composite:
  `showEmail`/`showPhone` × `RegPasswordMode` none/create/createConfirm;
  `emailRequired`/`phoneRequired` make a shown identifier OPTIONAL —
  empty passes, non-empty runs full rules, ≥1 must stay required (also
  `required` params on EmailField/PhoneNumberField themselves);
  create mode gets strength bar + requirements, confirm live-matches,
  `newPassword` hints, emits `RegistrationFormData`),
  `ChangePasswordForm` (current + new + confirm in one AutofillGroup;
  new must differ from current + pass complexity, generate fills confirm
  too; `requireCurrent: false` turns it into the RESET-password pair for
  post-OTP flows; `ChangePasswordForm.finishAutofill()` after success),
  `OtpVerificationForm` (OtpField + the verify-screen ceremony: masked
  "Code sent to {destination}" line, resend button with live cooldown
  countdown — async `onResend` spins then restarts the clock — and
  `errorText`/`success` passthrough driving auto-clear/lock),
  `EmailField` (domain ghost / whitelist / MX verify),
  `PasswordField` (login / create / confirm modes; breach check, capture
  protection, generator, strength), `PhoneNumberField` (country
  dictionary: lengths, mobile prefixes, grouping; SIM/locale default,
  smart paste), `NationalIdField` (KYC civil-number input, dictionary-
  driven via `NationalIdSpecs` — JO plain 10, SA 10 + Luhn + citizen/
  resident kind, EG 14 with embedded birth date/gender/governorate
  (en+ar names), AE 15 `784…` + Luhn + birth year, KW 12 + mod-11;
  joined country picker, semantic digit grouping + template ghost,
  Eastern-Arabic digit normalization, per-error localized messages,
  `showParsedInfo` live row "Born 14 May 2001 · Cairo · Male", generic
  length fallback for unlisted countries, emits `NationalId`; KYC
  cross-checks: `mustMatchBirthDate` (linked DateField controller — live
  "ID doesn't match the birth date"), `minAge` from embedded birth data,
  `allowedKinds` citizen/resident gates, smart paste auto-switches the
  country only on strong (structure/checksum) evidence, pre-filled
  values group at mount),
  `EmailOrPhoneField` (MENA login identifier — ONE input
  morphing live between the email and phone faces: digits/`+`/Eastern-
  Arabic digits (typed or pasted) flip to the phone face with country
  picker, a letter/`@` flips back keeping the text; emits sealed
  `LoginIdentifier` = `EmailLoginIdentifier` / `PhoneLoginIdentifier`,
  `null` when empty), `NameField` (first / last / middle / father / full
  modes; script restriction, profanity check, `FullName` callback),
  `UsernameField`.
- **Payment** — `PaymentCardForm` (composite: cardholder? + number +
  expiry + CVV, focus chain, brand → CVV length, parsed `PaymentCard`),
  or the pieces: `CreditCardField` (brand detection + `brandDetector`
  BIN hook, saved-card masking, capture protection),
  `DateField.cardExpiry` (MM/YY mode — replaced `ExpiryDateField`),
  `CvvField`, `CardholderNameField`, `IbanField` (registry-exact
  per-country lengths + mod-97), `SwiftBicField` (ISO 9362 — segment
  validation with per-failure messages, 8/11 length, country checked
  against the registry, uppercase + `DEUT DE FF 500` grouping + ghost,
  `mustMatchIban` live country cross-check against the sibling IbanField,
  "Germany · Head office" info row, test-BIC warning, `allowedCountries`,
  `required: false` lets an EMPTY BIC pass while a typed one still fully
  validates, emits `SwiftBic`), `BankAccountForm` (composite: full-name
  holder + IbanField + SwiftBicField with `mustMatchIban` pre-linked;
  `bicRequired` knob, emits `BankAccountData` with normalized IBAN +
  parsed BIC + BIC↔IBAN country in `isValid`).
- **Support** — `ContactForm` (full name + email + optional call-back
  phone + counted multiline message; one AutofillGroup; multiline eats
  the keyboard-done, so gate YOUR send button on
  `ContactFormData.isValid`; `MultilineTextField` gained
  `required`/`deferToParentForm` for it).
- **Layout** — `ResponsiveFieldRow` (width-aware form layout: give each
  `ResponsiveField` a `minWidth`; it greedily packs consecutive fields
  into rows and wraps when the next won't fit, collapsing to one-per-row
  when narrow. A wide field naturally lands alone as the viewport
  shrinks; `keepWithNext` binds fields so they never split. In-row width
  is `Expanded`, flex proportional to `minWidth`. Used by `AddressForm`
  for the area+postal row; reuse for any composite.)
- **Misc** — `AddressForm` (composite shipping/billing address —
  country-driven via `AddressSchemas`: pick a country and the field set
  reshapes (JO/EG/SA governorate-or-region labels, AE emirate dropdown +
  NO postal field, US ZIP mask, UK alphanumeric postcode); EG/AE offer a
  fixed subdivision DROPDOWN reusing the national-ID governorate data
  (en+ar), others free-text; per-country postal mask + validation, focus
  chain, `initialAddress` prefill, emits `Address` with a country-aware
  `formatted` multi-line string; generic fallback for unlisted
  countries. Dependent AREA narrowing: a governorate with curated
  districts (JO Amman / EG Cairo…) turns the area field into a scoped
  dropdown; uncovered ones stay free text. Delivery extras (opt-in):
  `showAddressType` home/work/other, `showRecipient` (a full-mode
  `NameField`), `showPhone` (a `PhoneNumberField` dial-synced to the
  country), `showLocation`, `showNotes` multiline courier instructions.
  `onReverseGeocode` (wire `ReverseGeocodingService
.reverseGeocodeAddress`): a GPS/map PICK — never typed coords —
  reverse-geocodes and fills EMPTY fields only. `Address` has
  `toJson`/`fromJson`/`copyWith` for address-book persistence. Auto-
  advances field-to-field incl. dropdown picks), `LocationField`
  (lat/long inputs, range-checked, in a `ResponsiveFieldRow`; GPS button
  via `LocationUtils.currentPosition` with a `fetchCurrentLocation`
  test override; map-pick button → `LocationPickerSheet` draggable
  GoogleMap + centre pin; emits `LocationValue` with `.latLng`),
  `PercentField` (0–100 default bounds, `max` HARD-BLOCKED at
  the keystroke, `allowDecimal`/`decimalPlaces` blocked likewise,
  Eastern-Arabic digits + `٫` normalize, locale `%`/`٪` affix, ↑/↓
  steps by `step` clamped to bounds, emits `Percent` with `fraction`),
  `PromoCodeField` (checkout apply flow as a state machine
  `idle → applying → applied | failed`: trailing Apply button / Enter,
  suffix spinner + mid-flight lock, server-driven `PromoOutcome`
  success/failure copy, applied = read-only + success row + ✕ remove,
  typing clears a rejection, uppercase + `A–Z0–9-` charset,
  `initialAppliedCode` restore, sealed `PromoCodeState` emission),
  `TagsField` (chips input: submit/separator commits typed
  text, paste explodes on separators, backspace-pop, suggestion
  pick-to-add with stay-open multi-pick + selected checks + tap-to-toggle,
  tap-a-chip-to-edit, duplicate-add pulses the existing chip, `3/5`
  counter + max-reached row, `readOnly` = chips-only display surface,
  `chipStyle`/`chipBuilder` visuals, one normalize/veto pipeline —
  trim/lowercase/dedupe/maxTagLength/tagValidator/vocabulary-only —,
  min/max count validation; module side: `ChipsConfig.addOnSubmit` /
  `separators` / `removeLastOnBackspace` / `beforeAdd` / `editOnTap` /
  `showCounter` / `style` / `chipBuilder`; overlay keyboard nav ↑/↓ +
  Enter/Esc works for ALL suggestion fields), `NumberField` (flip `allowDecimal` for integers),
  `AmountField`, `UrlField`, `PassportNumberField`, `OtpField`,
  `PlateNumberField` (per-country plate patterns JO/SA/AE + generic,
  country-charset keystroke filter, emits `PlateNumber`),
  `CryptoAddressField` (network auto-detect ETH/BTC-legacy/bech32/TRON or
  pinned, structure-only by design — checksums need keccak/sha and fail
  at the node anyway; info row names the detected network, emits
  `CryptoAddress`), `VinField` (17 chars, I/O/Q blocked at the keystroke,
  REAL ISO 3779 check digit, model-year decode + info row, emits `Vin`
  with `wmi`), `IpHostField` (IPv4/IPv6 via Dart's own `Uri.parseIPvX`
  parsers — web-safe — + RFC hostnames, `allowPort` incl. `[::1]:8080`,
  `mode` any/ipOnly/hostOnly, emits `IpHost`),
  `ColorField`, `DateField` (masked typing in five orders —
  `DD/MM/YYYY` / `MM/DD/YYYY` / `YYYY/MM/DD` / `MM/YY` / `DD/MM` —
  locale digit order with locale-switch re-expression, LTR-pinned
  editor + localized hint, Eastern-Arabic digits, ↑/↓ segment
  stepping, 2-digit-year expansion, calendar dialog/sheet, smart
  paste, weekday/blackout/notice rules, cross-field after/before,
  Hijri companion row; `.dob` / `.expiry` / `.past` / `.cardExpiry`
  presets), `DurationField` ("how long" — masked `hh:mm`/`hh:mm:ss`/
  `mm:ss` via `DurationInputFormatter`, `maxDuration` hard-blocked at
  the keystroke, `minDuration`/`minuteStep` validation, ↑/↓ caret-segment
  stepping with grid snap + haptic, localized "1h 30m" summary row,
  CupertinoTimerPicker bottom sheet, emits `DurationValue`),
  `DateRangeField` (start+end composite: focus chain,
  cross-validation, nights row, `DateRange`), `TimeField` (`HH:mm[:ss]`
  mask, 12/24h via device / pinned / a user-facing format dropdown,
  joined AM/PM picker, smart paste of any notation, 12h auto-PM typing
  - `a`/`p`/`ص`/`م` keys, format-switch re-expression, min/max +
    overnight windows, minute-grid intervals, cross-field `mustBeAfter`,
    Now action, width-adaptive suffix actions, ↑/↓ stepping with haptics,
    clock picker dial/input, imperative `applyTime` channel,
    `TimeValue`), `TimeRangeField` (start+end: focus chain, duration row,
    overnight spans, `TimeRange`), `DateTimeField` (date + time → one
    `DateTime`; joined segmented layout with a single date→time picker
    button, or split; boundary-day min/max windows, `DateTimeValue`),
    plus generic `SimpleTextField` / `MultilineTextField` /
    `SearchTextField`.

Each wraps the raw `GlobalTextFormField` — setting keyboard, formatters,
a default validator + an appropriate prefix/suffix — behind the shared
text-form-field contract. Add new shapes there, not as methods here.

> **PCI note (payment fields).** Production payments normally go through
> a PSP SDK (Stripe, Checkout, HyperPay…) whose own components keep raw
> card data out of your app and you out of most of PCI-DSS scope. These
> fields are for the UIs that legitimately remain yours: card-on-file
> display (`obscureWhenUnfocused`), custom acquirer integrations, and
> PSPs with raw-PAN server APIs. If you collect a PAN with these fields,
> never log it, never persist it, and send it only to a
> PCI-compliant endpoint.

## Configs

| Config                            | Themeable?                    | Purpose                                                                                    |
| --------------------------------- | ----------------------------- | ------------------------------------------------------------------------------------------ |
| `TextFieldStyle`                  | ✅ via `GlobalTextFieldTheme` | colors, radius, height, padding, blur, border, status colors                               |
| `TextFieldBehavior`               | ✗ caller-only                 | keyboard, formatters, mask, RTL, maxLines, debounce                                        |
| `TextFieldValidation`             | ✗                             | mode, validator, requirements, strength bar                                                |
| `TextFieldFeatures`               | ✗                             | suggestions, chips, voice, undo/redo, counters, animations, clear, success, loading        |
| `TextFieldSlots`                  | ✗                             | prefix/suffix icon/text/widget, info label                                                 |
| `TextFieldCallbacks`              | ✗                             | onChanged, onSubmitted, onTap, onTapOutside                                                |
| `TextFieldSizing`                 | ✗                             | box geometry — height/min/max, width/min/max, `fitWidthToContent`, `isDense`/`isCollapsed` |
| `messages` (`List<FieldMessage>`) | ✗                             | status rows below the field — error/success/warning/info, sorted by severity               |

`TextFieldStyle` is the themeable bag (analogue of `GlobalPopupSurfaceStyle`):
every field nullable, with `defaults` + `mergedWith()` + `resolve(context)`.

### Borders (`style.border` → `TextFieldBorderStyle`)

Border strokes are a structured bag: a `base` default plus per-state
overrides. Each state (`enabled` / `focused` / `error` / `focusedError`
/ `disabled`) is a `TextFieldBorderSide { color?, gradient?, width? }`.
Resolution for a state = `base.mergedWith(state)`, so set `base` once and
override only what differs.

```dart
TextFieldStyle(
  border: TextFieldBorderStyle(
    base: TextFieldBorderSide(color: outline, width: 1),
    focused: TextFieldBorderSide(
      gradient: LinearGradient(colors: [blue, purple]), width: 2,
    ),
  ),
)
```

`gradient` overrides `color`. Because `OutlineInputBorder` only accepts a
solid color, gradient strokes (and, when any state is a gradient, all
strokes) are painted by `_TextFieldBorderPainter` over the field; the
`InputDecoration` borders go transparent. The active side is recomputed on
focus via `_onFocusChanged` when `_hasGradientBorder`. The resting
(`enabled`) border stays invisible unless a color/gradient/width was
supplied (`ResolvedBorderSide.paints`).

### Validation semantics

- **Sync gates async.** `validator` runs first; only when it passes does
  the debounced `asyncValidator` fire (suffix spinner while in flight,
  monotonic request id drops stale responses). Async errors surface live
  below the field — they can't participate in a synchronous
  `Form.validate()`.
- **Mode → trigger.** `onSubmit` validates on keyboard submit AND always
  on `Form.validate()` (an untouched empty form still fails);
  `onFocusLoss` validates when focus leaves; `onInteraction` / `realTime`
  validate live after the first edit (debounced via `delay`).
- **`deferToParentForm` respects the mode.** Only the live modes hand the
  Form `AutovalidateMode.onUserInteraction`; `onSubmit` / `onFocusLoss`
  fields stay `disabled` — no per-keystroke validation just because a
  Form is above them.
- **An explicit `Form.validate()` ALWAYS validates, in every mode.** The
  live modes (`realTime` / `onInteraction`) hold errors back until first
  interaction, but that gate applies only while the enclosing `Form`
  actually auto-validates. When the Form is `AutovalidateMode.disabled`
  (Flutter's default) the validator is reachable *only* through an
  explicit `Form.validate()`, so the gate is skipped — otherwise a
  required field the user never focused reported valid while empty and
  the form submitted blank. Guard:
  `test/text_field/untouched_required_form_test.dart`.
- **Every error renders in the message column.** ALL validator errors —
  Form fields included — render as an error row (icon + status color)
  below the field, never as Material's plain string. The Form validator
  stays wired and stores its result for the column; Material's duplicate
  string is visually collapsed, so `Form.validate()`, the error border
  and semantics keep working. `errorIcon` / `errorBuilder` customize the
  row.
- **Success + messages share the column.** `features.showSuccess` /
  `successText` render as a success row; caller notes come in via
  `messages: [FieldMessage.info(...), ...]`, stacked sorted
  error → success → warning → info.
- **Rules changed at runtime → `revalidateKey`.** Validator closures are
  recreated every build, so the field can't tell a rebuild from a rule
  change. Encode the rule inputs (`revalidateKey: (allowLandline,
country.code)`); when the key differs, an interacted-with (or
  error-showing) field re-validates immediately instead of waiting for
  the next keystroke.

## Usage recipes

Copy-paste starting points for every feature. All assume
`import '.../shared/module/text_field/text_field.dart';`.

### Standalone vs Form (decide first)

Errors ALWAYS render in the message column (icon + status color) — the
choice only affects what triggers validation:

- **Inside a `Form`** → keep `deferToParentForm: true` (the default).
  `Form.validate()` / the Form's autovalidate drive the validator.
- **No `Form` (search bars, dialogs, settings rows)** →
  `deferToParentForm: false`. Internal triggers (focus loss / submit /
  live) drive it.

### Dual validation (sync format check gates an async server check)

```dart
GlobalTextFormField(
  controller: c, hint: 'you@example.com',
  validation: TextFieldValidation(
    deferToParentForm: false,
    mode: ValidationMode.onInteraction,     // async needs a firing mode —
    validator: Validators.validateEmail,    // it never runs under `none`,
    asyncValidator: (v) async =>            // and only on keyboard submit
        await api.emailTaken(v) ? 'Already registered' : null,  // under `onSubmit`
  ),
  features: const TextFieldFeatures(showSuccess: true), // ✓ row when clean
);
```

Suffix spinner shows while the async check runs. `asyncValidator` is
sync-only-invisible to `Form.validate()` — for async-gated submits check
the field state, not the Form result.

### Rich errors (icon or fully custom widget)

```dart
validation: TextFieldValidation(
  validator: Validators.validateRequired,
  errorIcon: Icons.error_outline,                    // icon + message row
  // OR full control:
  errorBuilder: (ctx, msg) => MyErrorChip(msg),      // wins over errorIcon
),
```

### Status messages (multi-state rows under the field)

```dart
messages: [
  FieldMessage.success('Username is available'),
  FieldMessage.warning('Unusual — double-check'),
  FieldMessage.info('Only visible to you', icon: Icons.lock_outline),
],
```

Rendered sorted error → success → warning → info regardless of list
order; any `FieldMessage.error` also forces the error border.

Row entrance animation (applies to the validator error row too, replays
when a row's text changes; reduced-motion skips to the end):

```dart
features: TextFieldFeatures(
  animations: AnimationsConfig(
    messageAnimation: FieldMessageAnimation.slide, // none / fade (default)
    messageSlideFrom: FieldMessageSlideFrom.start, //   / slide / typed
  ),                                               // start/end are RTL-aware
),
```

`typed` reveals text character-by-character (duration scales with length);
custom `errorBuilder` rows fall back to `fade`.

### Sizing

```dart
sizing: const TextFieldSizing(height: 40),                 // exact (auto-isDense)
sizing: const TextFieldSizing(height: 32, isCollapsed: true), // below the ~48 floor
sizing: const TextFieldSizing(minHeight: 48, maxHeight: 140), // growing multiline
sizing: const TextFieldSizing(                              // hug the text
  fitWidthToContent: true, minWidth: 120, maxWidth: 280),
```

An **external** `SizedBox` cannot shrink the field — tell the field its
height via `sizing.height` instead. `fitWidthToContent` reserves a 40 px
heuristic affordance per occupied prefix/suffix slot.

### Suggestions (four modes, combinable)

```dart
features: TextFieldFeatures(
  suggestions: SuggestionsConfig(
    items: ['apple', 'banana'],            // static → anchored overlay
    async: (q) => api.search(q),           // merged in, debounced 300ms
    recent: recents,                       // deletable rows on top
    onRecentDeleted: (r) {...}, onRecentCleared: () {...},
    inline: true,                          // panel under field instead of overlay
    showInlineCompletion: true,            // ghost text — Tab / → accepts
    completion: (text) => ...,             // DYNAMIC ghost derived from the
    onSelected: (s) {...},                 //   text (e.g. email domains) —
                                           //   overrides list-based matching
  ),
),
```

Overlay keyboard nav is built in for every suggestion field: ↑/↓ move the
highlight, Enter picks it, Esc closes. Tapping inside the overlay never
drops field focus (`_isInteractingWithOverlay` guard).

### Chips (picked suggestions become tags)

```dart
features: TextFieldFeatures(
  suggestions: SuggestionsConfig(items: tags),
  chips: ChipsConfig(initial: existing, max: 5,
      onChanged: (list) => save(list)),
),
```

### Voice / undo / counters / animations

```dart
features: TextFieldFeatures(
  voice: VoiceInputConfig(adapter: mySpeechAdapter),   // mic suffix; adapter
  enableUndoRedo: true,                                //   injected, no getIt
  counters: CountersConfig(showCharCount: true,        // charCount requires
      showWordCount: true),                            //   behavior.maxLength
  animations: AnimationsConfig(shakeOnError: true, floatingLabel: true),
  showClearButton: true,
),
```

### Slots

```dart
slots: TextFieldSlots(
  prefixIcon: Padding(                       // slots size to content now —
    padding: EdgeInsetsDirectional.only(     // pad bare icons yourself or
        start: 12, end: 8),                  // they hug the border
    child: Icon(Icons.person_outline),
  ),
  suffix: TextFieldSuffix.icon(Icons.close, onTap: c.clear), // or .loading /
  prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48), // .asset /
  infoLabel: 'Why we ask', onInfoLabelTap: showSheet,        // .widget
),
```

### Behavior extras

`inputMask: '## ### ####'` (`#` = digit), `trimOnSubmit`,
`onChangedDelay` (debounce), `enablePaste/enableCopy: false`,
`unfocusOnScroll` (legacy any-tap-outside dismiss),
`autoDetectDirection: false` for LTR-only content (emails, numbers, URLs),
`autofillHints: [AutofillHints.email]` for platform autofill — the
`AutofillGroup` wrapper belongs around a COMPOSITE (login, card, address),
never per-field; the wrapper-layer `*Form` widgets already carry it.

## Caller gotchas

- **Bare prefix icons hug the border** — slots default to size-to-content
  (no Material 48×48 box). Wrap in directional padding (wrappers already
  do) or pass explicit `prefixIconConstraints` for a fixed tap target.
- **Interactive prefix/suffix widgets + a long scroll → use a `ListView`,
  not `SingleChildScrollView` + `Column`.** A tappable slot widget
  (IconButton, toggle, stepper) lives in Material's `InputDecorator`
  prefix/suffix, which tags its semantics; when the field is clipped
  off-screen in a scroll that _doesn't cull_ (SingleChildScrollView), the
  slot's interactive semantics node inverts its rect and Flutter throws
  "Invisible SemanticsNodes should not be added to the tree" every frame.
  A lazy `ListView`/sliver disposes off-screen items, so the node never
  exists (this is why the showcase, full of interactive suffixes, is
  fine). For an affordance that must stay a11y-reachable _while_
  scrolling, render it as a sibling of the field, not a slot — see
  `QuantityField`'s stepper Row.
- **`asyncValidator` needs a firing mode** — dead under
  `ValidationMode.none`; under `onSubmit` it fires only on keyboard
  submit.
- **`counters.showCharCount` requires `behavior.maxLength`.**
- **Height-pinned fields don't shrink slot icons.** `sizing.height` ≤ the
  Material floor flips the `InputDecorator` to compact density, which
  re-themes prefix/suffix icons down to 18 px — the module neutralizes
  this with an `IconTheme.merge` pinning both slots to the ambient size
  (24). Want a genuinely smaller affix icon? Set `size:` on the `Icon`
  itself.
- **`ChipsConfig.initial` reseeds on change** (list-equality compared) —
  pass a stable list, don't rebuild it inline every frame.
- **Swapping `controller` at runtime is supported** (ghost/undo/direction
  re-bind), but prefer stable controllers.
- **`fitWidthToContent` slot affordance is a heuristic** (40 px/slot) —
  verify visually if you combine it with wide custom slot widgets.
- **`hideErrorWhenRequirements`** suppresses the red string while the
  checklist reports failure — `Form.validate()` still fails correctly.

## Pre-built surfaces

The `surfaces/` part-file renders: identifier header (+ info button),
chips wrap, char/word counter row, password strength bar, requirements
checklist, inline suggestions panel, and the composed suffix
(obscure → clear → voice → undo/redo). The anchored suggestions overlay
is rendered by the State via `GlobalPopupController`.

`required: true` appends a red `*` to the identifier header (or to the
hint inside the field when there's no identifier) — visual only; the
rule stays in the validator. Propagated by `SimpleTextField.required`.
`GlobalDropdown(slots: DropdownSlots(prefixIcon: ...))` gives a dropdown
a fixed trigger leading icon (a selected item's own `leading`/flag still
wins).

## Resolved-style invariant

`TextFieldStyle` exposes every themed field as nullable. The State
**materializes once per frame** at the top of `build()`:

```dart
_rs = widget.style.resolve(context);
```

`resolve` stacks `caller > GlobalTextFieldTheme.style > TextFieldStyle.defaults`,
then fills color/radius fallbacks from `context.<group>Colors`. The
returned `ResolvedTextFieldStyle` guarantees every themed field is
non-null; build + surface code reads `_rs.fillColor` etc. directly — no
`?? context...` ladders. Genuinely opt-in fields (`height`,
`contentPadding`, `textColor`, `hintStyle`, `charCountStyle`) stay
nullable on the snapshot.

If you add a themed field: add it to `TextFieldStyle`, `mergedWith`,
`copyWith`, `ResolvedTextFieldStyle`, and `GlobalTextFieldTheme._lerpStyle`.

## Theming

```dart
ThemeData(extensions: [
  GlobalTextFieldTheme(
    style: TextFieldStyle(
      borderRadius: BorderRadius.circular(12),
      fillColor: myFill,
      strengthStrongColor: myGreen,
    ),
  ),
]);
```

`MyGlobalTextFieldTheme.build(tokens:)` in `core/theme/widget_themes/`
binds the active token bucket (corner radius + motion) and is wired into
`theme.dart`'s `extensions:` list. Colors are left null in the factory so
they track the active palette via `context.<group>Colors` at build time.
Per-instance `style:` always wins.

### Defaults — single source

Every hard-coded module constant lives in **`TextFieldDefaults`**
(`models/text_field_defaults.dart`): shape (radius, blur), border widths,
slot constraints, fit-width geometry, message icon size, validation +
suggestion timings. Full resolution order for any value:

1. per-call `style:` / config
2. `GlobalTextFieldTheme` (runtime, app-wide)
3. `TextFieldDefaults` (compile-time floor) — colors excepted: they fall
   back to `context.<group>Colors`, never constants.

Tweak a module default → edit `TextFieldDefaults`. Rebrand at runtime →
theme extension. Never scatter new literals in widget/state code.

## Hard rules (project conventions)

- **Tokens / role-aware colors**: visual colors come from the resolved
  style (`_rs.*`), which is sourced from `context.<group>Colors`. Never
  hard-code palette colors (`Colors.green`) in surface code. `Theme.of`
  is used only for Material framework widgets / `colorScheme.onSurface`
  neutral tints.
- **No `getIt`**: voice is injected via `TextFieldSpeechAdapter` (see
  `data/services/speech_to_text_text_field_adapter.dart`). Surfaces take
  no DI.
- **`Semantics` on interactives**: suggestion + recent rows wrap in
  `Semantics(button:, selected:, label:)`. Suffix actions are
  `IconButton`s (built-in semantics + tooltip).
- **Strings via `Tr.t(key, fallback)`** so they're remote-overridable.

## The caret

`EditableText` blinks only while ALL of these hold: focus, a COLLAPSED
selection, `showCursor`, `TickerMode.of(context)`, and
`!renderEditable.floatingCursorOn`. Typing restarts a blink that is
already running but does not revive one that stopped — so once any
condition knocks the caret out it stays out, and every one of them
leaves the field fully usable. A field taking text with no visible
caret reads as broken even though nothing is.

**The one that actually bit this module** is not a blink problem at all.
Material paints the caret in `errorStyle.color` while a field is
invalid, and this module collapses that style to transparent so the
message column can own the error text — so the caret went transparent
too, and vanished the moment a field became invalid while still taking
input. `cursorErrorColor` outranks `errorStyle.color` and is now set
explicitly; do NOT remove it, and do not un-collapse `errorStyle` as a
"fix". Note that `_hasError` keys off the decoration's `errorText`,
which `TextFormField` injects only for FORM-driven validation — a
standalone field never reaches Material's error state, so any repro
needs a `Form`.

`controller/caret_watchdog.dart` probes for that state after each
keystroke (debug builds only). A keystroke is the exact right moment:
`EditableText` relights the caret on every value change, so a caret
still dark one frame later is genuinely stuck rather than mid-blink —
no polling, no guessing the blink phase.

One BLINK cause is repairable from outside: a
**floating cursor** (long-press drag on the caret, easy to strand with a
trackpad on the Simulator) whose matching `End` never arrives. The
watchdog sends the End the platform did not. The rest — stopped blink
timer, `TickerMode(enabled: false)` ancestor, non-collapsed selection —
live in private `EditableText` state and only get a log line naming
them, capped at three per focus session so a genuinely dark field does
not spam.

Everything it touches is public API: `EditableTextState.renderEditable`,
`RenderEditable.floatingCursorOn` / `.showCursor`, and
`updateFloatingCursor` (the same entry point the iOS text-input channel
uses). Guard: `test/text_field/caret_watchdog_test.dart`.

## Anti-flicker invariants (don't touch)

In `controller/`:

- `_isUndoRedoAction` — blocks an undo/redo write from re-entering the
  undo-capture path in `_handleOnChanged`.
- `_syncing` (`InlineGhostTextController`) — blocks the bidirectional
  source↔ghost mirror from echoing infinitely.
- `_isInteractingWithOverlay` + 150 ms deferred focus-loss — lets a
  tap/scroll inside the suggestions overlay land before the overlay is
  removed; stay-open mode (`overlayOptions.closeOnScroll == false`) keeps
  it open while the page scrolls.
- `_asyncRequestId` monotonic counter — drops stale async-suggestion
  responses that resolve out of order.

## Engines (pure, unit-testable)

The Flutter-independent logic is extracted into standalone classes under
`controller/`, leaving the `part`-file State as the lifecycle owner:

- `undo_redo_stack.dart` — `UndoRedoStack` (record / undo / redo / reset).
- `inline_ghost_controller.dart` — `InlineGhostTextController`
  (ghost-completion `TextEditingController`, bidirectional mirror).
- `suggestion_filter.dart` — `SuggestionFilter` (pure list math: byQuery /
  recents / mergeAsync / completion). The overlay orchestration stays in
  the State.
- `field_validation_controller.dart` — `FieldValidationController`
  (error state, interaction flag, debounce timer, mode→trigger decision,
  `formValidator`, `autovalidateMode`). Also owns the async pipeline:
  sync result gates the debounced `asyncValidator`, with a monotonic
  request id dropping stale responses. Owned by the State, which passes
  live config getters + `requestRebuild` / `triggerShake` callbacks.

## Deferred TODOs

- **Full imperative-controller-as-shell** — every cleanly-separable slice
  (undo, ghost, suggestion-filter, validation) is now its own unit. What
  remains in the State is irreducibly Element-bound: `FocusNode` lifecycle,
  the shake/pulse `AnimationController`s (need `TickerProvider`), and the
  suggestions overlay (needs `BuildContext` + `vsync` + the anti-flicker
  guards). Folding those into a single mega-controller + a separate view
  widget is a large, high-risk rewrite for a declarative field with no
  user-facing gain — left as an explicit non-goal.
- **Tokenize the last surface literals** — durations use `AppDurations`
  and exact-match spacings/radii use `context.spacing` / `context.radii`;
  the few values with no matching token (6, 12, 2 px) stay as intentional
  micro-constants.

`resolve()`'s materialize debug `assert` (themed fields non-null) is in
place — see `ResolvedTextFieldStyle._`. The suggestion-row scaffold is
deduped into `_suggestionRows` (shared by overlay + inline).

## Showcase

`/text_field-showcase` —
`lib/features/showcases/text_field_showcase/`. Mirrors the popup-showcase
gold standard: `views/text_field_showcase_page.dart` composes `DocChapter`
headers + `DocSection.live` entries (10 chapters — quickstart, pre-built
fields, validation, style, slots, behavior, features, theming,
accessibility, recipes), `ShowcaseJumpMenu` wired per chapter. Each demo is a
self-contained widget under `demos/<chapter>/<name>_demo.dart`.

Add a demo:

1. Drop a `<name>_demo.dart` under `demos/<chapter>/`, wrapping the body in
   `// #docregion main` … `// #enddocregion main`.
2. Ensure the chapter dir is in `pubspec.yaml` under `flutter.assets`.
3. Add a `DocSection.live(..., live: const YourDemo(), sourcePath:
'$_demosRoot/<chapter>/<name>_demo.dart')` entry in the page.

The WRAPPER catalog has its own page: `/common-fields-showcase` —
`lib/features/showcases/common_fields_showcase/` (7 chapters: identity/
KYC, auth, banking, date & time, location & vehicle, numbers & misc,
composites). This page's chapter 2 keeps one teaser demo + a link. Add a
wrapper demo there, under `demos/<chapter>/`, mirroring the DocSection
pattern above.

There is ALSO a throwaway GENERAL dev bench at
`lib/features/showcases/playground/` (`/playground` — knob-driven demos
of whatever is currently under construction, any module). It is a
scratch surface — polished demos graduate into their showcase pages;
strip the playground when forking the template into a real app.
