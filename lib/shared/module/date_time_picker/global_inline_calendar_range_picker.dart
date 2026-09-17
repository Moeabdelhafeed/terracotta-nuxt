import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../buttons/global_icon_button.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';
import 'picker_calendar_system.dart';
import 'theme/date_time_picker_theme.dart';

/// What a day cell is, handed to a custom [GlobalInlineCalendarRangePicker.dayBuilder].
@immutable
class DayCellInfo {
  const DayCellInfo({
    required this.isSelected,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.isToday,
    required this.isDisabled,
    required this.isOutside,
    required this.markers,
  });

  final bool isSelected;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final bool isToday;
  final bool isDisabled;
  final bool isOutside;
  final List<Color> markers;
}

// ---------------------------------------------------------------------------
// GlobalInlineCalendarRangePicker
// ---------------------------------------------------------------------------

/// A month grid that picks one date or a range.
///
/// The one calendar in this module: the wheel picker's `calendar`
/// surface, both overlay panels and the range picker's inline mode all
/// build this, so a calendar seen in four places is one implementation.
class GlobalInlineCalendarRangePicker extends StatefulWidget {
  const GlobalInlineCalendarRangePicker({
    super.key,
    this.selectedRange,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.additionalDays = 0,
    this.minimumRangeDays,
    this.maximumRangeDays,
    this.previousDaysDisabled,
    this.selection = CalendarSelection.range,
    this.selectedDates = const [],
    this.onDatesChanged,
    this.style,
    this.onRangeValidationError,
    this.startOfWeek = 0,
    this.selectableDayPredicate,
    this.markedDates,
    this.onMonthChanged,
    this.dayBuilder,
    this.clearable = false,
    this.clearText,
    this.semanticLabel,
    this.grain = CalendarGrain.day,
    this.autofocus = false,
  });

  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?>? onChanged;

  /// Defaults to a year either side of today.
  ///
  /// It used to default to TODAY, so the calendar opened unable to show
  /// last month — and the range picker's own "Last 7 days" preset
  /// selected a span every day of which was drawn disabled.
  final DateTime? firstDate;
  final DateTime? lastDate;

  final bool enabled;
  final String? errorText;

  /// Days after the end that are drawn as spoken-for: a hotel's
  /// checkout day, a rental's grace period.
  final int? additionalDays;

  final int? minimumRangeDays;
  final int? maximumRangeDays;

  /// Disable everything more than this many days in the past.
  final int? previousDaysDisabled;

  /// What this calendar collects — one date, a span, or any number of
  /// days.
  final CalendarSelection selection;

  /// The days that are on, in [CalendarSelection.multiple].
  final List<DateTime> selectedDates;

  /// Reports the whole set on every toggle. `multiple` only —
  /// [onChanged] carries the other two.
  final ValueChanged<List<DateTime>>? onDatesChanged;

  /// Whether this calendar collects exactly one date.
  bool get singleSelect => selection == CalendarSelection.single;

  /// Per-call visual overrides. `caller > GlobalDateTimePickerTheme >
  /// DateTimePickerStyle.defaults`.
  final DateTimePickerStyle? style;

  /// Told when a pick is refused by [minimumRangeDays] /
  /// [maximumRangeDays], with a message already in the reader's
  /// language.
  final ValueChanged<String>? onRangeValidationError;

  /// 0 = Sunday (default), 1 = Monday, …
  final int startOfWeek;

  /// Return false to disable a date.
  final bool Function(DateTime)? selectableDayPredicate;

  /// Dots under specific dates. Keys must be date-only.
  final Map<DateTime, List<Color>>? markedDates;

  /// Fired when the visible month changes — swipe, arrow, or grid.
  final ValueChanged<DateTime>? onMonthChanged;

  /// Replaces the default cell entirely.
  final Widget Function(BuildContext context, DateTime day, DayCellInfo info)?
  dayBuilder;

  /// Offer a "clear" affordance that resets the selection to null.
  final bool clearable;
  final String? clearText;

  /// What the whole calendar is called to a screen reader.
  final String? semanticLabel;

  /// Take keyboard focus on build.
  ///
  /// False inline — a calendar in a page would pull focus off whatever
  /// the reader was doing. TRUE in a dialog and in the anchored panel,
  /// where the calendar IS what just opened and a keyboard user should
  /// not have to Tab into it.
  final bool autofocus;

  /// How FINE a thing this calendar picks.
  ///
  /// `month` opens on the month grid and reports the 1st of whichever
  /// month is chosen; `year` opens on the years. The two coarse modes
  /// existed on the WHEELS and were silently ignored here — a
  /// `monthYear` picker on a calendar surface drew a grid of days.
  final CalendarGrain grain;

  @override
  State<GlobalInlineCalendarRangePicker> createState() =>
      _GlobalInlineCalendarRangePickerState();
}

enum _CalendarView { days, months, years }

