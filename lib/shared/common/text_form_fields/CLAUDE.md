# CLAUDE.md — lib/shared/common/text_form_fields

App-owned, purpose-shaped wrappers over the raw
[`GlobalTextFormField`](../../module/text_field/global_text_field.dart)
module. Each wrapper pre-wires keyboard type, formatters, validators,
autofill hints, prefix icon, and localized strings for one input shape —
everything overridable. Screens use THESE; only PRIMITIVE module code composes the raw
`GlobalTextFormField` directly (primitive modules must never import
this directory — one-way dependency). COMPOSITE screen modules
(system_pages, feedback, faq, wizard, …) consume these wrappers like
any screen — see the carve-out in `../../module/CLAUDE.md`.

Module internals (grouped params, validation engine, theming, per-feature
usage recipes) → [`../../module/text_field/CLAUDE.md`](../../module/text_field/CLAUDE.md).

## `OtpField` is the ONLY PIN entry

There used to be a second one: `lib/shared/module/pin_input/`, a
`GlobalPinInput` wrapping `package:pinput`. It has been deleted along
with its showcase, its route and the dependency.

It was a duplicate that was worse on every axis a wrapper is supposed to
help with — a third-party widget's own theming instead of the palette,
its own `HapticFeedbackType` enum that callers had to import
`package:pinput` to name, no `Tr` strings, no `ValidationMode`, no
`GlobalTextFormField` underneath it. `OtpField` already does boxed
cells, `joined` mode, obscuring, SMS autofill, per-cell filtering by
`OtpMode`, paste distribution and the shared message column.

Guard: `test/text_field/otp_is_the_only_pin_test.dart` fails if the
module directory or the dependency comes back.

## Structure

```
text_form_fields.dart      — barrel; import this, not individual files
responsive_field_row.dart  — ResponsiveFieldRow / ResponsiveField layout primitive
generic/                   — shape-agnostic: SimpleTextField, MultilineTextField, SearchTextField
domain/                    — one file per input shape (~45 fields + 8 composite forms)
```

## Wrapper contract

Every field exposes the same standard surface on top of its domain params:
`controller` (required), `onChanged`/`onSubmitted`, `label`/`identifier`/`hint`,
`required`, `enabled`/`readOnly`, `errorText`, `validator`/`asyncValidator`/`asyncDebounce`,
`focusNode`, `textInputAction`, `validationMode`, `deferToParentForm`,
`errorIcon`/`errorBuilder`, `messages`, `showSuccess`/`successText`,
`showPrefixIcon`, `suffix`, `style`, `sizing`, `autofillHints`.

Rules when adding or editing a wrapper:

- **`required` semantics** — default `true` on auth-critical fields
  (email, phone, password, username), `false` elsewhere. `true` shows the
  red `*` on the identifier header, or appended to the hint when there is
  no identifier. `false` means empty-passes-but-nonempty-runs-full-rules —
  the validator must early-return `null` on empty.
- **`deferToParentForm`** — default `true` (a wrapping `Form` drives
  validation). Standalone screens/demos pass `false` so internal triggers
  (focus loss / live / submit) fire. Forgetting this = "why doesn't it
  validate" bug #1.
- **Localization** — every user-facing string via
  `Tr.t('key', S.current.key)`. New strings: add to `lib/l10n/intl_en.arb`
  - `intl_ar.arb`, run `dart run intl_utils:generate`, hot RESTART.
- **Value objects** — fields that parse emit an immutable object alongside
  the raw text (`PhoneNumber`, `NationalId`, `SwiftBic`, `FullName`,
  `LocationValue`, `PaymentCard`, …) via an `onXChanged` callback. `==`/
  `hashCode` overridden; `isValid` snapshot included.
- **Cross-field checks** — link the SIBLING's controller, don't duplicate
  state: `SwiftBicField.mustMatchIban`, `PasswordField.matchController`,
  `NationalIdField.mustMatchBirthDate`.
