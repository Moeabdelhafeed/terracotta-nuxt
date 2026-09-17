import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';

/// What the workshops tab knows. Same three states as the other tabs.
@immutable
sealed class WorkshopsState {
  const WorkshopsState();
}

final class WorkshopsLoading extends WorkshopsState {
  const WorkshopsLoading();
}

final class WorkshopsLoaded extends WorkshopsState {
  const WorkshopsLoaded(this.workshops);

  final List<Workshop> workshops;
}

final class WorkshopsFailed extends WorkshopsState {
  const WorkshopsFailed(this.error);

  final AppException error;
}
