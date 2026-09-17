import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/content/delivery_zone.dart';

/// «عناويني» — the saved addresses, and the cities they can be in.
@immutable
class AddressesState {
  const AddressesState({
    this.addresses = const [],
    this.zones = const [],
    this.loading = false,
    this.busyIds = const {},
    this.error,
    this.loaded = false,
  });

  final List<Address> addresses;

  /// The delivery zones, fetched once with the list.
  ///
  /// Needed by the FORM, not the list — but a customer who opens «اضف
  /// عنوان» should not wait on a second request to see the city
  /// picker, and the two are one screen's worth of data.
  final List<DeliveryZone> zones;

  final bool loading;

  /// Addresses with a write in flight — a delete, or a promotion to
  /// default. Per-row, so one slow request does not freeze the list.
  final Set<int> busyIds;

  final AppException? error;

  /// Whether a load has ever finished. Separates "nothing yet" from
  /// "nothing at all", which are different screens.
  final bool loaded;

  bool get isEmpty => loaded && addresses.isEmpty;

  /// The one the checkout will pick by default, if there is one.
  Address? get defaultAddress {
    for (final a in addresses) {
      if (a.isDefault) return a;
    }
    return null;
  }

  AddressesState copyWith({
    List<Address>? addresses,
    List<DeliveryZone>? zones,
    bool? loading,
    Set<int>? busyIds,
    AppException? error,
    bool clearError = false,
    bool? loaded,
  }) => AddressesState(
    addresses: addresses ?? this.addresses,
    zones: zones ?? this.zones,
    loading: loading ?? this.loading,
    busyIds: busyIds ?? this.busyIds,
    error: clearError ? null : (error ?? this.error),
    loaded: loaded ?? this.loaded,
  );
}
