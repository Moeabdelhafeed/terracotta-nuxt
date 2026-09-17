import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;

import '../../../../core/a11y/semantics_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/date_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/sheet/global_sheet.dart';
import '../../../module/text_field/global_text_field.dart';

export '../../../../core/utils/hijri_date.dart' show HijriDate;
export '../../../module/text_field/input_formatters/date_input_formatter.dart'
    show DateDigitOrder;

/// How [DateField]'s calendar suffix presents the picker.
///
/// Both go through `date_time_picker/` — the app's own module — not
/// through Material's `showDatePicker` and `CalendarDatePicker`. Those
/// could only be made to match the app through a `Theme` wrapper, and
/// even then not their icons, their layout or their entry-mode toggle.
enum DateFieldCalendar {
  /// `PickerDialogs.date` — a modal (default).
  dialog,

  /// `GlobalDateTimePicker.calendar` inside a `GlobalBottomSheet` —
  /// one-handed mobile pick, side-sheet on wide screens.
  sheet,
}

/// What shape of date the field collects — set by the named constructors.
enum _DateVariant { plain, dob, expiry, past, cardExpiry }

/// The parsed value a [DateField] emits on every change — the [DateTime]
/// (null while empty / incomplete / impossible), the raw text, and the
/// sync-validity snapshot. Matches the `Money` / `PhoneNumber` pattern.
@immutable
class DateValue {
  const DateValue({
    required this.date,
    required this.raw,
    required this.isValid,
  });

  /// Midnight-local of the typed date, or null while it isn't one.
  final DateTime? date;

  /// The exact field text (`'14/05/2001'`).
  final String raw;

  /// Passes the field's sync validator.
  final bool isValid;

  /// Partial-order note: under [DateDigitOrder.my] the date is the LAST
  /// day of the typed month (expiry semantics); under
  /// [DateDigitOrder.dm] the year is the leap sentinel 2000 — read only
  /// day/month from it.
  ///
  /// Whole years between [date] and [reference] (birthday math, not
  /// day-count division). Null while [date] is.
  int? ageAt(DateTime reference) {
    final d = date;
    if (d == null) return null;
    var years = reference.year - d.year;
    if (reference.month < d.month ||
        (reference.month == d.month && reference.day < d.day)) {
      years--;
    }
    return years;
  }

  /// [ageAt] today — the age a DOB entry represents right now.
  int? get age => ageAt(DateTime.now());

  /// Civil (tabular) Hijri equivalent — see [HijriDate] for the ±1-day
  /// caveat vs sighting calendars. Null while [date] is.
  HijriDate? get hijri => date == null ? null : HijriDate.fromGregorian(date!);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateValue &&
          other.date == date &&
          other.raw == raw &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(date, raw, isValid);

  @override
  String toString() => 'DateValue($raw → $date, valid: $isValid)';
}