class _GlobalInlineCalendarRangePickerState
    extends State<GlobalInlineCalendarRangePicker> {
  _CalendarView _view = _CalendarView.days;

  late DateTime _first;
  late DateTime _last;
  late DateTime _focusedMonth;

  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  late List<DateTime> _selectedDates = [...widget.selectedDates];

  // Drag-to-sweep
  bool _isDragging = false;
  DateTime? _dragStart;
  DateTime? _dragEnd;
  double _dayViewWidth = 0;

  // Edge page-turn while sweeping
  Timer? _edgeScrollTimer;
  Timer? _edgeCooldownTimer;
  bool _edgeCooldown = false;

  /// -1 = leading edge active, 1 = trailing, 0 = none.
  int _edgeIndicator = 0;

  PageController? _pageController;
  bool _isPageAnimating = false;

  ScrollController? _yearGridController;
  ScrollController? _monthListController;
  ScrollController? _monthGridController;

  /// Where the ARROW KEYS are, which is not the same as what is
  /// selected and not the same as today. Null until a key is pressed —
  /// a mouse-only reader never sees the ring.
  DateTime? _keyboardDay;
  final FocusNode _gridFocus = FocusNode(debugLabel: 'calendarGrid');

  /// The resolved bag lives on the STATE, never in a `late` field — a
  /// picker can be laid out before its first paint, and a `late` bag
  /// throws there. Seeded with the context-free fallback so anything
  /// that runs before the first `build` still has numbers.
  ResolvedDateTimePickerStyle _style = ResolvedDateTimePickerStyle.fallback;

  static const _defaultSpan = Duration(days: 365);

  /// How months and days are COUNTED — Gregorian or Hijri.
  ///
  /// Everything else is calendar-agnostic already: a week is seven days
  /// in both, `DateTime.weekday` answers for both, and the value this
  /// widget reports is a `DateTime` either way. Only the counting
  /// changes, which is why the column arithmetic needed no edits.
  PickerCalendarSystem get _system => _style.calendarSystem;

  /// 1..12, in whichever calendar is counting.
  int _monthNumberOf(DateTime anchor) =>
      _system.monthsBetween(
        _system.anchorFor(_system.yearOf(anchor), 1),
        anchor,
      ) +
      1;

  // ─── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _view = switch (widget.grain) {
      CalendarGrain.day => _CalendarView.days,
      CalendarGrain.month => _CalendarView.months,
      CalendarGrain.year => _CalendarView.years,
    };
    _readBounds();
    _selectedStart = widget.selectedRange?.start;
    _selectedEnd = widget.selectedRange?.end;
  }

  /// The bag is materialised HERE, not in `build` and not in
  /// `initState`.
  ///
  /// Which calendar is counting decides where the first page even is,
  /// and `initState` cannot read an inherited widget — so a Hijri grid
  /// opened on a Gregorian anchor and drew the wrong month. This is the
  /// same place `GlobalDialog` resolves its own bag.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyStyle();
  }

  void _applyStyle() {
    final previous = _pageController == null ? null : _style.calendar;
    _style = (widget.style ?? const DateTimePickerStyle()).resolve(context);

    if (_pageController == null) {
      _focusedMonth = _monthOf(
        (widget.selectedRange?.start ??
                // A multi-select calendar has no range to open on, so
                // the first day it already holds is the next best thing.
                (widget.selectedDates.isEmpty
                    ? null
                    : widget.selectedDates.first) ??
                DateTime.now())
            .clampTo(_first, _last),
      );
      _pageController = _newPageController();
      return;
    }

    // A page index means a different month once the calendar changes,
    // so the controller is rebuilt rather than re-aimed.
    if (previous != _style.calendar) {
      _focusedMonth = _monthOf(_focusedMonth);
      _pageController?.dispose();
      _pageController = _newPageController();
    }
  }

  /// A month with nothing either side of it gives no sense of where it
  /// sits. The neighbours peek in, dimmed, and that sliver is also the
  /// affordance saying the grid swipes at all.
  ///
  /// The fraction is worked out from the WIDTH — see [_pageFraction].
  PageController _newPageController() => PageController(
    initialPage: _pageOf(_focusedMonth),
    viewportFraction: _pageFraction,
  );

  bool get _peeking => _style.monthPeek > 0;

  /// How much of the day view one month takes.
  ///
  /// With a peek the view spans the panel EDGE TO EDGE and the peek is
  /// carved from where the inset used to be, so the focused month keeps
  /// the width it has WITHOUT one. Taking a fraction of the view
  /// instead made switching the peek on look like adding padding,
  /// because the slice came out of the seven columns.
  double get _pageFraction {
    if (!_peeking || _dayViewWidth <= 0) return 1;
    return ((_dayViewWidth - _style.monthPeek * 2) / _dayViewWidth).clamp(
      0.5,
      1.0,
    );
  }

  /// Rebuilds the controller when the width it was sized against
  /// changes.
  ///
  /// `viewportFraction` is final, and a peek measured in POINTS only
  /// becomes a fraction once the view has been laid out — so the first
  /// controller is always built against a width of zero and has to be
  /// replaced as soon as there is a real one.
  void _syncPageFraction() {
    final controller = _pageController;
    if (controller == null) return;
    if ((controller.viewportFraction - _pageFraction).abs() < 0.001) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final old = _pageController;
      setState(() => _pageController = _newPageController());
      // A frame later, so the PageView has let go of it first.
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    });
  }

  @override
  void didUpdateWidget(GlobalInlineCalendarRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.style != oldWidget.style) _applyStyle();

    if (widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _readBounds();
      final clamped = _monthOf(_focusedMonth.clampTo(_first, _last));
      if (clamped != _focusedMonth) {
        _focusedMonth = clamped;
        _jumpToFocusedMonth();
      }
    }

    if (!listEquals(widget.selectedDates, oldWidget.selectedDates)) {
      _selectedDates = [...widget.selectedDates];
    }

    if (widget.selectedRange != oldWidget.selectedRange) {
      _selectedStart = widget.selectedRange?.start;
      _selectedEnd = widget.selectedRange?.end;
      // Not while sweeping — the reader may be two months away from
      // where the range starts, and yanking the page out from under a
      // finger mid-drag is how the sweep used to jump.
      if (widget.selectedRange != null && !_isDragging) {
        final month = _monthOf(widget.selectedRange!.start);
        if (month != _focusedMonth) {
          _focusedMonth = month.clampTo(_first, _last);
          _jumpToFocusedMonth();
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _edgeScrollTimer?.cancel();
    _edgeCooldownTimer?.cancel();
    _yearGridController?.dispose();
    _monthListController?.dispose();
    _monthGridController?.dispose();
    _gridFocus.dispose();
    super.dispose();
  }

  void _readBounds() {
    final today = DateUtils.dateOnly(DateTime.now());
    _first = DateUtils.dateOnly(
      widget.firstDate ?? today.subtract(_defaultSpan),
    );
    _last = DateUtils.dateOnly(widget.lastDate ?? today.add(_defaultSpan));
    if (_last.isBefore(_first)) _last = _first;
  }

  // ─── Month ↔ page ──────────────────────────────────────────
  //
  // The pages are BOUNDED by the date range rather than an arbitrary
  // 2400-page window centred on today. Unbounded, a swipe walked past
  // `lastDate` into months where every cell was disabled, and the two
  // arrows did the same.

  DateTime _monthOf(DateTime d) => _system.firstOfMonth(d);
  DateTime get _firstMonth => _monthOf(_first);
  DateTime get _lastMonth => _monthOf(_last);

  int _pageOf(DateTime month) => _system.monthsBetween(_firstMonth, month);

  DateTime _monthAtPage(int page) => _system.addMonths(_firstMonth, page);

  int get _pageCount => _pageOf(_lastMonth) + 1;

  bool get _canGoBack => _pageOf(_focusedMonth) > 0;
  bool get _canGoForward => _pageOf(_focusedMonth) < _pageCount - 1;

  void _jumpToFocusedMonth() {
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;
    controller.jumpToPage(_pageOf(_focusedMonth));
  }

  Future<void> _animateToPage(int page, Duration duration) async {
    final controller = _pageController;
    final clamped = page.clamp(0, _pageCount - 1);
    final month = _monthAtPage(clamped);
    final changed = month != _focusedMonth;

    _isPageAnimating = true;
    setState(() => _focusedMonth = month);
    if (changed) widget.onMonthChanged?.call(month);

    if (controller != null && controller.hasClients) {
      if (duration == Duration.zero) {
        controller.jumpToPage(clamped);
      } else {
        await controller.animateToPage(
          clamped,
          duration: duration,
          curve: Curves.easeInOut,
        );
      }
    }
    _isPageAnimating = false;
  }

  // ─── Navigation ────────────────────────────────────────────

  void _navigate({required bool forward, required Duration motion}) {
    switch (_view) {
      case _CalendarView.days:
        _animateToPage(
          _pageOf(_focusedMonth) + (forward ? 1 : -1),
          motion,
        );
      case _CalendarView.months:
        // A year is twelve months in either calendar, so the step is
        // in MONTHS rather than in a `DateTime` year.
        final month = _system
            .addMonths(_focusedMonth, forward ? 12 : -12)
            .clampTo(_firstMonth, _lastMonth);
        setState(() => _focusedMonth = _monthOf(month));
        widget.onMonthChanged?.call(_focusedMonth);
      case _CalendarView.years:
        final month = _system
            .addMonths(_focusedMonth, forward ? 144 : -144)
            .clampTo(_firstMonth, _lastMonth);
        setState(() => _focusedMonth = _monthOf(month));
    }
  }

  bool _navigationEnabled({required bool forward}) {
    if (!widget.enabled) return false;
    return switch (_view) {
      _CalendarView.days => forward ? _canGoForward : _canGoBack,
      _ =>
        forward
            ? _system.yearOf(_focusedMonth) < _system.yearOf(_lastMonth)
            : _system.yearOf(_focusedMonth) > _system.yearOf(_firstMonth),
    };
  }

  String _navigationLabel({required bool forward}) => switch (_view) {
    _CalendarView.days =>
      forward ? DatePickerStrings.nextMonth : DatePickerStrings.previousMonth,
    _CalendarView.months =>
      forward ? DatePickerStrings.nextYear : DatePickerStrings.previousYear,
    _CalendarView.years =>
      forward ? DatePickerStrings.nextYears : DatePickerStrings.previousYears,
  };

  // ─── Selection ─────────────────────────────────────────────

  void _onDayTapped(DateTime day) {
    if (!widget.enabled || _isDragging) return;
    if (_style.enableHaptic) HapticFeedback.selectionClick();
    setState(() {
      _keyboardDay = day;
      _updateSelection(day);
    });
  }

  void _updateSelection(DateTime day) {
    if (widget.selection == CalendarSelection.multiple) {
      final was = _selectedDates.length;
      _selectedDates.removeWhere((d) => isSameDay(d, day));
      if (_selectedDates.length == was) _selectedDates.add(day);
      _selectedDates.sort();
      widget.onDatesChanged?.call(List.unmodifiable(_selectedDates));
      return;
    }
    if (widget.singleSelect) {
      _selectedStart = day;
      _selectedEnd = day;
      widget.onChanged?.call(DateTimeRange(start: day, end: day));
      return;
    }

    final hasBoth = _selectedStart != null && _selectedEnd != null;

    // A complete range plus a tap starts a new one.
    if (hasBoth || _selectedStart == null) {
      _selectedStart = day;
      _selectedEnd = null;
      return;
    }

    var start = _selectedStart!;
    var end = day;
    if (end.isBefore(start)) {
      start = day;
      end = _selectedStart!;
    }

    if (!_validateRange(start, end)) return;

    _selectedStart = start;
    _selectedEnd = end;
    widget.onChanged?.call(DateTimeRange(start: start, end: end));
  }

  bool get _hasSelection =>
      _selectedStart != null ||
      _selectedEnd != null ||
      _selectedDates.isNotEmpty;

  void _clearSelection() {
    if (_style.enableHaptic) HapticFeedback.selectionClick();
    setState(() {
      _selectedStart = null;
      _selectedEnd = null;
      _selectedDates = [];
    });
    widget.onChanged?.call(null);
    widget.onDatesChanged?.call(const []);
  }

  bool _validateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    final min = widget.minimumRangeDays;
    final max = widget.maximumRangeDays;

    if (min != null && days < min) {
      widget.onRangeValidationError?.call(DatePickerStrings.minRangeDays(min));
      return false;
    }
    if (max != null && days > max) {
      widget.onRangeValidationError?.call(DatePickerStrings.maxRangeDays(max));
      return false;
    }
    return true;
  }

  bool _withinRangeLimits(DateTime day, DateTime? start) {
    if (start == null) return true;
    final days = day.difference(start).inDays;
    if (widget.minimumRangeDays != null && days < widget.minimumRangeDays!) {
      return false;
    }
    if (widget.maximumRangeDays != null && days > widget.maximumRangeDays!) {
      return false;
    }
    return true;
  }

  // ─── Drag-to-sweep ─────────────────────────────────────────

  bool get _listFlow => _style.monthFlow == MonthFlow.list;

  bool get _dragEnabled =>
      widget.enabled &&
      widget.selection == CalendarSelection.range &&
      _style.enableDragSelect &&
      // A long-press drag inside a vertical scroller fights the
      // scroller, and loses.
      !_listFlow;

  DateTime? _dayAt(Offset local) {
    final firstDayOffset = CalendarGrid.firstDayOffset(
      _focusedMonth,
      widget.startOfWeek,
    );
    final daysInMonth = _system.daysInMonth(_focusedMonth);
    // Where the focused month starts depends on which of the two
    // layouts is running: peeking, the PEEK is the inset; not peeking,
    // the panel's own is. Reading it off the view alone put every sweep
    // a column out.
    // The week gutter is not part of the seven columns, so it shifts
    // where they start.
    final inset = (_peeking ? _style.monthPeek : _gridInset) + _weekColumnWidth;

    final dayNumber = CalendarGrid.dayNumberAt(
      local: local,
      gridWidth: math.max(
        0.0,
        _dayViewWidth - inset - (_peeking ? _style.monthPeek : _gridInset),
      ),
      inset: inset,
      headerExtent: _headerExtent,
      rowExtent: _style.rowExtent,
      firstDayOffset: firstDayOffset,
      daysInMonth: daysInMonth,
      rtl: Directionality.of(context) == TextDirection.rtl,
    );
    if (dayNumber == null) return null;

    final day = _system.dayOf(_focusedMonth, dayNumber);
    if (day.isBefore(_first) || day.isAfter(_last)) return null;
    if (widget.selectableDayPredicate?.call(day) == false) return null;
    return day;
  }

  void _onSweepStart(LongPressStartDetails details) {
    final day = _dayAt(details.localPosition);
    if (day == null) return;

    if (_style.enableHaptic) HapticFeedback.selectionClick();
    setState(() {
      _isDragging = true;
      _dragStart = day;
      _dragEnd = day;
      _selectedStart = day;
      _selectedEnd = null;
    });
  }

  void _onSweepUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDragging) return;

    if (_style.enableEdgeScroll) {
      final x = details.localPosition.dx;
      const zone = DateTimePickerDefaults.edgeScrollZone;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      if (x < zone && !_edgeCooldown) {
        _setEdgeIndicator(-1);
        _scheduleEdgeScroll(forward: rtl);
      } else if (x > _dayViewWidth - zone && !_edgeCooldown) {
        _setEdgeIndicator(1);
        _scheduleEdgeScroll(forward: !rtl);
      } else {
        _setEdgeIndicator(0);
        _stopEdgeScroll();
      }
    }

    final day = _dayAt(details.localPosition);
    if (day == null || day == _dragEnd) return;
    setState(() {
      _dragEnd = day;
      _applySweep(emit: true);
    });
  }

  void _onSweepEnd() {
    if (!_isDragging) return;
    _stopEdgeScroll();
    setState(() {
      _isDragging = false;
      _edgeIndicator = 0;
      _applySweep(emit: true, finalise: true);
      _dragStart = null;
      _dragEnd = null;
    });
    _edgeCooldown = false;
  }

  void _applySweep({required bool emit, bool finalise = false}) {
    final a = _dragStart;
    final b = _dragEnd;
    if (a == null || b == null) return;

    final start = b.isBefore(a) ? b : a;
    final end = b.isBefore(a) ? a : b;

    if (!_validateRange(start, end)) {
      if (finalise) {
        _selectedStart = widget.selectedRange?.start;
        _selectedEnd = widget.selectedRange?.end;
      }
      return;
    }

    _selectedStart = start;
    _selectedEnd = end;
    if (emit) widget.onChanged?.call(DateTimeRange(start: start, end: end));
  }

  void _setEdgeIndicator(int direction) {
    if (_edgeIndicator != direction) {
      setState(() => _edgeIndicator = direction);
    }
  }

  void _scheduleEdgeScroll({required bool forward}) {
    if (_edgeScrollTimer != null || _edgeCooldown) return;
    _edgeScrollTimer = Timer(DateTimePickerDefaults.edgeScrollDelay, () async {
      _edgeScrollTimer = null;
      if (!mounted || !_isDragging) return;

      await _animateToPage(
        _pageOf(_focusedMonth) + (forward ? 1 : -1),
        _style.pageDuration,
      );
      if (!mounted || !_isDragging) return;

      // Carry the sweep into the new month so the range keeps
      // following the finger rather than stopping at the fold.
      setState(() {
        _dragEnd = forward
            ? _focusedMonth
            : _system.dayOf(
                _focusedMonth,
                _system.daysInMonth(_focusedMonth),
              );
        _applySweep(emit: true);
      });
      _setEdgeIndicator(0);

      // Without the cooldown, one held finger flips through a year.
      _edgeCooldown = true;
      _edgeCooldownTimer?.cancel();
      _edgeCooldownTimer = Timer(
        DateTimePickerDefaults.edgeScrollCooldown,
        () => _edgeCooldown = false,
      );
    });
  }

  void _stopEdgeScroll() {
    _edgeScrollTimer?.cancel();
    _edgeScrollTimer = null;
    _setEdgeIndicator(0);
  }

  // ─── Keyboard ──────────────────────────────────────────────
  //
  // The calendar had `Semantics` on every cell and no way to reach one
  // without a pointer — which made it worse than the Material picker it
  // replaced, because that one arrows around a month. One focus node
  // for the whole grid, arrow keys to move a cursor, Enter to take it:
  // forty-two focusable cells would make Tab useless.

  /// The day the arrow keys act on, defaulting to what is selected.
  DateTime get _cursor => _keyboardDay ?? _selectedStart ?? _focusedMonth;

  void _moveCursor(int days) {
    final next = DateTime(
      _cursor.year,
      _cursor.month,
      _cursor.day + days,
    ).clampTo(_first, _last);
    _showCursor(next);
  }

  void _moveCursorMonths(int months) =>
      _showCursor(_system.addMonths(_cursor, months).clampTo(_first, _last));

  void _cursorToEdge({required bool end}) {
    final anchor = _system.firstOfMonth(_cursor);
    _showCursor(
      _system
          .dayOf(anchor, end ? _system.daysInMonth(anchor) : 1)
          .clampTo(_first, _last),
    );
  }

  /// Puts the cursor on [day], turning the page to it if it has left
  /// the month on screen.
  void _showCursor(DateTime day) {
    setState(() => _keyboardDay = day);
    final month = _monthOf(day);
    if (_system.monthsBetween(_focusedMonth, month) != 0) {
      _animateToPage(_pageOf(month), _style.pageDuration);
    }
  }

  void _takeCursor() {
    final day = _cursor;
    if (day.isBefore(_first) || day.isAfter(_last)) return;
    if (widget.selectableDayPredicate?.call(day) == false) return;
    _onDayTapped(day);
  }

  /// In Arabic the grid runs the other way, so "left" is the next day.
  Map<ShortcutActivator, VoidCallback> _shortcuts(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return {
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          _moveCursor(rtl ? 1 : -1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          _moveCursor(rtl ? -1 : 1),
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => _moveCursor(-7),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => _moveCursor(7),
      const SingleActivator(LogicalKeyboardKey.pageUp): () =>
          _moveCursorMonths(-1),
      const SingleActivator(LogicalKeyboardKey.pageDown): () =>
          _moveCursorMonths(1),
      const SingleActivator(LogicalKeyboardKey.home): () =>
          _cursorToEdge(end: false),
      const SingleActivator(LogicalKeyboardKey.end): () =>
          _cursorToEdge(end: true),
      const SingleActivator(LogicalKeyboardKey.enter): _takeCursor,
      const SingleActivator(LogicalKeyboardKey.space): _takeCursor,
    };
  }

  // ─── Day state ─────────────────────────────────────────────

  /// Whether the keyboard cursor is on [day] AND the grid has focus —
  /// a ring on an unfocused calendar points at nothing.
  bool _isCursor(DateTime day) =>
      _keyboardDay != null &&
      _gridFocus.hasFocus &&
      isSameDay(_keyboardDay, day);

  bool _isStart(DateTime day) => widget.selection == CalendarSelection.multiple
      ? _selectedDates.any((d) => isSameDay(d, day))
      : isSameDay(_selectedStart, day);

  bool _isEnd(DateTime day) => widget.selection == CalendarSelection.multiple
      ? _isStart(day)
      : isSameDay(_selectedEnd, day);

  bool _isInRange(DateTime day) {
    // Nothing spans between two arbitrary days, so nothing is drawn
    // between them either.
    if (widget.selection == CalendarSelection.multiple) return false;
    final s = _selectedStart;
    final e = _selectedEnd;
    if (s == null || e == null) return false;
    return day.isAfter(s) && day.isBefore(e);
  }

  bool _isAdditional(DateTime day) {
    final end = _selectedEnd;
    final extra = widget.additionalDays ?? 0;
    if (end == null || extra == 0) return false;
    final tail = end.add(Duration(days: extra));
    return day.isAfter(end) && (day.isBefore(tail) || isSameDay(tail, day));
  }

  bool _isPastCutoff(DateTime day, DateTime today) {
    final n = widget.previousDaysDisabled;
    if (n == null || n == 0) return false;
    return day.isBefore(today.subtract(Duration(days: n)));
  }

  // ─── Geometry ──────────────────────────────────────────────

  double get _gridInset => context.spacing.md;

  /// The week-number gutter, or nothing when it is off.
  double get _weekColumnWidth => _style.showWeekNumbers
      ? _style.dayCellSize * DateTimePickerDefaults.weekNumberColumnFactor
      : 0;

  /// The weekday-label strip's own height.
  double get _weekdayExtent => math.max(24, _style.weekdayLabelFontSize * 1.5);

  /// Everything above the first day row. The sweep hit-test reads the
  /// SAME number the layout uses — it used to be a hard-coded `24 + 8`
  /// beside a cell size the caller could change, so a taller cell made
  /// every drag select the row above.
  double get _headerExtent => _weekdayExtent + _style.dayCellMargin * 2;

  double _dayViewHeight(DateTime month) {
    final rows = CalendarGrid.rowsFor(
      CalendarGrid.firstDayOffset(month, widget.startOfWeek),
      _system.daysInMonth(month),
    );
    return _headerExtent + rows * _style.rowExtent;
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final motion = reduceMotion ? Duration.zero : _style.viewSwitchDuration;
    final today = DateUtils.dateOnly(DateTime.now());
    final panel = _buildPanel(context, today, reduceMotion, motion);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The vertical list FILLS the box it was given; the paged one
          // is as tall as its month.
          if (_listFlow) Expanded(child: panel) else panel,
          if (widget.errorText != null) ...[
            SizedBox(height: context.spacing.sm),
            Padding(
              padding: EdgeInsetsDirectional.only(start: context.spacing.xs),
              child: Text(
                widget.errorText!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.statusColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    DateTime today,
    bool reduceMotion,
    Duration motion,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _style.surfaceColor,
        borderRadius: BorderRadius.circular(_style.radius),
        border: Border.all(
          color: widget.errorText != null
              ? context.statusColors.error
              : _style.borderColor,
          width: widget.errorText != null
              ? _style.borderWidth * 2
              : _style.borderWidth,
        ),
        boxShadow: _style.shadow,
      ),
      padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
      child: Column(
        children: [
          // No month header in the list: every month names itself as it
          // goes by, and a header that could not follow the scroll
          // would be a stale one.
          if (!_listFlow) _buildHeader(context, reduceMotion),
          if (widget.clearable && _hasSelection) _buildClear(context),
          SizedBox(height: context.spacing.md),
          if (_listFlow)
            Expanded(child: _buildDayView(context, today))
          else
            AnimatedSize(
              duration: motion,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: motion,
                child: switch (_view) {
                  _CalendarView.months => _buildMonthGrid(context, today),
                  _CalendarView.years => _buildYearGrid(context, today),
                  _CalendarView.days => _buildDayView(context, today),
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool reduceMotion) {
    final motion = reduceMotion ? Duration.zero : _style.pageDuration;

    Widget arrow({required bool forward}) {
      // `Icons.chevron_left` and `chevron_right` carry
      // `matchTextDirection: true`, so the FRAMEWORK mirrors them in
      // Arabic. Picking the glyph by hand as well flipped them twice
      // and put them back the way they started — which is exactly what
      // an Arabic screenshot showed.
      return GlobalIconButton(
        iconData: forward ? Icons.chevron_right : Icons.chevron_left,
        iconSize: _style.arrowIconSize,
        semanticLabel: _navigationLabel(forward: forward),
        tooltip: _navigationLabel(forward: forward),
        enableHaptic: _style.enableHaptic,
        style: ButtonStateStyle(foregroundColor: _style.arrowColor, width: 40),
        onPressed: _navigationEnabled(forward: forward)
            ? () => _navigate(forward: forward, motion: motion)
            : null,
      );
    }

    Widget viewToggle({
      required String text,
      required _CalendarView view,
      required String label,
    }) {
      final active = _view == view;
      return Semantics(
        button: true,
        expanded: active,
        label: label,
        child: InkWell(
          onTap: widget.enabled
              ? () => setState(
                  () => _view = active ? _CalendarView.days : view,
                )
              : null,
          borderRadius: BorderRadius.circular(_style.gridCellRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.xs,
              vertical: context.spacing.xs,
            ),
            child: ExcludeSemantics(
              child: Text(
                text,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: _style.calendarHeaderFontWeight,
                  fontSize: _style.calendarHeaderFontSize,
                  color: active ? _style.arrowColor : _style.dayTextColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          arrow(forward: false),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: viewToggle(
                    text: _system.monthName(_focusedMonth),
                    view: _CalendarView.months,
                    label: DatePickerStrings.chooseMonth,
                  ),
                ),
                Flexible(
                  child: viewToggle(
                    text: AppNumbers.padded(
                      _system.yearOf(_focusedMonth),
                      width: 4,
                    ),
                    view: _CalendarView.years,
                    label: DatePickerStrings.chooseYear,
                  ),
                ),
                AnimatedRotation(
                  turns: _view == _CalendarView.days ? 0 : 0.5,
                  duration: reduceMotion
                      ? Duration.zero
                      : _style.viewSwitchDuration,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: context.iconSizes.sm,
                    color: _style.arrowColor,
                  ),
                ),
              ],
            ),
          ),
          arrow(forward: true),
        ],
      ),
    );
  }

  Widget _buildClear(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: context.spacing.sm),
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: widget.enabled ? _clearSelection : null,
            borderRadius: BorderRadius.circular(_style.gridCellRadius),
            child: Padding(
              padding: EdgeInsets.all(context.spacing.xs),
              child: Text(
                widget.clearText ?? CommonStrings.clear,
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _style.arrowColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Day view ──────────────────────────────────────────────

  Widget _buildDayView(BuildContext context, DateTime today) {
    return CallbackShortcuts(
      bindings: _shortcuts(context),
      child: Focus(
        focusNode: _gridFocus,
        canRequestFocus: widget.enabled,
        autofocus: widget.autofocus && widget.enabled,
        child: _buildDayViewBody(context, today),
      ),
    );
  }

  Widget _buildDayViewBody(BuildContext context, DateTime today) {
    return LayoutBuilder(
      key: const ValueKey('dayView'),
      builder: (context, constraints) {
        _dayViewWidth = constraints.maxWidth;
        _syncPageFraction();
        return _style.monthFlow == MonthFlow.list
            ? _buildMonthList(context, today)
            : _buildPagedMonths(context, today);
      },
    );
  }

  /// One month at a time, swiped, with its neighbours peeking in.
  Widget _buildPagedMonths(BuildContext context, DateTime today) {
    const zone = DateTimePickerDefaults.edgeScrollZone;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: _dragEnabled ? _onSweepStart : null,
      onLongPressMoveUpdate: _dragEnabled ? _onSweepUpdate : null,
      onLongPressEnd: _dragEnabled ? (_) => _onSweepEnd() : null,
      onLongPressCancel: _dragEnabled ? _onSweepEnd : null,
      child: SizedBox(
        height: _dayViewHeight(_focusedMonth),
        child: Stack(
          children: [
            // With a peek the view spans the panel EDGE TO EDGE and the
            // peek is carved from where the inset used to be, so the
            // focused month keeps the width it has WITHOUT one. The
            // inset used to sit on each PAGE, which made the sliver a
            // neighbour showed its own padding and nothing else.
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _peeking ? 0 : _gridInset,
              ),
              child: _FadeEdges(
                axis: Axis.horizontal,
                // Never wider than half the sliver it is fading, or the
                // neighbour is faded out of existence.
                size: _peeking
                    ? math.min(_style.edgeFadeSize, _style.monthPeek / 2)
                    : 0,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pageCount,
                  physics: _style.enableSwipeMonths && !_isDragging
                      ? null
                      : const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    if (_isPageAnimating) return;
                    final month = _monthAtPage(page);
                    setState(() => _focusedMonth = month);
                    widget.onMonthChanged?.call(month);
                  },
                  // The view is as tall as the FOCUSED month, and that
                  // updates the moment a turn starts — so the outgoing
                  // month can be a row taller than the box it is sliding
                  // out of. A scroll view clips instead of asserting,
                  // and the row it clips is already on its way off
                  // screen. Hijri makes this routine: 29- and 30-day
                  // months change the row count far more often than
                  // Gregorian ones do.
                  itemBuilder: (context, page) => SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: _DimWhenAway(
                      controller: _pageController!,
                      page: page,
                      focusedPage: _pageOf(_focusedMonth),
                      opacity: _style.neighbourOpacity,
                      child: _buildMonth(
                        context,
                        _monthAtPage(page),
                        today,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_edgeIndicator != 0)
              PositionedDirectional(
                start: _edgeIndicator == -1 ? 0 : null,
                end: _edgeIndicator == 1 ? 0 : null,
                top: 0,
                bottom: 0,
                width: zone,
                child: _EdgeHint(
                  leading: _edgeIndicator == -1,
                  color: _style.arrowColor,
                  radius: _style.gridCellRadius,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Every month in the range, stacked and scrolled.
  ///
  /// What a full page wants: the room is there, and a range spanning a
  /// fold is easier to pick when both ends are on screen. The weekday
  /// strip is pinned above the list rather than repeated in every
  /// month, and the sweep is off — a long-press drag inside a vertical
  /// scroller fights the scroller.
  Widget _buildMonthList(BuildContext context, DateTime today) {
    _monthListController ??= ScrollController(
      initialScrollOffset: _offsetOfMonth(_pageOf(_focusedMonth)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _gridInset),
          child: _buildWeekdayStrip(context),
        ),
        SizedBox(height: _style.dayCellMargin * 2),
        Expanded(
          child: _FadeEdges(
            axis: Axis.vertical,
            size: _style.edgeFadeSize,
            child: ListView.builder(
              controller: _monthListController,
              itemCount: _pageCount,
              itemBuilder: (context, index) {
                final month = _monthAtPage(index);
                return Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    _gridInset,
                    0,
                    _gridInset,
                    DateTimePickerDefaults.monthListGap,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: _monthLabelExtent,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Semantics(
                            header: true,
                            child: Text(
                              '${_system.monthName(month)} '
                              '${AppNumbers.padded(_system.yearOf(month), width: 4)}',
                              style: context.textTheme.titleSmall?.copyWith(
                                fontWeight: _style.calendarHeaderFontWeight,
                                color: _style.dayTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _buildMonth(
                        context,
                        month,
                        today,
                        showWeekdays: false,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// The label above each month in the list.
  double get _monthLabelExtent => math.max(28, _style.dayFontSize * 2);

  /// Where month [page] starts in the list. Every month's height is
  /// known before it is built — it is rows times a row — so the list
  /// opens on the focused month exactly rather than near it.
  double _offsetOfMonth(int page) {
    var offset = 0.0;
    for (var i = 0; i < page; i++) {
      final month = _monthAtPage(i);
      final rows = CalendarGrid.rowsFor(
        CalendarGrid.firstDayOffset(month, widget.startOfWeek),
        _system.daysInMonth(month),
      );
      offset +=
          _monthLabelExtent +
          rows * _style.rowExtent +
          DateTimePickerDefaults.monthListGap;
    }
    return offset;
  }

  Widget _buildMonth(
    BuildContext context,
    DateTime month,
    DateTime today, {
    bool showWeekdays = true,
  }) {
    final firstDayOffset = CalendarGrid.firstDayOffset(
      month,
      widget.startOfWeek,
    );
    final daysInMonth = _system.daysInMonth(month);
    final rows = CalendarGrid.rowsFor(firstDayOffset, daysInMonth);

    return Column(
      key: ValueKey('month_${month.year}_${month.month}'),
      children: [
        if (showWeekdays) ...[
          _buildWeekdayStrip(context),
          SizedBox(height: _style.dayCellMargin * 2),
        ],
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              if (_style.showWeekNumbers)
                _weekNumberCell(
                  context,
                  // The FOURTH cell of the row, not the first. ISO
                  // weeks run Monday to Sunday, so a row drawn from
                  // Sunday straddles two of them — and the fourth cell
                  // is inside the one the row mostly is, whichever day
                  // it starts on.
                  _system.dayOf(month, row * 7 - firstDayOffset + 4),
                ),
              for (var col = 0; col < 7; col++)
                _buildCell(
                  context,
                  month: month,
                  today: today,
                  dayNumber: row * 7 + col - firstDayOffset + 1,
                  daysInMonth: daysInMonth,
                ),
            ],
          ),
      ],
    );
  }

  /// The seven letters above the grid.
  ///
  /// NARROW names, not short. Arabic's short names are whole words —
  /// الاثنين, الثلاثاء — and seven of them across a phone ran into each
  /// other, which is what an Arabic screenshot showed. Narrow is one or
  /// two characters in every locale, and is what a calendar grid wants.
  Widget _buildWeekdayStrip(BuildContext context) {
    final all = DateFormat.E().dateSymbols.STANDALONENARROWWEEKDAYS;
    final weekdays = [
      for (var i = 0; i < 7; i++) all[(i + widget.startOfWeek) % 7],
    ];

    return SizedBox(
      height: _weekdayExtent,
      child: ExcludeSemantics(
        child: Row(
          children: [
            if (_style.showWeekNumbers) SizedBox(width: _weekColumnWidth),
            for (final day in weekdays)
              Expanded(
                child: Center(
                  // A locale whose narrow names are still wide — and
                  // there are some — shrinks rather than overflowing
                  // into its neighbour.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day,
                      maxLines: 1,
                      softWrap: false,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: _style.weekdayLabelFontSize,
                        color: _style.weekdayLabelColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// One number in the leading gutter.
  Widget _weekNumberCell(BuildContext context, DateTime rowStart) {
    return SizedBox(
      width: _weekColumnWidth,
      height: _style.rowExtent,
      child: Center(
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppNumbers.padded(
                CalendarGrid.isoWeekNumber(rowStart),
                width: 1,
              ),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: _style.weekdayLabelFontSize,
                fontWeight: FontWeight.w600,
                color: _style.weekdayLabelColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(
    BuildContext context, {
    required DateTime month,
    required DateTime today,
    required int dayNumber,
    required int daysInMonth,
  }) {
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return _buildOutsideCell(context, month, dayNumber);
    }

    final day = _system.dayOf(month, dayNumber);

    final isStart = _isStart(day);
    final isEnd = _isEnd(day);
    final isSelected = isStart || isEnd;
    final isInRange = _isInRange(day);
    final isAdditional = _isAdditional(day);
    final isToday = _style.showTodayHighlight && isSameDay(today, day);
    final markers = widget.markedDates?[DateUtils.dateOnly(day)] ?? const [];

    final rangeLimited =
        _selectedStart != null &&
        _selectedEnd == null &&
        !_withinRangeLimits(day, _selectedStart);
    final isDisabled =
        day.isBefore(_first) ||
        day.isAfter(_last) ||
        _isPastCutoff(day, today) ||
        rangeLimited ||
        widget.selectableDayPredicate?.call(day) == false;

    final info = DayCellInfo(
      isSelected: isSelected,
      isStart: isStart,
      isEnd: isEnd,
      isInRange: isInRange,
      isToday: isToday,
      isDisabled: isDisabled,
      isOutside: false,
      markers: markers,
    );

    final tappable = !isDisabled && widget.enabled && !_isDragging;

    return Expanded(
      child: Semantics(
        button: true,
        enabled: !isDisabled,
        selected: isSelected,
        label: _cellLabel(day, info),
        onTap: tappable ? () => _onDayTapped(day) : null,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: tappable ? () => _onDayTapped(day) : null,
            child:
                widget.dayBuilder?.call(context, day, info) ??
                _defaultCell(
                  context,
                  day: day,
                  info: info,
                  isAdditional: isAdditional,
                  markers: markers,
                ),
          ),
        ),
      ),
    );
  }

  String _cellLabel(DateTime day, DayCellInfo info) {
    final parts = <String>[_system.describe(day)];
    if (info.isToday) parts.add(DatePickerStrings.today);
    if (info.isStart && info.isEnd) {
      parts.add(DatePickerStrings.selected);
    } else if (info.isStart) {
      parts.add(DatePickerStrings.rangeStart);
    } else if (info.isEnd) {
      parts.add(DatePickerStrings.rangeEnd);
    } else if (info.isInRange) {
      parts.add(DatePickerStrings.inRange);
    }
    if (info.isDisabled) parts.add(DatePickerStrings.unavailable);
    if (info.markers.isNotEmpty) {
      parts.add(DatePickerStrings.events(info.markers.length));
    }
    return parts.join(', ');
  }

  Widget _buildOutsideCell(
    BuildContext context,
    DateTime month,
    int dayNumber,
  ) {
    if (!_style.showOutsideDays) {
      return Expanded(child: SizedBox(height: _style.rowExtent));
    }

    // Out-of-range indices run into the neighbouring months on their
    // own, in either calendar — no branch needed.
    final outside = _system.dayOf(month, dayNumber);

    return Expanded(
      child: ExcludeSemantics(
        child: SizedBox(
          height: _style.rowExtent,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AppNumbers.padded(_system.dayNumberOf(outside), width: 1),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: _style.dayFontSize,
                  color: _style.dayTextColor.withValues(
                    alpha: _style.outsideDayOpacity,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultCell(
    BuildContext context, {
    required DateTime day,
    required DayCellInfo info,
    required bool isAdditional,
    required List<Color> markers,
  }) {
    final circle =
        (info.isSelected && _style.selectedDayShape == BoxShape.circle) ||
        (info.isToday &&
            !info.isSelected &&
            _style.todayShape == BoxShape.circle) ||
        (!info.isSelected &&
            !info.isToday &&
            _style.dayShape == BoxShape.circle);

    final shape = info.isSelected
        ? _style.selectedDayShape
        : info.isToday
        ? _style.todayShape
        : _style.dayShape;

    return Container(
      margin: EdgeInsetsDirectional.only(
        start: isAdditional || info.isStart ? 2 : 0,
        end: isAdditional || info.isEnd ? 2 : 0,
        top: _style.dayCellMargin,
        bottom: _style.dayCellMargin,
      ),
      height: _style.dayCellSize,
      decoration: BoxDecoration(
        color: _cellFill(info, isAdditional),
        gradient: info.isSelected ? _style.selectedGradient : null,
        shape: shape,
        borderRadius: circle ? null : _rangeBarRadius(day, info, isAdditional),
        // The keyboard's ring wins over today's border: it is
        // transient, and where the next key press will act matters more
        // than which day happens to be today.
        border: _isCursor(day)
            ? Border.all(
                color: _style.focusRingColor,
                width: DateTimePickerDefaults.focusRingWidth,
              )
            : info.isToday && !info.isSelected
            ? Border.all(
                color: _style.todayBorderColor,
                width: _style.todayBorderWidth,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // A narrow cell SHRINKS its number rather than wrapping it.
          // Two digits at 16 points need 32, and a seven-column grid in
          // a 296-point panel gives each cell 31.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppNumbers.padded(_system.dayNumberOf(day), width: 1),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: _style.dayFontSize,
                fontWeight: info.isSelected
                    ? _style.selectedDayFontWeight
                    : info.isToday
                    ? _style.todayFontWeight
                    : _style.dayFontWeight,
                color: _cellTextColor(info),
              ),
            ),
          ),
          if (markers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in markers.take(_style.maxMarkers))
                    Container(
                      width: _style.markerSize,
                      height: _style.markerSize,
                      margin: EdgeInsets.symmetric(
                        horizontal: _style.markerSpacing / 2,
                      ),
                      decoration: BoxDecoration(
                        color: info.isSelected
                            ? _style.selectedDayTextColor
                            : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _cellFill(DayCellInfo info, bool isAdditional) {
    if (isAdditional) return _style.additionalDayColor;
    if (!widget.enabled) {
      return _style.dayTextColor.withValues(
        alpha: _style.disabledDayOpacity * 0.2,
      );
    }
    if (info.isSelected) {
      // A gradient paints INSTEAD of a fill, and `BoxDecoration`
      // asserts if both are set.
      return _style.selectedGradient != null
          ? Colors.transparent
          : _style.selectedDayColor;
    }
    if (info.isInRange) return _style.rangeFillColor;
    return Colors.transparent;
  }

  Color _cellTextColor(DayCellInfo info) {
    if (info.isSelected) return _style.selectedDayTextColor;
    if (info.isDisabled || !widget.enabled) {
      return _style.dayTextColor.withValues(alpha: _style.disabledDayOpacity);
    }
    if (info.isToday) return _style.todayTextColor;
    if (info.isInRange) return _style.rangeTextColor;
    return _style.dayTextColor;
  }

  /// The range reads as ONE bar: only its two ends are round, plus
  /// whichever cells sit at a row's edge so the bar does not run into
  /// the panel's own corner.
  BorderRadiusGeometry _rangeBarRadius(
    DateTime day,
    DayCellInfo info,
    bool isAdditional,
  ) {
    final r = Radius.circular(_style.dayRadius);
    if (isAdditional) return BorderRadius.all(r);

    final column = CalendarGrid.columnOf(day, widget.startOfWeek);
    final rowStart = column == 0;
    final rowEnd = column == 6;

    return BorderRadiusDirectional.horizontal(
      start: rowStart || info.isStart ? r : Radius.zero,
      end: rowEnd || info.isEnd ? r : Radius.zero,
    );
  }

  // ─── Month + year grids ────────────────────────────────────

  /// How tall a grid of [count] cells comes out, and how tall it is
  /// allowed to be.
  ///
  /// It used to be a FIXED box for both, which left a band of white
  /// under twelve months and hid the tail of a long year list behind an
  /// edge that did not scroll.
  double _gridContentHeight(double width, int count) {
    const columns = DateTimePickerDefaults.gridColumns;
    final spacing = context.spacing.sm;
    final cellWidth = (width - spacing * (columns - 1)) / columns;
    final cellHeight = cellWidth / DateTimePickerDefaults.gridAspectRatio;
    final rows = (count / columns).ceil();
    return rows * cellHeight + spacing * (rows - 1);
  }

  /// The ceiling. A fixed 280 was most of a landscape phone.
  double _gridCap(BuildContext context) => math.min(
    _style.gridViewHeight,
    MediaQuery.sizeOf(context).height * 0.45,
  );

  Widget _buildOptionGrid({
    required Key key,
    required int count,
    required ScrollController controller,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return LayoutBuilder(
      key: key,
      builder: (context, constraints) {
        final width = constraints.maxWidth - _gridInset * 2;
        final content = _gridContentHeight(width, count);
        final cap = _gridCap(context);

        return SizedBox(
          height: math.min(content, cap),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _gridInset),
            child: _FadeEdges(
              axis: Axis.vertical,
              // Only worth a fade when there is something past the
              // edge to fade INTO.
              size: content > cap ? _style.edgeFadeSize : 0,
              child: GridView.builder(
                controller: controller,
                physics: content > cap
                    ? null
                    : const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: DateTimePickerDefaults.gridColumns,
                  childAspectRatio: DateTimePickerDefaults.gridAspectRatio,
                  crossAxisSpacing: context.spacing.sm,
                  mainAxisSpacing: context.spacing.sm,
                ),
                itemCount: count,
                itemBuilder: itemBuilder,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthGrid(BuildContext context, DateTime today) {
    final months = _system.monthNames();
    final focusedYear = _system.yearOf(_focusedMonth);
    _monthGridController ??= ScrollController();

    return _buildOptionGrid(
      key: const ValueKey('monthView'),
      count: 12,
      controller: _monthGridController!,
      itemBuilder: (context, index) {
        final month = _system.anchorFor(focusedYear, index + 1);
        final enabled =
            widget.enabled &&
            !month.isBefore(_firstMonth) &&
            !month.isAfter(_lastMonth);

        return _GridCell(
          label: months[index],
          semanticLabel:
              '${months[index]} '
              '${AppNumbers.padded(focusedYear, width: 4)}',
          selected: _system.monthsBetween(month, _focusedMonth) == 0,
          // "this month", in whichever calendar is counting.
          marked:
              _system.monthsBetween(month, _system.firstOfMonth(today)) == 0,
          enabled: enabled,
          style: _style,
          onTap: () async {
            // A month-grained calendar is DONE here — drilling into the
            // days would be asking for something it was told not to ask
            // for.
            if (widget.grain == CalendarGrain.month) {
              setState(() => _focusedMonth = month);
              widget.onMonthChanged?.call(month);
              _selectedStart = month;
              _selectedEnd = month;
              widget.onChanged?.call(
                DateTimeRange(start: month, end: month),
              );
              return;
            }
            setState(() {
              _focusedMonth = month;
              _view = _CalendarView.days;
            });
            widget.onMonthChanged?.call(month);
            // The PageView is rebuilt by the view switch, so the jump
            // waits for it to exist.
            await WidgetsBinding.instance.endOfFrame;
            if (mounted) _jumpToFocusedMonth();
          },
        );
      },
    );
  }

  Widget _buildYearGrid(BuildContext context, DateTime today) {
    final firstYear = _system.yearOf(_first);
    final totalYears = _system.yearOf(_last) - firstYear + 1;

    // Created ONCE and scrolled afterwards. The old version disposed and
    // rebuilt the controller inside `build`, which throws the moment a
    // rebuild lands on an attached one.
    _yearGridController ??= ScrollController();
    final target =
        ((_system.yearOf(_focusedMonth) - firstYear) ~/
            DateTimePickerDefaults.gridColumns) *
        DateTimePickerDefaults.yearRowExtent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = _yearGridController;
      if (!mounted || c == null || !c.hasClients) return;
      final clamped = target.clamp(0.0, c.position.maxScrollExtent);
      if ((c.offset - clamped).abs() > 1) c.jumpTo(clamped);
    });

    return _buildOptionGrid(
      key: const ValueKey('yearView'),
      count: totalYears,
      controller: _yearGridController!,
      itemBuilder: (context, index) {
        final year = firstYear + index;
        return _GridCell(
          label: AppNumbers.padded(year, width: 4),
          semanticLabel: AppNumbers.padded(year, width: 4),
          selected: _system.yearOf(_focusedMonth) == year,
          marked: _system.yearOf(today) == year,
          enabled: widget.enabled,
          style: _style,
          onTap: () {
            final anchor = _system
                .anchorFor(year, _monthNumberOf(_focusedMonth))
                .clampTo(_firstMonth, _lastMonth);
            if (widget.grain == CalendarGrain.year) {
              setState(() => _focusedMonth = anchor);
              _selectedStart = anchor;
              _selectedEnd = anchor;
              widget.onChanged?.call(
                DateTimeRange(start: anchor, end: anchor),
              );
              return;
            }
            setState(() {
              _focusedMonth = anchor;
              _view = _CalendarView.months;
            });
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Grid cell — one month or one year
// ---------------------------------------------------------------------------

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.marked,
    required this.enabled,
    required this.style,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;

  /// The current month / year, when it is not the focused one.
  final bool marked;
  final bool enabled;
  final ResolvedDateTimePickerStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? style.selectedDayColor : Colors.transparent,
              borderRadius: BorderRadius.circular(style.gridCellRadius),
              border: marked && !selected
                  ? Border.all(
                      color: style.todayBorderColor,
                      width: style.todayBorderWidth,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected || marked
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: !enabled
                      ? style.dayTextColor.withValues(
                          alpha: style.disabledDayOpacity,
                        )
                      : selected
                      ? style.selectedDayTextColor
                      : marked
                      ? style.todayTextColor
                      : style.dayTextColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edge hint — the page-turn strip shown while sweeping
// ---------------------------------------------------------------------------

class _EdgeHint extends StatelessWidget {
  const _EdgeHint({
    required this.leading,
    required this.color,
    required this.radius,
  });

  final bool leading;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tint = color.withValues(alpha: 0.25);

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.centerStart,
            end: AlignmentDirectional.centerEnd,
            colors: leading
                ? [tint, Colors.transparent]
                : [Colors.transparent, tint],
          ),
          borderRadius: BorderRadiusDirectional.horizontal(
            start: leading ? Radius.circular(radius) : Radius.zero,
            end: leading ? Radius.zero : Radius.circular(radius),
          ),
        ),
        child: Center(
          child: Icon(
            // Mirrors itself in Arabic — see the header's arrows.
            leading ? Icons.chevron_left : Icons.chevron_right,
            color: color.withValues(alpha: 0.6),
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FadeEdges — a soft edge on a scrolled or paged surface
// ---------------------------------------------------------------------------

/// Fades [size] points at both ends of [axis].
///
/// A hard edge on a paged month says the neighbour stops there; a
/// faded one says it carries on. `dstIn` makes the pixels genuinely
/// transparent, so it works over any background rather than only over
/// the one it was told about.
class _FadeEdges extends StatelessWidget {
  const _FadeEdges({
    required this.child,
    required this.axis,
    required this.size,
  });

  final Widget child;
  final Axis axis;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (size <= 0) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = axis == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        if (!extent.isFinite || extent <= size * 2) return child;

        final stop = (size / extent).clamp(0.0, 0.5);
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: axis == Axis.horizontal
                ? Alignment.centerLeft
                : Alignment.topCenter,
            end: axis == Axis.horizontal
                ? Alignment.centerRight
                : Alignment.bottomCenter,
            colors: const [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0, stop, 1 - stop, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _DimWhenAway — a peeking month is context, not content
// ---------------------------------------------------------------------------

/// Fades a page towards [opacity] as it slides away from the middle.
class _DimWhenAway extends StatelessWidget {
  const _DimWhenAway({
    required this.controller,
    required this.page,
    required this.focusedPage,
    required this.opacity,
    required this.child,
  });

  final PageController controller;
  final int page;

  /// Where the view is, for the frames before the controller can say.
  final int focusedPage;

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, built) {
        // A `PageController` has no `page` until it has been laid out,
        // and nothing notifies afterwards if nothing scrolls — so
        // falling back to THIS page's own index left every neighbour at
        // full strength for as long as the reader did not swipe.
        final current =
            controller.hasClients && controller.position.haveDimensions
            ? controller.page ?? focusedPage.toDouble()
            : focusedPage.toDouble();
        final away = (current - page).abs().clamp(0.0, 1.0);
        return Opacity(opacity: 1 - (1 - opacity) * away, child: built);
      },
      child: child,
    );
  }
}