- **Sizing** — joined-pair fields (phone/national-id pickers, lat|lng) pin
  editors to `kJoinedPairBoxHeight` and use `joinedPairRadii` (RTL-aware).
  Both faces of a swapping field MUST share identical sizing or GlobalKey
  reparenting breaks (see `EmailOrPhoneField`).
- **Prefix icons** — bare icons need
  `EdgeInsetsDirectional.only(start: 12, end: 8)` padding (slots size to
  content).

## Composite contract (the `*Form` widgets)

Composites arrange existing fields; they add NO new validation logic
beyond cross-field checks. Every composite:

- wraps its fields in ONE `AutofillGroup` (never per-field); auth/card
  composites expose `static void finishAutofill()` — call after a
  successful submit so the OS offers to save.
- owns its controllers unless the caller passes them
  (`TextEditingController? xController` + lazy `_ownedX`).
- chains focus field → field via internal `FocusNode`s; keyboard-done on
  the LAST field fires `onSubmit`. Multiline endings (ContactForm) can't —
  gate the caller's button on `data.isValid` instead.
- emits an immutable `XFormData` (with `isValid`) from `onChanged` on
  every keystroke. Validity is computed via `Validators.*` directly —
  optional-shown fields pass when empty (`emailRequired`/`phoneRequired`/
  `bicRequired` knobs).

| Composite             | Shapes                                                                                                                             |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `LoginForm`           | identifier type (email / phone / emailOrPhone / username) × password toggle — covers classic, MENA either-way, magic-link, OTP; `showRememberMe` → localized checkbox riding `LoginFormData.rememberMe` |
| `RegistrationForm`    | `showEmail`/`showPhone` × requiredness × `RegPasswordMode` none/create/createConfirm; asserts ≥1 shown identifier required; `onTermsTap`/`onPrivacyTap` → `ConsentCheckboxField` gating `isValid`, `showMarketingOptIn` opt-in row |
| `ChangePasswordForm`  | current + new (≠ current) + confirm; `requireCurrent: false` = reset-password pair                                                 |
| `OtpVerificationForm` | sent-to line + `OtpField` + resend cooldown button; `errorText`/`success` passthrough                                              |
| `BankAccountForm`     | holder + IBAN + BIC (`mustMatchIban` pre-linked, `bicRequired` knob)                                                               |
| `ContactForm`         | full name + email + optional phone + counted message                                                                               |
| `AddressForm`         | schema-driven per-country lines + subdivision dropdowns + delivery extras (type/recipient/phone/location/notes), reverse geocoding; `showDefaultToggle` → `Address.isDefault` |
| `PaymentCardForm`     | cardholder? + number + expiry + CVV, brand → CVV length; `showSaveCard` → `PaymentCard.saveCard` |

## Catalog (domain/)

- **Identity / KYC**: `EmailField`, `PhoneNumberField` (country dictionary,
  SIM default, smart paste), `EmailOrPhoneField` (morphing login
  identifier), `NameField` (first/last/middle/father/full, script
  restriction), `UsernameField`, `NationalIdField` (`NationalIdSpecs`
  JO/SA/EG/AE/KW + generic), `PassportNumberField`.
- **Auth**: `PasswordField` (login/create/confirm modes, strength,
  breach check, generate, capture protection), `OtpField`.
- **Banking / payment**: `AmountField`, `CreditCardField`, `CvvField`,
  `CardholderNameField`, `IbanField`, `SwiftBicField`, `PromoCodeField`
  (async apply state machine).
