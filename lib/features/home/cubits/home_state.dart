import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/content/home_payload.dart';

/// What the home screen knows.
///
/// Four states rather than a nullable payload with flags beside it: the
/// screen has to draw something different for each, and a bag of
/// booleans lets two of them be true at once.
@immutable
sealed class HomeState {
  const HomeState();
}

/// Before the first request has answered. The screen shows its skeleton.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// The payload, as the server sent it.
final class HomeLoaded extends HomeState {
  const HomeLoaded(this.payload);

  final HomePayload payload;
}

/// The first request failed and there is nothing to show.
///
/// Distinct from a refresh that failed while content was already on
/// screen — see [HomeLoaded], which the cubit keeps rather than
/// replacing a good page with an error because a pull-to-refresh
/// timed out.
final class HomeFailed extends HomeState {
  const HomeFailed(this.error);

  final AppException error;
}
