// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pagination_links.freezed.dart';
part 'pagination_links.g.dart';

/// Page-navigation URLs for a paginated list — the `links` object of
/// a standard JSON:API / Laravel paginated response.
///
/// All fields are nullable by design:
/// - [prev] is null on the first page.
/// - [next] is null on the last page.
/// - [first] / [last] can be null if the endpoint doesn't expose
///   direct jumps (rare, but happens).
///
/// Paired with [PaginationMeta] inside `PaginatedResult<T>`.
@freezed
abstract class PaginationLinks with _$PaginationLinks {
  const factory PaginationLinks({
    String? first,
    String? last,
    String? prev,
    String? next,
  }) = _PaginationLinks;

  factory PaginationLinks.fromJson(Map<String, dynamic> json) =>
      _$PaginationLinksFromJson(json);
}