- **Date / time**: `DateField` (+ `.cardExpiry`, age row), `TimeField`,
  `DateTimeField`, `DateRangeField`, `TimeRangeField`, `DurationField`
  (masked hh:mm:ss).
  - **Every calendar and clock here is `date_time_picker/`**, never
    Flutter's. `DateField` → `PickerDialogs.date` (dialog) or
    `GlobalDateTimePicker.calendar` (sheet); `TimeField` →
    `PickerDialogs.time`; `DateTimeField` → `PickerDialogs.dateAndTime`,
    ONE dialog where it used to walk a date dialog and then a time one;
    `DateRangeField` grows a shared button onto `PickerDialogs.range`,
    because two independent single-date dialogs are not a range picker.
    Guard: `test/date_time_picker/picker_adoption_test.dart`.
  - **`TimeField.pickerLayout`** replaces `pickerEntryMode`: the
    module's dialog has no keyboard side, because the FIELD is the
    keyboard side and it is already masked. `TimePickerLayout.wheels` or
    `.dial`.
  - **These fields need `BreakpointsProvider` in `MaterialApp.builder`.**
    A dialog goes into the ROOT overlay, which sits inside `builder` but
    ABOVE `home` — a provider under `home` cannot reach it.
  - **`DurationField` → `PickerDialogs.duration`** and
    **`TimeRangeField` → `PickerDialogs.timeRange`** (ONE dialog for both
    ends, behind `showRangeDialog`). Nothing in the app opens a borrowed
    picker any more.
- **Location / vehicle**: `AddressForm` (+ `AddressSchemas` registry in
  `core/constants/`), `LocationField` (joined lat|lng + GPS/map pickers +
  `LocationPickerSheet`), `PlateNumberField` (JO/SA/AE).
- **Numbers / misc**: `NumberField`, `PercentField`, `QuantityField`,
  `MeasurementField` (unit dropdown/steppers), `ColorField` /
  `SegmentedColorField` (+ picker panel, contrast info), `UrlField`,
  `TagsField` (chips + suggestions), `CryptoAddressField`, `VinField`
  (ISO 3779 check digit), `IpHostField`.
- **Support files**: `joined_pair_radii.dart`, `stepper_interactions.dart`,
  `stepper_style.dart`, `color_contrast_info.dart`, `location_picker_sheet.dart`.

## Adding a new field — checklist

1. `domain/<name>_field.dart` — follow the wrapper contract above; value
   object first if it parses.
2. ARB keys (en+ar) → `dart run intl_utils:generate`.
3. Export from `text_form_fields.dart` (alphabetical).
4. Tests in `test/text_field/<name>_field_test.dart` (see conventions
   below).
5. Entry in `../../module/text_field/CLAUDE.md` § Pre-built wrappers.
6. Demo in the Common Fields showcase
   (`lib/features/showcases/common_fields_showcase/demos/<chapter>/` — add
   the dir to `pubspec.yaml` assets if new) and a playground knob bench if
   it has combinations worth exercising.

## Test conventions (test/text_field/)

- Harness: `MaterialApp` + `S.delegate` + `locale: en` +
  `BreakpointsProvider(overrideSize)`; popups need `GlobalPopupScope`.
- `editors()` finder = `TextField && !readOnly` (dropdown/picker triggers
  are readOnly TextFields — excluded).
- NEVER `pumpAndSettle` near country flags / infinite animations — use the
  bounded `settle()` helper (pump + 50ms + 600ms).
- Flush pending timers at test end: focus 150ms → `pump(200ms)`,
  validation debounce → `pump(1s)`.
- Suggestion-overlay rows render as `RichText` (`findRichText: true`);
  `GlobalTextButton` labels match twice (morph layers) — use
  `findsWidgets` / `.first`.
- Valid fixtures: IBAN `JO94CBJO0010000000000131000302` /
  `DE89370400440532013000`, VIN `1HGCM82633A004352` (year 2003), JO phone
  `0791234567` → `+962791234567`.

## `SearchTextField.showSearchIcon`

The in-field magnifier is on by default and off where the surrounding
chrome already says "search" — `SearchAppBar` turns it off, because the
bar IS the affordance and the icon only repeats it while eating width
from the query. Guard: `test/app_bar/global_app_bar_test.dart` covers
both the off (in-bar) and on (standalone) cases.
