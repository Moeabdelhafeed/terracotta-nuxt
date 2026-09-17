import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/api/calls/inbox_apis.dart';
import '../../../data/api/calls/shop_apis.dart';

/// A call that answers with a list of the caller's own things.
typedef CountFetch =
    Future<Result<List<Object?>, Object>> Function({CancelToken? cancelToken});

/// HOW MANY of each, for the numbers beside the account rows.
///
/// ## Why a cubit of its own
///
/// «مفضلتي ٥» is the row saying what is behind it before it is opened,
/// and every one of those numbers lives on a different endpoint —
/// favourites on the shop, addresses on the account, orders on the
/// shop, complaints on the inbox. Nothing on the profile page needed
/// any of them until the rows started printing them, and none of the
/// pages behind the rows can supply one without being opened.
///
/// The four calls go out TOGETHER and each one lands on its own: a
/// count is decoration on a row that works without it, so a failure
/// leaves that number absent and says nothing. There is no error state
/// here on purpose.
///
/// ## Signed in only
///
/// All four answer 401 without a session — and a 401 is the session
/// ending, which would evict a guest browsing the profile tab. The
/// page gates the call; [clear] is what a sign-out leaves behind.
///
/// ## A `getIt` singleton
///
/// Same reason as every other tab cubit: the profile is a top-level
/// route and `context.go` tears its `State` down, so a page-owned
/// cubit would re-ask on every visit to the tab. The page must not
/// close it.
@immutable
class ProfileCountsState {
  const ProfileCountsState({
    this.favorites,
    this.addresses,
    this.orders,
    this.complaints,
  });

  /// Null means UNKNOWN — not yet asked, or the call failed. Zero is a
  /// real answer and the row prints it, because "0 orders" is
  /// information and a blank row is not.
  final int? favorites;
  final int? addresses;
  final int? orders;
  final int? complaints;

  ProfileCountsState copyWith({
    int? favorites,
    int? addresses,
    int? orders,
    int? complaints,
  }) => ProfileCountsState(
    favorites: favorites ?? this.favorites,
    addresses: addresses ?? this.addresses,
    orders: orders ?? this.orders,
    complaints: complaints ?? this.complaints,
  );
}

class ProfileCountsCubit extends Cubit<ProfileCountsState> {
  ProfileCountsCubit({
    CountFetch? favorites,
    CountFetch? addresses,
    CountFetch? orders,
    CountFetch? complaints,
  }) : _favorites = favorites ?? _defaultFavorites,
       _addresses = addresses ?? _defaultAddresses,
       _orders = orders ?? _defaultOrders,
       _complaints = complaints ?? _defaultComplaints,
       super(const ProfileCountsState());

  final CountFetch _favorites;
  final CountFetch _addresses;
  final CountFetch _orders;
  final CountFetch _complaints;
  final _cancel = CancelToken();

  static Future<Result<List<Object?>, Object>> _defaultFavorites({
    CancelToken? cancelToken,
  }) async => switch (await ShopApis.getFavorites(cancelToken: cancelToken)) {
    Success(:final value) => Success(value),
    Failure(:final error) => Failure(error),
  };

  static Future<Result<List<Object?>, Object>> _defaultAddresses({
    CancelToken? cancelToken,
  }) async =>
      switch (await AddressApis.getAddresses(cancelToken: cancelToken)) {
        Success(:final value) => Success(value),
        Failure(:final error) => Failure(error),
      };

  static Future<Result<List<Object?>, Object>> _defaultOrders({
    CancelToken? cancelToken,
  }) async => switch (await ShopApis.getOrders(cancelToken: cancelToken)) {
    Success(:final value) => Success(value),
    Failure(:final error) => Failure(error),
  };

  static Future<Result<List<Object?>, Object>> _defaultComplaints({
    CancelToken? cancelToken,
  }) async => switch (await InboxApis.getComplaints(cancelToken: cancelToken)) {
    Success(:final value) => Success(value),
    Failure(:final error) => Failure(error),
  };

  /// Whether an answer has ever arrived. Zero of everything is still an
  /// answer, so this is not "is any count non-null and positive".
  bool get hasData => _answered;
  bool _answered = false;

  /// Ask once. A second visit to the tab keeps what is already here.
  Future<void> ensureLoaded() => _answered ? Future.value() : load();

  /// Ask again — a pull, or the account changing.
  Future<void> load() async {
    // TOGETHER, not one after another: four sequential round trips is
    // four times the wait for numbers the reader is already looking
    // at.
    final results = await Future.wait([
      _favorites(cancelToken: _cancel),
      _addresses(cancelToken: _cancel),
      _orders(cancelToken: _cancel),
      _complaints(cancelToken: _cancel),
    ]);
    if (isClosed) return;

    int? count(int i) => switch (results[i]) {
      Success(:final value) => value.length,
      Failure() => null,
    };

    _answered = true;
    emit(
      ProfileCountsState(
        favorites: count(0),
        addresses: count(1),
        orders: count(2),
        complaints: count(3),
      ),
    );
  }

  /// Signed out: nothing to count, and nothing to keep from whoever
  /// was signed in before.
  void clear() {
    _answered = false;
    emit(const ProfileCountsState());
  }

  @override
  Future<void> close() {
    _cancel.cancel('profile counts closed');
    return super.close();
  }
}
