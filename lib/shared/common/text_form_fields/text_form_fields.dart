/// Barrel for all pre-built text form field components. Import from
/// here when a screen needs several fields — saves per-widget
/// imports.
///
/// ```dart
/// import 'package:terracotta/shared/common/text_form_fields/text_form_fields.dart';
/// ```
///
/// Organized by purpose:
///  - `generic/` — reusable wrappers (simple / multiline / search).
///  - `domain/`  — pre-configured for common input shapes (email,
///    password, phone, URL, number, amount, passport, username,
///    names). Each wires `Validators.*` + a sensible keyboard type
///    + a prefix icon by default; everything's overridable.
///
/// ## Canonical text-form-field contract
///
/// Every widget here exposes the same standard surface in addition
/// to its domain fields:
///
/// | prop              | type                         | default          |
/// |-------------------|------------------------------|------------------|
/// | `controller`      | `TextEditingController`      | —                |
/// | `onChanged`       | `void Function(String)?`     | none             |
/// | `onSubmitted`     | `void Function(String)?`     | none             |
/// | `label`           | `String?`                    | per-widget       |
/// | `identifier`      | `String?`                    | none             |
/// | `hint`            | `String`                     | per-widget       |
/// | `enabled`         | `bool`                       | `true`           |
/// | `readOnly`        | `bool`                       | `false`          |
/// | `errorText`       | `String?`                    | none             |
/// | `validator`       | `String? Function(String?)?` | per-widget       |
/// | `focusNode`       | `FocusNode?`                 | none             |
/// | `textInputAction` | `TextInputAction?`           | per-widget       |
/// | `validationMode`  | `ValidationMode`             | `onInteraction`  |
///
/// Domain fields (`createPassword`, `countryCode`, `currencySymbol`,
/// `allowDecimal`, …) on top. `GlobalTextFormField`'s full surface
/// is still available via `shared/module/text_field/` when callers
/// need flags outside this contract.
library;

// Contract types callers need when configuring the wrappers — keeps a
// barrel import self-sufficient (the `sizing:` / `style:` / `messages:`
// params every wrapper exposes need these types).
export '../../module/text_field/input_formatters/duration_input_formatter.dart'
    show DurationFormat;
export '../../module/text_field/models/text_field_enums.dart'
    show ValidationMode;
export '../../module/text_field/models/text_field_sizing.dart'
    show TextFieldSizing;

// ─── Domain ──────────────────────────────────────────────────────
export 'domain/address_form.dart';
export 'domain/amount_field.dart';
export 'domain/bank_account_form.dart';
export 'domain/cardholder_name_field.dart';
export 'domain/change_password_form.dart';
export 'domain/color_contrast_info.dart';
export 'domain/color_field.dart';
export 'domain/color_picker_panel.dart';
export 'domain/contact_form.dart';
export 'domain/credit_card_field.dart';
export 'domain/crypto_address_field.dart';
export 'domain/cvv_field.dart';
export 'domain/date_field.dart';
export 'domain/date_range_field.dart';
export 'domain/date_time_field.dart';
export 'domain/duration_field.dart';
export 'domain/email_field.dart';
export 'domain/email_or_phone_field.dart';
export 'domain/iban_field.dart';
export 'domain/ip_host_field.dart';
export 'domain/location_field.dart';
export 'domain/location_picker_sheet.dart';
export 'domain/login_form.dart';
export 'domain/measurement_field.dart';
export 'domain/name_field.dart';
export 'domain/national_id_field.dart';
export 'domain/number_field.dart';
export 'domain/otp_field.dart';
export 'domain/otp_verification_form.dart';
export 'domain/passport_number_field.dart';
export 'domain/password_field.dart';
export 'domain/payment_card_form.dart';
export 'domain/percent_field.dart';
export 'domain/phone_number_field.dart';
export 'domain/plate_number_field.dart';
export 'domain/promo_code_field.dart';
export 'domain/quantity_field.dart';
export 'domain/registration_form.dart';
export 'domain/segmented_color_field.dart';
export 'domain/stepper_style.dart';
export 'domain/swift_bic_field.dart';
export 'domain/tags_field.dart';
export 'domain/time_field.dart';
export 'domain/time_range_field.dart';
export 'domain/url_field.dart';
export 'domain/username_field.dart';
export 'domain/vin_field.dart';
// ─── Generic ─────────────────────────────────────────────────────
export 'generic/multiline_text_field.dart';
export 'generic/search_text_field.dart';
export 'generic/simple_text_field.dart';
// ─── Layout ──────────────────────────────────────────────────────
export 'responsive_field_row.dart';