/// Numeric date input — masked typing (`14/05/2001`, auto-separators,
/// zero-padding, impossible segments blocked at the keystroke, Eastern-
/// Arabic keyboards normalized — see [DateInputFormatter]) plus:
///
/// * **Locale digit order** — [order] null resolves DD/MM vs MM/DD vs
///   YYYY/MM from the active locale's `yMd` pattern; hint + template
///   follow.
/// * **Template ghost** — the remaining pattern renders as ghost text
///   while typing (`14/0` → ghost `M/YYYY`).
/// * **Calendar suffix** — [DateFieldCalendar.dialog] or `.sheet`,
///   clamped to the field's bounds and day rules; picking writes the
///   formatted text.
/// * **Smart paste** — `2001-05-14` / `5/14/2001` / `١٤/٥/٢٠٠١` re-order
///   into the field's segments when unambiguous.
/// * **2-digit years** — `14/5/26` expands on focus loss (sliding
///   window: up to 10 years ahead → 20xx, else 19xx). Applies to paste
///   too. [expandTwoDigitYears].
/// * **↑/↓ stepping** — arrows adjust the segment under the caret
///   (day / month / year), announced to screen readers.
///   [stepOnArrows].
/// * **Day rules** — [allowedWeekdays] / [disabledDate] fail validation
///   AND grey the days out in the calendar; [minDaysAhead] /
///   [maxDaysAhead] for notice/horizon windows.
/// * **Cross-field** — [mustBeAfter] / [mustBeOnOrAfter] /
///   [mustBeBefore] / [mustBeOnOrBefore] validate against another
///   [DateField]'s controller and re-check when it changes.
/// * **Hijri companion row** ([showHijri]) — the typed date as a civil
///   Hijri info row (`٢٨ رجب ١٤٤٥ هـ`).
/// * **Two-tier errors** — incomplete entry ("use DD/MM/YYYY") vs a
///   complete-but-impossible date ("doesn't exist").
/// * **[DateValue] emit** via [onDateChanged]; [onCompleted] fires once
///   when a full VALID date lands (chain focus there).
///
/// Presets: [DateField.dob] (age window, birthday autofill, age info
/// row), [DateField.expiry] (document expiry — today onward, optional
/// "valid for N more months" rule), [DateField.past] (no future dates).
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.controller,
    this.onDateChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showCalendarButton = true,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.showHijri = false,
    this.calendar = DateFieldCalendar.dialog,
    this.order,
    this.required = false,
    this.expandTwoDigitYears = true,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.minDate,
    this.maxDate,
    this.minDaysAhead,
    this.maxDaysAhead,
    this.allowedWeekdays,
    this.disabledDate,
    this.mustBeAfter,
    this.mustBeOnOrAfter,
    this.mustBeBefore,
    this.mustBeOnOrBefore,
    this.initialCalendarDate,
    this.applyDate,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
  }) : _variant = _DateVariant.plain,
       minAge = null,
       maxAge = null,
       showAgeInfo = false,
       minMonthsAhead = null,
       allowToday = true;

  /// Date-of-birth preset: no future dates, [minAge]/[maxAge] window
  /// ("Must be at least 18 years old"), `AutofillHints.birthday`, a live
  /// age info row ([showAgeInfo]), and the calendar opens on the
  /// youngest allowed year instead of today.
  const DateField.dob({
    super.key,
    required this.controller,
    this.onDateChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showCalendarButton = true,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.showHijri = false,
    this.showAgeInfo = true,
    this.calendar = DateFieldCalendar.dialog,
    this.order,
    this.required = true,
    this.expandTwoDigitYears = true,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.minAge = 0,
    this.maxAge = 120,
    this.applyDate,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints = const [AutofillHints.birthday],
  }) : _variant = _DateVariant.dob,
       minDate = null,
       maxDate = null,
       minDaysAhead = null,
       maxDaysAhead = null,
       allowedWeekdays = null,
       disabledDate = null,
       mustBeAfter = null,
       mustBeOnOrAfter = null,
       mustBeBefore = null,
       mustBeOnOrBefore = null,
       initialCalendarDate = null,
       minMonthsAhead = null,
       allowToday = true,
       assert(
         minAge != null && maxAge != null && minAge >= 0 && maxAge >= minAge,
         'Ages must satisfy 0 <= minAge <= maxAge.',
       );

  /// Document-expiry preset (passport / ID / license): today onward,
  /// with an optional "must stay valid for [minMonthsAhead] more months"
  /// rule (visa-style 6-month requirements). The calendar starts at the
  /// earliest acceptable day.
  const DateField.expiry({
    super.key,
    required this.controller,
    this.onDateChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showCalendarButton = true,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.showHijri = false,
    this.calendar = DateFieldCalendar.dialog,
    this.order,
    this.required = true,
    this.expandTwoDigitYears = true,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.minMonthsAhead = 0,
    this.maxDate,
    this.applyDate,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
  }) : _variant = _DateVariant.expiry,
       minAge = null,
       maxAge = null,
       showAgeInfo = false,
       minDate = null,
       minDaysAhead = null,
       maxDaysAhead = null,
       allowedWeekdays = null,
       disabledDate = null,
       mustBeAfter = null,
       mustBeOnOrAfter = null,
       mustBeBefore = null,
       mustBeOnOrBefore = null,
       initialCalendarDate = null,
       allowToday = true,
       assert(minMonthsAhead != null && minMonthsAhead >= 0);

  /// Past-only preset (employment start, incident date): today (or
  /// yesterday with `allowToday: false`) is the ceiling; [minDate]
  /// optionally floors it.
  const DateField.past({
    super.key,
    required this.controller,
    this.onDateChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showCalendarButton = true,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.showHijri = false,
    this.calendar = DateFieldCalendar.dialog,
    this.order,
    this.required = false,
    this.expandTwoDigitYears = true,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.allowToday = true,
    this.minDate,
    this.applyDate,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
  }) : _variant = _DateVariant.past,
       minAge = null,
       maxAge = null,
       showAgeInfo = false,
       minMonthsAhead = null,
       maxDate = null,
       minDaysAhead = null,
       maxDaysAhead = null,
       allowedWeekdays = null,
       disabledDate = null,
       mustBeAfter = null,
       mustBeOnOrAfter = null,
       mustBeBefore = null,
       mustBeOnOrBefore = null,
       initialCalendarDate = null;

  /// Card-expiry preset — `MM/YY` mask ([DateDigitOrder.my]), the card
  /// validator ("expired" / "must be MM/YY"), `creditCardExpirationDate`
  /// autofill and no calendar (partial dates don't have one). Emits the
  /// LAST day of the typed month via [onDateChanged] / [onCompleted] —
  /// what "valid thru" means. Replaces the old `ExpiryDateField`.
  const DateField.cardExpiry({
    super.key,
    required this.controller,
    this.onDateChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.applyDate,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints = const [AutofillHints.creditCardExpirationDate],
  }) : _variant = _DateVariant.cardExpiry,
       order = DateDigitOrder.my,
       required = true,
       calendar = DateFieldCalendar.dialog,
       showCalendarButton = false,
       showHijri = false,
       showAgeInfo = false,
       expandTwoDigitYears = false,
       minAge = null,
       maxAge = null,
       minMonthsAhead = null,
       allowToday = true,
       minDate = null,
       maxDate = null,
       minDaysAhead = null,
       maxDaysAhead = null,
       allowedWeekdays = null,
       disabledDate = null,
       mustBeAfter = null,
       mustBeOnOrAfter = null,
       mustBeBefore = null,
       mustBeOnOrBefore = null,
       initialCalendarDate = null;

  final _DateVariant _variant;

  final TextEditingController controller;

  /// Parsed value on every change (typing, paste, calendar pick,
  /// stepping). See [DateValue].
  final ValueChanged<DateValue>? onDateChanged;

  /// Fires ONCE each time the text becomes a complete date that passes
  /// the sync validator — chain focus to the next field here.
  final ValueChanged<DateTime>? onCompleted;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → the order's template (`DD/MM/YYYY`).
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → the built-in chain (required → two-tier
  /// format → variant window → bounds → day rules → cross-field).
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  final bool showPrefixIcon;

  /// Calendar suffix button — see [calendar] for the presentation. A
  /// custom [suffix] wins.
  final bool showCalendarButton;

  /// Ghost-complete the remaining pattern while typing (`14/0` → ghost
  /// `M/YYYY`).
  final bool showTemplateGhost;

  /// Module clear (✕) button while the field has text.
  final bool showClearButton;

  /// Info row with the typed date on the civil Hijri calendar
  /// (`٢٨ رجب ١٤٤٥ هـ`). ±1 day vs sighting-based calendars — see
  /// [HijriDate].
  final bool showHijri;

  /// [DateField.dob] only: live "24 years old" info row while a valid
  /// date is typed.
  final bool showAgeInfo;

  /// Dialog (default) or bottom-sheet calendar.
  final DateFieldCalendar calendar;

  /// Digit order. Null → from the active locale (`en_US` → MM/DD, most
  /// others DD/MM).
  final DateDigitOrder? order;

  /// Empty input fails validation.
  final bool required;

  /// Expand a 2-digit year on focus loss (`14/5/26` → `14/05/2026`) —
  /// sliding window: up to 10 years ahead reads as 20xx, else 19xx.
  final bool expandTwoDigitYears;

  /// ↑/↓ adjust the segment under the caret (day/month/year); an empty
  /// field seeds today. Hardware keyboards only.
  final bool stepOnArrows;

  /// Light haptic tick per ↑/↓ step.
  final bool enableHaptic;

  /// Inclusive bounds — localized "on or after/before" errors, clamped
  /// onto the calendar. (Variant presets compute their own window.)
  final DateTime? minDate;
  final DateTime? maxDate;

  /// Notice / horizon window in days from today (booking rules:
  /// "at least 2 days ahead", "within 90 days").
  final int? minDaysAhead;
  final int? maxDaysAhead;

  /// Allowed `DateTime.weekday` values (1 = Monday … 7 = Sunday) — e.g.
  /// `{1, 2, 3, 4, 6}` for a clinic closed Fri+Sun. Others fail
  /// validation and grey out in the calendar.
  final Set<int>? allowedWeekdays;

  /// Blackout predicate — return true for dates that can't be chosen
  /// (holidays, fully-booked days). Also greys them in the calendar.
  /// NOTE: closure changes can't be detected — pair a data change with a
  /// state rebuild that swaps another `revalidateKey` input if needed.
  final bool Function(DateTime date)? disabledDate;

  /// Cross-field rules against another [DateField]'s controller (parsed
  /// with THIS field's [order]); the field re-validates when the linked
  /// text changes. `mustBeAfter` is strict (checkout > check-in);
  /// `mustBeOnOrAfter` inclusive. Mirrors for the other direction.
  final TextEditingController? mustBeAfter;
  final TextEditingController? mustBeOnOrAfter;
  final TextEditingController? mustBeBefore;
  final TextEditingController? mustBeOnOrBefore;

  /// Where the calendar opens while the field is empty. Null → today
  /// (clamped), or the variant's natural edge (dob: youngest allowed;
  /// expiry: earliest acceptable).
  final DateTime? initialCalendarDate;

  /// [DateField.dob] only: inclusive age window in whole years.
  final int? minAge;
  final int? maxAge;

  /// [DateField.expiry] only: the document must remain valid for at
  /// least this many months from today.
  final int? minMonthsAhead;

  /// [DateField.past] only: whether today itself is acceptable.
  final bool allowToday;

  /// Imperative write channel — push a [DateTime] through a
  /// `ValueNotifier` and the field applies it correctly (formatted into
  /// the active digit order, emitted). Nulls are ignored; to re-apply
  /// the same value, set null first.
  final ValueListenable<DateTime?>? applyDate;

  /// Trailing slot — wins over the calendar button.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill. `[AutofillHints.birthday]` in [DateField.dob],
  /// null otherwise.
  final List<String>? autofillHints;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  static const _separator = '/';

  /// Digit runs of a pasted date (`2001-05-14`, `١٤/٥/٢٠٠١`).
  static final _pastedDate = RegExp(
    r'^\s*(\d{1,4})[/\-. ](\d{1,4})[/\-. ](\d{1,4})\s*$',
  );

  FocusNode? _internalNode;

  /// Last full-valid text [DateField.onCompleted] fired for.
  String? _completedFor;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  /// Order the current text was FORMATTED under — locale switches can
  /// flip the resolved order; the text must be re-expressed, not
  /// re-read (02/22/2027 typed in mdy is month-22 to a dmy reader).
  DateDigitOrder? _appliedOrder;

  /// Bumped after an order-switch rewrite. The switch itself already
  /// re-validated (mid-build, via `revalidateKey`) — feeding this
  /// counter into `revalidateKey` forces one more pass once the
  /// REWRITTEN text is actually in the controller.
  int _rewriteGeneration = 0;

  /// Rewrite computed during the order switch but not yet applied (it
  /// lands post-frame). While set, validation judges THIS text instead
  /// of the controller's — otherwise the switch frame validates the old
  /// notation under the new order and flashes "doesn't exist" for one
  /// frame.
  String? _pendingRewrite;

  bool get _needsTextListener =>
      widget.showHijri ||
      (widget._variant == _DateVariant.dob && widget.showAgeInfo);

  @override
  void initState() {
    super.initState();
    _node
      ..addListener(_onFocusChange)
      ..onKeyEvent = _onKey;
    if (_needsTextListener) widget.controller.addListener(_onText);
    widget.applyDate?.addListener(_onApplyDate);
    _attachLinked(widget);
  }

  /// External [DateTime] pushed through [DateField.applyDate].
  void _onApplyDate() {
    final date = widget.applyDate?.value;
    if (date == null || !mounted) return;
    _applyPicked(date);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register the locale dependency so a language switch reaches this
    // state even though the order itself is read from `Intl`.
    Localizations.maybeLocaleOf(context);
    _syncOrder();
  }

  void _syncOrder() {
    final order = _order;
    final previous = _appliedOrder;
    _appliedOrder = order;
    if (previous == null || previous == order) return;
    final text = widget.controller.text;
    if (text.isEmpty) return;
    // Re-express the typed date in the new segment order.
    final parsed = _parseWith(previous, text);
    if (parsed == null) return;
    final rewritten = _formatWith(order, parsed);
    if (rewritten == text) return;
    // This runs from didChangeDependencies — mid-build. Writing the
    // controller here fires onDateChanged into the caller, whose
    // setState would throw "called during build". Land it post-frame;
    // until then `_pendingRewrite` stands in for validation.
    _pendingRewrite = rewritten;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pendingRewrite = null;
      if (widget.controller.text != text) return; // user got there first
      _applyText(rewritten);
      setState(() => _rewriteGeneration++);
    });
  }

  @override
  void didUpdateWidget(covariant DateField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onText);
      if (_needsTextListener) widget.controller.addListener(_onText);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _internalNode)
        ?..removeListener(_onFocusChange)
        ..onKeyEvent = null;
      _node
        ..addListener(_onFocusChange)
        ..onKeyEvent = _onKey;
    }
    if (old.applyDate != widget.applyDate) {
      old.applyDate?.removeListener(_onApplyDate);
      widget.applyDate?.addListener(_onApplyDate);
    }
    _detachLinked(old);
    _attachLinked(widget);
    if (old.order != widget.order) _syncOrder();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    widget.applyDate?.removeListener(_onApplyDate);
    _detachLinked(widget);
    _node.removeListener(_onFocusChange);
    if (widget.focusNode != null) widget.focusNode!.onKeyEvent = null;
    _internalNode?.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  // ── linked-controller re-validation ──────────────────────────────
  Iterable<TextEditingController> _linkedOf(DateField w) => [
    w.mustBeAfter,
    w.mustBeOnOrAfter,
    w.mustBeBefore,
    w.mustBeOnOrBefore,
  ].whereType<TextEditingController>();

  void _attachLinked(DateField w) {
    for (final c in _linkedOf(w)) {
      c.addListener(_onLinkedText);
    }
  }

  void _detachLinked(DateField w) {
    for (final c in _linkedOf(w)) {
      c.removeListener(_onLinkedText);
    }
  }

  /// The other side of a cross-field rule changed — rebuild so
  /// `revalidateKey` picks it up and re-checks an interacted field,
  /// and re-emit so consumers get the fresh validity.
  void _onLinkedText() {
    if (!mounted) return;
    setState(() {});
    _emit();
  }

  // ── order / template ──────────────────────────────────────────────
  DateDigitOrder get _order => widget.order ?? _localeOrder();

  /// d/M/y positions from the locale's own short-date pattern.
  DateDigitOrder _localeOrder() {
    final pattern = DateFormat.yMd(Intl.getCurrentLocale()).pattern ?? 'd/M/y';
    final d = pattern.indexOf('d');
    final m = pattern.indexOf('M');
    final y = pattern.indexOf('y');
    if (y < m && m < d) return DateDigitOrder.ymd;
    if (m < d) return DateDigitOrder.mdy;
    return DateDigitOrder.dmy;
  }

  String get _template => _order.template(_separator);

  // ── parse / format ────────────────────────────────────────────────
  /// Strict parse of [text] against [order] — complete, numeric, and a
  /// REAL calendar date (Feb 30 → null). Partial orders fill the gap:
  /// `my` → LAST day of the month (expiry semantics), `dm` → leap
  /// sentinel year 2000 (so 29/02 stays valid).
  DateTime? _parseWith(DateDigitOrder order, String text) {
    final parts = text.split(_separator);
    final segs = order.segments;
    if (parts.length != segs.length) return null;
    int? day, month, year;
    for (var i = 0; i < segs.length; i++) {
      if (parts[i].length != segs[i].length) return null;
      final v = int.tryParse(parts[i]);
      if (v == null) return null;
      switch (segs[i]) {
        case DateSegmentKind.day:
          day = v;
        case DateSegmentKind.month:
          month = v;
        case DateSegmentKind.year:
          year = v;
        case DateSegmentKind.year2:
          year = 2000 + v;
      }
    }
    if (month == null || month < 1 || month > 12) return null;
    final y = year ?? 2000; // dm: leap sentinel
    if (day == null) return DateTime(y, month + 1, 0); // my: end of month
    final dt = DateTime(y, month, day);
    // DateTime normalizes overflow (31/02 → 02/03) — reject that.
    if (dt.year != y || dt.month != month || dt.day != day) return null;
    return dt;
  }

  DateTime? _parse(String text) => _parseWith(_order, text);

  String _formatWith(DateDigitOrder order, DateTime d) {
    String seg(DateSegmentKind kind) => switch (kind) {
      DateSegmentKind.day => d.day.toString().padLeft(2, '0'),
      DateSegmentKind.month => d.month.toString().padLeft(2, '0'),
      DateSegmentKind.year => d.year.toString().padLeft(4, '0'),
      DateSegmentKind.year2 => (d.year % 100).toString().padLeft(2, '0'),
    };
    return order.segments.map(seg).join(_separator);
  }

  String _format(DateTime d) => _formatWith(_order, d);

  /// Localized hint — pattern words per segment (`DD/MM/YYYY`,
  /// `يوم/شهر/سنة`). The GHOST keeps the structural Latin template:
  /// RTL-strong placeholder glyphs inside the LTR-pinned editor would
  /// get bidi-reordered mid-word.
  String get _hintText => _order.segments
      .map(
        (s) => switch (s) {
          DateSegmentKind.day => DateFieldStrings.dayWord,
          DateSegmentKind.month => DateFieldStrings.monthWord,
          DateSegmentKind.year => DateFieldStrings.yearWord,
          DateSegmentKind.year2 => DateFieldStrings.year2Word,
        },
      )
      .join(_separator);

  /// Bound formatted for an error message / a11y (locale short date).
  String _display(DateTime d) =>
      DateFormat.yMd(Intl.getCurrentLocale()).format(d);

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _today => _dateOnly(DateTime.now());

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ── bounds / variant window ───────────────────────────────────────
  /// Expiry floor: today pushed [DateField.minMonthsAhead] months out.
  DateTime get _expiryFloor {
    final t = _today;
    final months = widget.minMonthsAhead ?? 0;
    final m = t.month + months;
    return DateTime(
      t.year,
      m,
      t.day.clamp(1, _daysInMonth(t.year + (m - 1) ~/ 12, (m - 1) % 12 + 1)),
    );
  }

  /// Calendar bounds for the active variant + day-window rules +
  /// cross-field floors/ceilings.
  ({DateTime first, DateTime last}) get _bounds {
    final t = _today;
    var (first, last) = switch (widget._variant) {
      _DateVariant.dob => (
        DateTime(t.year - widget.maxAge! - 1, t.month, t.day),
        DateTime(t.year - widget.minAge!, t.month, t.day),
      ),
      _DateVariant.expiry => (
        _expiryFloor,
        widget.maxDate ?? DateTime(2100, 12, 31),
      ),
      _DateVariant.past => (
        widget.minDate ?? DateTime(1900),
        widget.allowToday ? t : t.subtract(const Duration(days: 1)),
      ),
      // Partial order — no calendar; wide window keeps the math sane.
      _DateVariant.cardExpiry => (
        _today,
        DateTime(2100, 12, 31),
      ),
      _DateVariant.plain => (
        widget.minDate ?? DateTime(1900),
        widget.maxDate ?? DateTime(2100, 12, 31),
      ),
    };
    if (widget.minDaysAhead != null) {
      final floor = t.add(Duration(days: widget.minDaysAhead!));
      if (floor.isAfter(first)) first = floor;
    }
    if (widget.maxDaysAhead != null) {
      final ceil = t.add(Duration(days: widget.maxDaysAhead!));
      if (ceil.isBefore(last)) last = ceil;
    }
    final after = _linkedDate(widget.mustBeAfter);
    if (after != null) {
      final floor = after.add(const Duration(days: 1));
      if (floor.isAfter(first)) first = floor;
    }
    final onOrAfter = _linkedDate(widget.mustBeOnOrAfter);
    if (onOrAfter != null && onOrAfter.isAfter(first)) first = onOrAfter;
    final before = _linkedDate(widget.mustBeBefore);
    if (before != null) {
      final ceil = before.subtract(const Duration(days: 1));
      if (ceil.isBefore(last)) last = ceil;
    }
    final onOrBefore = _linkedDate(widget.mustBeOnOrBefore);
    if (onOrBefore != null && onOrBefore.isBefore(last)) last = onOrBefore;
    // A hostile combination can cross — keep the picker constructible.
    if (last.isBefore(first)) last = first;
    return (first: first, last: last);
  }

  DateTime? _linkedDate(TextEditingController? c) =>
      c == null ? null : _parse(c.text);

  // ── validation ────────────────────────────────────────────────────
  /// Weekday / blackout predicate shared by the validator AND the
  /// calendar, so typing and picking agree.
  bool _dayAllowed(DateTime d) {
    final weekdays = widget.allowedWeekdays;
    if (weekdays != null && !weekdays.contains(d.weekday)) return false;
    if (widget.disabledDate?.call(d) ?? false) return false;
    return true;
  }

  bool get _hasDayPredicate =>
      widget.allowedWeekdays != null || widget.disabledDate != null;

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      if (!widget.required) return null;
      return widget._variant == _DateVariant.cardExpiry
          ? ValidatorStrings.cardExpiryCannotBeEmpty
          : ValidatorStrings.dateCannotBeEmpty;
    }
    // Card expiry speaks card language and delegates the month/expired
    // rules to the shared card validator (MM/YY text).
    if (widget._variant == _DateVariant.cardExpiry) {
      if (text.length < _template.length) {
        return ValidatorStrings.cardExpiryMustBeMmYy;
      }
      return Validators.validateCardExpiry(text);
    }
    // Two-tier: still typing vs a complete date that doesn't exist.
    if (text.length < _template.length) {
      return DateFieldStrings.incomplete(_template);
    }
    final date = _parse(text);
    if (date == null) {
      return DateFieldStrings.impossible;
    }
    final t = _today;
    switch (widget._variant) {
      case _DateVariant.dob:
        if (date.isBefore(DateTime(1900))) {
          return ValidatorStrings.dateOfBirthMustBeValid;
        }
        final ageError = Validators.validateAgeFromBirthDate(
          date,
          min: widget.minAge!,
          max: widget.maxAge!,
        );
        if (ageError != null) return ageError;
      case _DateVariant.expiry:
        final floor = _expiryFloor;
        if (date.isBefore(floor)) {
          final months = widget.minMonthsAhead ?? 0;
          return months > 0
              ? DateFieldStrings.expiryMinMonths(months)
              : DateFieldStrings.minDate(_display(t));
        }
      case _DateVariant.past:
        final limit = widget.allowToday
            ? t
            : t.subtract(const Duration(days: 1));
        if (date.isAfter(limit)) {
          return ValidatorStrings.dateMustBeInThePast;
        }
      case _DateVariant.plain:
      case _DateVariant.cardExpiry: // handled above
        break;
    }
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && date.isBefore(_dateOnly(min))) {
      return DateFieldStrings.minDate(_display(min));
    }
    if (max != null && date.isAfter(_dateOnly(max))) {
      return DateFieldStrings.maxDate(_display(max));
    }
    if (widget.minDaysAhead != null &&
        date.isBefore(t.add(Duration(days: widget.minDaysAhead!)))) {
      return DateFieldStrings.minDaysAhead(widget.minDaysAhead!);
    }
    if (widget.maxDaysAhead != null &&
        date.isAfter(t.add(Duration(days: widget.maxDaysAhead!)))) {
      return DateFieldStrings.maxDaysAhead(widget.maxDaysAhead!);
    }
    if (widget.allowedWeekdays != null &&
        !widget.allowedWeekdays!.contains(date.weekday)) {
      return DateFieldStrings.weekdayNotAllowed;
    }
    if (widget.disabledDate?.call(date) ?? false) {
      return DateFieldStrings.dateUnavailable;
    }
    final after = _linkedDate(widget.mustBeAfter);
    if (after != null && !date.isAfter(after)) {
      return DateFieldStrings.mustBeAfter(_display(after));
    }
    final onOrAfter = _linkedDate(widget.mustBeOnOrAfter);
    if (onOrAfter != null && date.isBefore(onOrAfter)) {
      return DateFieldStrings.minDate(_display(onOrAfter));
    }
    final before = _linkedDate(widget.mustBeBefore);
    if (before != null && !date.isBefore(before)) {
      return DateFieldStrings.mustBeBefore(_display(before));
    }
    final onOrBefore = _linkedDate(widget.mustBeOnOrBefore);
    if (onOrBefore != null && date.isAfter(onOrBefore)) {
      return DateFieldStrings.maxDate(_display(onOrBefore));
    }
    return null;
  }

  String? Function(String?) get _effectiveValidator =>
      widget.validator ?? _defaultValidator;

  // ── emit / completion ─────────────────────────────────────────────
  void _emit() {
    final cb = widget.onDateChanged;
    final raw = widget.controller.text;
    cb?.call(
      DateValue(
        date: _parse(raw),
        raw: raw,
        isValid: _effectiveValidator(raw) == null,
      ),
    );
    _maybeComplete(raw);
  }

  void _maybeComplete(String text) {
    if (text.length < _template.length) {
      _completedFor = null;
      return;
    }
    final date = _parse(text);
    if (date == null || _effectiveValidator(text) != null) return;
    if (_completedFor == text) return;
    _completedFor = text;
    widget.onCompleted?.call(date);
  }

  /// Programmatic writes (calendar, stepping, expansion) — the module's
  /// own onChanged doesn't fire for these.
  void _applyText(String text) {
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
    _emit();
  }

  // ── 2-digit year expansion (focus loss) ───────────────────────────
  void _onFocusChange() {
    if (_node.hasFocus) return;
    // Partial orders have no 4-digit year to expand into.
    if (!widget.expandTwoDigitYears || !_order.isFullDate) return;
    final expanded = _expandTwoDigitYear(widget.controller.text);
    if (expanded != null) _applyText(expanded);
  }

  /// `14/05/26` → `14/05/2026` when every other segment is complete.
  /// Sliding window: `now.year + 10` splits 20xx from 19xx.
  String? _expandTwoDigitYear(String text) {
    final segs = _order.segments;
    final parts = text.split(_separator);
    if (parts.length != segs.length) return null;
    String? expandedYear;
    final out = <String>[];
    for (var i = 0; i < segs.length; i++) {
      final part = parts[i];
      if (segs[i] == DateSegmentKind.year && part.length == 2) {
        final yy = int.tryParse(part);
        if (yy == null) return null;
        final pivot = (DateTime.now().year + 10) % 100;
        expandedYear = (yy <= pivot ? 2000 + yy : 1900 + yy).toString();
        out.add(expandedYear);
      } else {
        if (part.length != segs[i].length) return null;
        out.add(part);
      }
    }
    return expandedYear == null ? null : out.join(_separator);
  }

  // ── ↑/↓ segment stepping ──────────────────────────────────────────
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.stepOnArrows ||
        !widget.enabled ||
        widget.readOnly ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final dir = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => 1,
      LogicalKeyboardKey.arrowDown => -1,
      _ => 0,
    };
    if (dir == 0) return KeyEventResult.ignored;
    _stepSegment(dir);
    return KeyEventResult.handled;
  }

  void _stepSegment(int dir) {
    final text = widget.controller.text;
    if (text.isEmpty) {
      // Seed with today (clamped into the field's window).
      final (:first, :last) = _bounds;
      var seed = _today;
      if (seed.isBefore(first)) seed = first;
      if (seed.isAfter(last)) seed = last;
      _applyText(_format(seed));
      _announce();
      return;
    }
    final date = _parse(text);
    if (date == null) return; // partial entry — nothing sane to step
    final segs = _order.segments;
    final caret = widget.controller.selection.baseOffset.clamp(0, text.length);
    final segIndex = (text.substring(0, caret).split(_separator).length - 1)
        .clamp(0, segs.length - 1);
    final seg = segs[segIndex];
    final next = switch (seg) {
      DateSegmentKind.day => DateTime(date.year, date.month, date.day + dir),
      DateSegmentKind.month => DateTime(
        date.year,
        date.month + dir,
        date.day.clamp(1, _daysInMonth(date.year, date.month + dir)),
      ),
      DateSegmentKind.year || DateSegmentKind.year2 => DateTime(
        date.year + dir,
        date.month,
        date.day.clamp(1, _daysInMonth(date.year + dir, date.month)),
      ),
    };
    _applyText(_format(next));
    // Keep the caret on the stepped segment (end of it).
    var offset = 0;
    for (var i = 0; i <= segIndex; i++) {
      offset += segs[i].length + (i > 0 ? _separator.length : 0);
    }
    widget.controller.selection = TextSelection.collapsed(offset: offset);
    _announce();
  }

  void _announce() {
    if (widget.enableHaptic) HapticFeedback.selectionClick();
    if (!mounted) return;
    announceForAccessibility(context, widget.controller.text);
  }

  // ── smart paste (other notations → the field's order) ────────────
  /// A paste like `2001-05-14`, `5/14/2001` or `١٤/٥/٢٠٠١` is
  /// re-segmented into this field's order when the parts are
  /// unambiguous: a 4-digit group is the year (2-digit years expand via
  /// the pivot window when [DateField.expandTwoDigitYears]); a group
  /// over 12 is the day; a tie falls back to the field's own day/month
  /// order. Runs BEFORE the mask formatter.
  TextEditingValue _interceptDatePaste(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_order.isFullDate) return newValue; // 3-group paste needs 3 slots
    if (newValue.text.length - oldValue.text.length < 6) return newValue;
    final ascii = DateInputFormatter.normalizeDigits(newValue.text);
    final m = _pastedDate.firstMatch(ascii);
    if (m == null) return newValue;
    final groups = [m.group(1)!, m.group(2)!, m.group(3)!];
    var yearIndex = groups.indexWhere((g) => g.length == 4);
    var year = yearIndex < 0 ? null : int.parse(groups[yearIndex]);
    if (yearIndex < 0 && widget.expandTwoDigitYears) {
      // No 4-digit group — read the year from the FIELD's own position.
      yearIndex = _order.segments.indexOf(DateSegmentKind.year);
      final yy = int.tryParse(groups[yearIndex]);
      if (yy == null || groups[yearIndex].length != 2) return newValue;
      final pivot = (DateTime.now().year + 10) % 100;
      year = yy <= pivot ? 2000 + yy : 1900 + yy;
    }
    if (year == null) return newValue;
    final rest = [...groups]..removeAt(yearIndex);
    final a = int.parse(rest[0]);
    final b = int.parse(rest[1]);
    final int day;
    final int month;
    if (a > 12 && b <= 12) {
      day = a;
      month = b;
    } else if (b > 12 && a <= 12) {
      day = b;
      month = a;
    } else if (a <= 12 && b <= 12) {
      // Ambiguous (5/4) — read it in this field's own order.
      final dayFirst =
          _order.segments.indexOf(DateSegmentKind.day) <
          _order.segments.indexOf(DateSegmentKind.month);
      day = dayFirst ? a : b;
      month = dayFirst ? b : a;
    } else {
      return newValue; // both > 12 — not a date
    }
    if (day > 31 || month > 12 || day == 0 || month == 0) return newValue;
    // Digits in THIS field's segment order; the mask formatter (next in
    // the chain) inserts the separators.
    final digits = _order.segments
        .map(
          (s) => switch (s) {
            DateSegmentKind.day => day.toString().padLeft(2, '0'),
            DateSegmentKind.month => month.toString().padLeft(2, '0'),
            DateSegmentKind.year => year.toString().padLeft(4, '0'),
            // Unreachable — paste is gated to full-date orders.
            DateSegmentKind.year2 => (year! % 100).toString().padLeft(2, '0'),
          },
        )
        .join();
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }

  // ── template ghost ────────────────────────────────────────────────
  /// Remaining pattern once typing starts (`14/0` → `M/YYYY`) — the
  /// formatted text always matches the template's separator positions.
  String? _templateGhost(String text) {
    if (text.isEmpty || text.length >= _template.length) return null;
    return _template.substring(text.length);
  }

  // ── info rows (age / hijri) ───────────────────────────────────────
  FieldMessage? get _ageRow {
    if (widget._variant != _DateVariant.dob || !widget.showAgeInfo) {
      return null;
    }
    final date = _parse(widget.controller.text);
    if (date == null) return null;
    final age = DateValue(date: date, raw: '', isValid: true).age;
    if (age == null || age < 0 || age > 150) return null;
    // Under a year "0 years old" is useless — step down to months, and
    // under a month to days.
    final String text;
    if (age > 0) {
      text = DateFieldStrings.ageYears(age);
    } else {
      final now = DateTime.now();
      final months =
          (now.year - date.year) * 12 +
          now.month -
          date.month -
          (now.day < date.day ? 1 : 0);
      if (months > 0) {
        text = DateFieldStrings.ageMonths(months);
      } else {
        final days = now.difference(date).inDays;
        if (days < 0) return null;
        text = DateFieldStrings.ageDays(days);
      }
    }
    return FieldMessage.info(text, icon: Icons.timelapse);
  }

  FieldMessage? get _hijriRow {
    if (!widget.showHijri || !_order.isFullDate) return null;
    final date = _parse(widget.controller.text);
    if (date == null) return null;
    final h = HijriDate.fromGregorian(date);
    return FieldMessage.info(
      DateFieldStrings.hijri(h.format()),
      icon: Icons.nights_stay_outlined,
    );
  }

  // ── calendar ──────────────────────────────────────────────────────
  /// First day from [seed] (inclusive) that passes the day rules —
  /// pickers assert their initial date is selectable.
  DateTime _firstSelectable(DateTime seed, DateTime first, DateTime last) {
    if (!_hasDayPredicate) return seed;
    for (var d = seed; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      if (_dayAllowed(d)) return d;
    }
    for (
      var d = seed;
      !d.isBefore(first);
      d = d.subtract(const Duration(days: 1))
    ) {
      if (_dayAllowed(d)) return d;
    }
    return seed; // no selectable day at all — let the picker cope
  }

  DateTime get _calendarSeed {
    final (:first, :last) = _bounds;
    DateTime clamp(DateTime d) =>
        d.isBefore(first) ? first : (d.isAfter(last) ? last : d);
    final base =
        _parse(widget.controller.text) ??
        widget.initialCalendarDate ??
        switch (widget._variant) {
          _DateVariant.dob => last, // youngest allowed year
          _DateVariant.expiry => first, // earliest acceptable day
          _ => _today,
        };
    return _firstSelectable(clamp(base), first, last);
  }

  void _applyPicked(DateTime picked) => _applyText(_format(picked));

  Future<void> _openCalendar() async {
    final (:first, :last) = _bounds;
    final predicate = _hasDayPredicate ? _dayAllowed : null;

    switch (widget.calendar) {
      case DateFieldCalendar.dialog:
        final picked = await PickerDialogs.date(
          context,
          initial: _calendarSeed,
          firstDate: first,
          lastDate: last,
          title: DateFieldStrings.pickDate,
          selectableDayPredicate: predicate,
          // The field already types its own masked date; a second
          // keyboard entry inside the dialog would be the same job
          // twice.
          entryMode: PickerEntryMode.calendar,
        );
        if (picked != null && mounted) _applyPicked(picked);
      case DateFieldCalendar.sheet:
        await GlobalBottomSheet.show<void>(
          context: context,
          title: DateFieldStrings.pickDate,
          content: GlobalDateTimePicker.calendar(
            value: _calendarSeed,
            firstDate: first,
            lastDate: last,
            selectableDayPredicate: predicate,
            // The sheet IS the surface; a bordered, shadowed panel
            // inside it would be a frame within a frame.
            style: DateTimePickerStyle.flat,
            onChanged: (d) {
              _applyPicked(d);
              Navigator.of(context).pop();
            },
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ageRow = _ageRow;
    final hijriRow = _hijriRow;
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint ?? _hintText,
      focusNode: _node,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (ageRow != null) ageRow,
        if (hijriRow != null) hijriRow,
      ],
      behavior: TextFieldBehavior(
        // datetime keeps `/` reachable for the pad-on-separator trick.
        keyboardType: TextInputType.datetime,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          TextInputFormatter.withFunction(_interceptDatePaste),
          DateInputFormatter(order: _order, separator: _separator),
        ],
        maxLength: _template.length,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
        // Digit/separator runs bidi-reorder under an RTL locale (segments
        // visually swap as you type) — dates are structurally LTR. The
        // ALIGNMENT still follows the ambient direction (an RTL form
        // keeps its text on the right edge): start/end here resolve
        // against the pinned-LTR editor, so RTL needs `end`.
        textDirection: TextDirection.ltr,
        textAlign: Directionality.of(context) == TextDirection.rtl
            ? TextAlign.end
            : TextAlign.start,
        autofillHints: widget.autofillHints,
      ),
      validation: TextFieldValidation(
        // During an order switch the controller still holds the OLD
        // notation for one frame — validate the pending rewrite instead.
        validator: (v) => _effectiveValidator(_pendingRewrite ?? v),
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // Order (locale flips), windows and linked fields can all change
        // at runtime. Sets/closures are keyed by a stable projection.
        revalidateKey: (
          _order,
          _rewriteGeneration,
          widget.required,
          widget.minDate,
          widget.maxDate,
          widget.minAge,
          widget.maxAge,
          widget.minMonthsAhead,
          widget.allowToday,
          widget.minDaysAhead,
          widget.maxDaysAhead,
          widget.allowedWeekdays?.join(','),
          widget.mustBeAfter?.text,
          widget.mustBeOnOrAfter?.text,
          widget.mustBeBefore?.text,
          widget.mustBeOnOrBefore?.text,
        ),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
        showClearButton: widget.showClearButton,
        suggestions: widget.showTemplateGhost
            ? SuggestionsConfig(
                showInlineCompletion: true,
                completion: _templateGhost,
              )
            : null,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  switch (widget._variant) {
                    _DateVariant.dob => Icons.cake_outlined,
                    _DateVariant.cardExpiry => Icons.credit_card,
                    _ => Icons.event_outlined,
                  },
                  color: context.iconColors.primary,
                ),
              )
            : null,
        // Partial orders (MM/YY, DD/MM) have no single day to pick.
        suffix:
            widget.suffix ??
            (widget.showCalendarButton &&
                    _order.isFullDate &&
                    widget.enabled &&
                    !widget.readOnly
                ? TextFieldSuffix.icon(
                    Icons.calendar_today_outlined,
                    onTap: _openCalendar,
                  )
                : null),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
