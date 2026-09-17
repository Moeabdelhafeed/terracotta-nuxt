import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/workshop/workshop_slot.dart';

/// «اختر موعد» — party size, then date, then slot.
///
/// Each step NARROWS the next, which is the whole shape of this screen:
/// the party size decides which dates can take it, and the date decides
/// which sessions exist.
@immutable
class BookingScheduleState {
  const BookingScheduleState({
    this.people = 1,
    this.maxPeople = 1,
    this.blockedDates = const {},
    this.date,
    this.slots = const [],
    this.selectedSlotId,
    this.loadingCalendar = true,
    this.loadingSlots = false,
    this.error,
  });

  /// How many are coming.
  final int people;

  /// The largest party this workshop can take TODAY.
  ///
  /// The lower of the workshop's own `max_people_per_booking` and the
  /// calendar's `max_available_seats` — a workshop that seats eight
  /// with three left offers one, two and three, and nothing else. The
  /// design draws a strip of numbers; this is what decides how many of
  /// them exist.
  final int maxPeople;

  /// `Y-m-d` strings the server will not take, for a party of [people].
  final Set<String> blockedDates;

  /// The chosen day, `Y-m-d`. Null until one is picked.
  final String? date;

  final List<WorkshopSlot> slots;
  final int? selectedSlotId;

  final bool loadingCalendar;
  final bool loadingSlots;
  final AppException? error;

  /// The party sizes to offer: one to [maxPeople].
  List<int> get partySizes => [for (var i = 1; i <= maxPeople; i++) i];

  /// Whether the CTA can fire.
  bool get canContinue => selectedSlotId != null;

  BookingScheduleState copyWith({
    int? people,
    int? maxPeople,
    Set<String>? blockedDates,
    String? date,
    List<WorkshopSlot>? slots,
    int? selectedSlotId,
    bool clearSlot = false,
    bool? loadingCalendar,
    bool? loadingSlots,
    AppException? error,
    bool clearError = false,
  }) => BookingScheduleState(
    people: people ?? this.people,
    maxPeople: maxPeople ?? this.maxPeople,
    blockedDates: blockedDates ?? this.blockedDates,
    date: date ?? this.date,
    slots: slots ?? this.slots,
    selectedSlotId: clearSlot ? null : selectedSlotId ?? this.selectedSlotId,
    loadingCalendar: loadingCalendar ?? this.loadingCalendar,
    loadingSlots: loadingSlots ?? this.loadingSlots,
    error: clearError ? null : error ?? this.error,
  );
}
