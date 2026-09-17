import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/content/delivery_zones.dart';
import '../data/guest_addresses.dart';
import 'addresses_state.dart';

/// `GET /api/addresses`.
typedef AddressesFetch =
    AsyncResult<List<Address>> Function({CancelToken? cancelToken});

/// `GET /api/delivery-zones`.
typedef ZonesFetch =
    AsyncResult<DeliveryZones> Function({CancelToken? cancelToken});

/// «عناويني» — the saved addresses.
///
/// `GET /api/addresses` and `GET /api/delivery-zones` together, because
/// they are one screen's worth: the list needs the addresses and the
/// form behind it needs the cities, and a customer who taps «اضف عنوان»
/// should not wait on a second request to see a city picker.
class AddressesCubit extends Cubit<AddressesState> {
  AddressesCubit({
    AddressesFetch? fetch,
    ZonesFetch? zones,
    GuestAddresses? local,
    bool Function()? signedIn,
  }) : _fetch = fetch ?? AddressApis.getAddresses,
       _zones = zones ?? AddressApis.getDeliveryZones,
       _injectedLocal = local,
       _signedIn = signedIn,
       super(const AddressesState());

  /// Injectable so the state machine — and every screen that renders
  /// it — can be tested without a network. Null in the app.
  final AddressesFetch _fetch;
  final ZonesFetch _zones;

  final GuestAddresses? _injectedLocal;
  final bool Function()? _signedIn;

  /// The device's own book, when there is one to fall back on.
  GuestAddresses? get _local =>
      _injectedLocal ??
      (getIt.isRegistered<GuestAddresses>() ? getIt<GuestAddresses>() : null);

  /// Whether the SERVER owns this list.
  ///
  /// Every address route answers 401 without a session, and someone
  /// filling in a delivery address is about to buy something — making
  /// them type it again after signing in is the worst moment to ask.
  /// So a guest's book lives on the device.
  ///
  /// True when there is no device book at all, so a test with an empty
  /// container behaves exactly as it did before any of this existed.
  bool get _remote {
    if (_local == null) return true;
    final signedIn = _signedIn;
    if (signedIn != null) return signedIn();
    return !getIt.isRegistered<AuthBloc>() || getIt<AuthBloc>().isAuthenticated;
  }

  final _cancel = CancelToken();

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    // NO SESSION, NO REQUEST. The device's book is the whole list, and
    // asking the server for it would be a guaranteed 401 dressed as an
    // error screen.
    if (!_remote) {
      final local = _local!;
      emit(
        state.copyWith(
          addresses: local.items,
          loading: false,
          loaded: true,
          clearError: true,
        ),
      );
      await _loadZones();
      return;
    }

    final addresses = await _fetch(cancelToken: _cancel);
    if (isClosed) return;

    switch (addresses) {
      case Success(:final value):
        emit(
          state.copyWith(
            addresses: value,
            loading: false,
            loaded: true,
            clearError: true,
          ),
        );
      case Failure(:final error):
        // A failed REFRESH keeps the list already on screen; only a
        // failed FIRST load is an error screen.
        emit(state.copyWith(loading: false, error: error, loaded: true));
        return;
    }

    await _loadZones();
  }

  /// The zones are the FORM's, so a failure here must not take the list
  /// down with it — the customer can still read and delete what they
  /// have, and the form falls back to the app-wide default fee.
  ///
  /// PUBLIC on the server, so a guest gets them too — which is what
  /// lets a device-only address still carry a real delivery fee.
  Future<void> _loadZones() async {
    if (await _zones(cancelToken: _cancel) case Success(:final value)) {
      if (!isClosed) emit(state.copyWith(zones: value.zones));
    }
  }

  /// Put a freshly saved address into the list without a round trip.
  ///
  /// The server DEMOTES every other address when this one arrives
  /// default, so the local copy has to do the same or two rows would
  /// wear the badge until the next load.
  void remember(Address saved) {
    // A guest's book is the store, so record it there too — otherwise
    // the row is on screen for this run and gone on the next.
    if (!_remote) _local!.save(saved);
    final without = [
      for (final a in state.addresses)
        if (a.id != saved.id)
          saved.isDefault ? a.copyWith(isDefault: false) : a,
    ];
    emit(
      state.copyWith(addresses: [saved, ...without], loaded: true),
    );
  }

  Future<bool> remove(Address address) async {
    if (!_remote) {
      final ok = _local!.remove(address.id);
      if (ok) {
        emit(state.copyWith(addresses: _local!.items));
      }
      return ok;
    }

    emit(state.copyWith(busyIds: {...state.busyIds, address.id}));

    final result = await AddressApis.deleteAddress(
      '${address.id}',
      cancelToken: _cancel,
    );
    if (isClosed) return false;

    final ok = result is Success;
    emit(
      state.copyWith(
        addresses: ok
            ? [
                for (final a in state.addresses)
                  if (a.id != address.id) a,
              ]
            : null,
        busyIds: {...state.busyIds}..remove(address.id),
      ),
    );
    return ok;
  }

  /// Promote one address to default.
  ///
  /// `PUT /api/addresses/{id}` with `is_default` — there is no separate
  /// endpoint, and the server demotes the rest.
  Future<bool> makeDefault(Address address) async {
    if (address.isDefault) return true;

    if (!_remote) {
      final ok = _local!.makeDefault(address.id);
      if (ok) emit(state.copyWith(addresses: _local!.items));
      return ok;
    }

    emit(state.copyWith(busyIds: {...state.busyIds, address.id}));

    // The WHOLE address back, with the one flag flipped. `PUT` takes a
    // full body — there is no partial update and no separate
    // "make default" endpoint, so anything omitted here would be
    // cleared rather than left alone.
    final result = await AddressApis.updateAddress(
      '${address.id}',
      buildingNumber: address.buildingNumber,
      street: address.street,
      district: address.district,
      postalCode: address.postalCode,
      additionalNumber: address.additionalNumber,
      lat: double.parse(address.lat),
      lng: double.parse(address.lng),
      phone: address.phone,
      label: address.label,
      unitNumber: address.unitNumber,
      shortAddress: address.shortAddress,
      deliveryZoneId: address.deliveryZoneId,
      notes: address.notes,
      isDefault: true,
      cancelToken: _cancel,
    );
    if (isClosed) return false;

    switch (result) {
      case Success(:final value):
        remember(value);
        emit(state.copyWith(busyIds: {...state.busyIds}..remove(address.id)));
        return true;
      case Failure():
        emit(state.copyWith(busyIds: {...state.busyIds}..remove(address.id)));
        return false;
    }
  }

  @override
  Future<void> close() {
    _cancel.cancel('addresses closed');
    return super.close();
  }
}
