// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_meta.freezed.dart';
part 'pagination_meta.g.dart';

/// Pagination metadata returned by list endpoints — matches the
/// common JSON:API / Laravel pagination envelope shape.
///
/// Paired with [PaginationLinks] inside `PaginatedResult<T>` in
/// `core/types/paginated_result.dart`.
///
/// Required (always present on a paginated response):
/// - [currentPage] — 1-indexed page number of the current batch.
/// - [lastPage] — total number of pages; final page inclusive.
/// - [total] — total number of items across all pages.
///
/// Optional:
/// - [perPage] — defaults to 20 when absent (standard page size).
/// - [from] / [to] — 1-indexed item range for the current page
///   (e.g. items 21-40 of 200).
@freezed
abstract class PaginationMeta with _$PaginationMeta {
  const factory PaginationMeta({
    required int currentPage,
    required int lastPage,
    required int total,
    @Default(20) int perPage,
    int? from,
    int? to,
  }) = _PaginationMeta;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetaFromJson(json);
}
