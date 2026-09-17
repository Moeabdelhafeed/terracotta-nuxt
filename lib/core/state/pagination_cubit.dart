import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../error/app_exception.dart';
import '../types/paginated_result.dart';
import '../types/result.dart';

/// Sentinel for [PaginationState.copyWith] so callers can pass
/// `error: null` to clear the field without it being mistaken for
/// "leave alone."
const Object _sentinel = Object();

/// Offset-based pagination state.
@immutable
class PaginationState<T> {
  const PaginationState({
    this.items = const [],
    this.nextPage = 1,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final int nextPage;
  final bool isLoading;
  final bool hasMore;
  final AppException? error;

  PaginationState<T> copyWith({
    List<T>? items,
    int? nextPage,
    bool? isLoading,
    bool? hasMore,
    Object? error = _sentinel,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      nextPage: nextPage ?? this.nextPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _sentinel) ? this.error : error as AppException?,
    );
  }
}

/// Offset-based pagination cubit — replaces `PaginationMixin on
/// GetxController`. Subclass and override [fetchPage]; the cubit
/// handles page counters, accumulating items, the `hasMore` flag,
/// loading guards, and concurrent-call protection.
///
/// ```dart
/// class PostsCubit extends PaginationCubit<Post> {
///   @override
///   int get perPage => 20;
///
///   @override
///   AsyncResult<PaginatedResult<Post>> fetchPage(int page) =>
///     PostsApi.list(page: page, perPage: perPage);
/// }
///
/// // In the widget:
/// BlocProvider(
///   create: (_) => PostsCubit()..loadFirst(),
///   child: BlocBuilder<PostsCubit, PaginationState<Post>>(
///     builder: (context, state) { ... },
///   ),
/// );
/// ```
abstract class PaginationCubit<T> extends Cubit<PaginationState<T>> {
  PaginationCubit() : super(PaginationState<T>());

  /// Default page size. Override as needed.
  int get perPage => 20;

  /// Subclass-provided fetcher. Must return a typed [PaginatedResult]
  /// so the cubit can read [PaginatedResult.meta] for the `hasMore`
  /// check.
  Future<Result<PaginatedResult<T>, AppException>> fetchPage(int page);

  /// Reset state and load the first page.
  Future<void> loadFirst() async {
    emit(PaginationState<T>());
    await loadMore();
  }

  /// Fetch the next page and append. No-ops while one is in flight
  /// or when there are no more pages.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    emit(state.copyWith(isLoading: true));
    final result = await fetchPage(state.nextPage);
    if (isClosed) return;
    result
        .onSuccess((paged) {
          final meta = paged.meta;
          final more = meta != null
              ? meta.currentPage < meta.lastPage
              : paged.items.length >= perPage;
          emit(
            state.copyWith(
              items: [...state.items, ...paged.items],
              nextPage: state.nextPage + 1,
              hasMore: more,
              isLoading: false,
              error: null,
            ),
          );
        })
        .onFailure(
          (e) => emit(state.copyWith(isLoading: false, error: e)),
        );
  }

  /// Drop accumulated items and refetch from page 1.
  Future<void> reload() => loadFirst();
}
