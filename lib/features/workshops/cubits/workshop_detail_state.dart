import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/workshop/workshop_detail.dart';

/// What one opened workshop knows.
@immutable
sealed class WorkshopDetailState {
  const WorkshopDetailState();
}

final class WorkshopDetailLoading extends WorkshopDetailState {
  const WorkshopDetailLoading();
}

final class WorkshopDetailLoaded extends WorkshopDetailState {
  const WorkshopDetailLoaded(this.workshop);

  final WorkshopDetail workshop;
}

final class WorkshopDetailFailed extends WorkshopDetailState {
  const WorkshopDetailFailed(this.error);

  final AppException error;
}
