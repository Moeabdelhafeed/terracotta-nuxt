/// Barrel for all pre-built dropdown field components. Import from
/// here when a screen needs several — saves per-widget imports.
///
/// ```dart
/// import 'package:terracotta/shared/common/dropdown_fields/dropdown_fields.dart';
/// ```
///
/// Organized by purpose:
///  - `generic/` — reusable wrappers that take an `items` list
///    (simple / searchable / multi / async / grouped).
///  - `domain/`  — pre-populated for common data types (language,
///    country / state / city, nationality, timezone, currency, unit,
///    gender, blood type, marital status, education level, theme,
///    color format, sort presets, duration / recurrence,
///    day / weekday / month / year, hour). Each one picks a generic
///    wrapper under the hood. Several expose a static `itemFor` — the
///    canonical row shared with the embedded pickers inside
///    `text_form_fields/` (phone, national-ID, amount, measurement,
///    color, address) so host and standalone render identically.
///
/// ## Canonical dropdown-field contract
///
/// Every widget here exposes the same standard surface in addition
/// to its domain fields:
///
/// | prop              | type                      | default    |
/// |-------------------|---------------------------|------------|
/// | `value`           | `T?`                      | —          |
/// | `onChanged`       | `ValueChanged<T?>?`       | —          |
/// | `label`           | `String?`                 | none       |
/// | `hint`            | `String`                  | per-widget |
/// | `errorText`       | `String?`                 | none       |
/// | `enabled`         | `bool`                    | `true`     |
/// | `infoLabel`       | `String?`                 | none (searchable-backed fields) |
/// | `onInfoLabelTap`  | `VoidCallback?`           | none (searchable-backed fields) |
/// | `validator`       | `FormFieldValidator<T>?`  | none (form-scoped only) |
///
/// Domain fields (`items`, `groups`, `itemsLoader`, `values`, …)
/// come on top. `GlobalDropdown`'s full surface is still available
/// one level down via `shared/module/drop_down/` when callers need
/// anything outside this contract (chipDisplay flags, custom item
/// builders, selection limits, etc.).
library;

// ─── Module models ───────────────────────────────────────────────
// Consumers need DropdownItem / DropdownGroup / the controller just to
// construct wrapper params — re-export so one import serves a screen.
export '../../module/drop_down/drop_down_models.dart';
// ─── Domain ──────────────────────────────────────────────────────
export 'domain/blood_type_dropdown_field.dart';
export 'domain/city_dropdown_field.dart';
export 'domain/color_format_dropdown_field.dart';
export 'domain/country_code_dropdown_field.dart';
export 'domain/country_dropdown_field.dart';
export 'domain/currency_dropdown_field.dart';
export 'domain/day_dropdown_field.dart';
export 'domain/duration_dropdown_field.dart';
export 'domain/education_level_dropdown_field.dart';
export 'domain/gender_dropdown_field.dart';
export 'domain/hour_dropdown_field.dart';
export 'domain/language_dropdown_field.dart';
export 'domain/marital_status_dropdown_field.dart';
export 'domain/month_dropdown_field.dart';
export 'domain/nationality_dropdown_field.dart';
export 'domain/recurrence_dropdown_field.dart';
export 'domain/sort_dropdown_field.dart';
export 'domain/state_dropdown_field.dart';
export 'domain/theme_mode_dropdown_field.dart';
export 'domain/timezone_dropdown_field.dart';
export 'domain/unit_dropdown_field.dart';
export 'domain/weekday_dropdown_field.dart';
export 'domain/year_dropdown_field.dart';
// ─── Generic ─────────────────────────────────────────────────────
export 'generic/async_dropdown_field.dart';
export 'generic/grouped_dropdown_field.dart';
export 'generic/multi_select_dropdown_field.dart';
export 'generic/searchable_dropdown_field.dart';
export 'generic/simple_dropdown_field.dart';
