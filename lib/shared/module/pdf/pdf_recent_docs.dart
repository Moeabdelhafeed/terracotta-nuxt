import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/strings/pdf_strings.dart';
import '../../../data/blocs/pdf_bookmarks/pdf_bookmarks_cubit.dart';
import '../../../data/blocs/pdf_bookmarks/pdf_bookmarks_state.dart';
import '../buttons/global_icon_button.dart';
import '../container/global_container.dart';
import '../divider/global_divider.dart';

/// "Continue reading" list — every document the user has opened (we
/// track them by writing `lastReadPage` from [GlobalPdfViewer]).
///
/// Doesn't open the document itself — the caller wires [onTap] to
/// push their own viewer route. Source identity is the same
/// `persistKey` ([PdfSourceSpec.cacheKey] or the source value) used
/// elsewhere in the module, so the caller can rebuild a
/// [PdfSourceSpec] from it.
///
/// Pass [bookmarksCubit] explicitly. Modules don't reach into DI —
/// callers resolve `getIt<PdfBookmarksCubit>()` (or any other source)
/// at the call site and inject.
class PdfRecentDocsList extends StatelessWidget {
  const PdfRecentDocsList({
    super.key,
    required this.bookmarksCubit,
    required this.onTap,
    this.emptyPlaceholder,
    this.shrinkWrap = false,
    this.physics,
  });

  /// Source of the recent-doc state. Caller injects.
  final PdfBookmarksCubit bookmarksCubit;

  /// `(key, lastReadPage)` — caller rebuilds a source spec from the
  /// key. Pages indexes are 1-based.
  final void Function(String key, int lastReadPage) onTap;

  /// Shown when there are no recent docs.
  final Widget? emptyPlaceholder;

  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PdfBookmarksCubit, PdfBookmarksState>(
      bloc: bookmarksCubit,
      builder: (context, state) {
        final entries = state.lastReadPage.entries.toList();
        if (entries.isEmpty) {
          return emptyPlaceholder ??
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: Text(PdfStrings.noRecentDocuments)),
              );
        }
        // Its own Material. A caller drops this list into a card — the
        // showcase does exactly that — and a `DecoratedBox` with a
        // background between a `ListTile` and the nearest Material
        // swallows the tile's ink and its own background colour.
        // Flutter warns about it; the two other lists in this module
        // already carry one.
        return Material(
          type: MaterialType.transparency,
          child: ListView.separated(
            shrinkWrap: shrinkWrap,
            physics: physics,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const GlobalDivider(),
            itemBuilder: (context, i) {
              final e = entries[i];
              final bookmarks = state.pages[e.key] ?? const [];
              return GlobalContainer.tile(
                leading: const Icon(Icons.picture_as_pdf_rounded),
                titleWidget: Text(
                  _shortName(e.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitleWidget: Text(
                  PdfStrings.pageNumber(e.value) +
                      (bookmarks.isEmpty
                          ? ''
                          : ' · ${PdfStrings.bookmarkCount(bookmarks.length)}'),
                ),
                trailing: GlobalIconButton(
                  iconData: Icons.delete_outline_rounded,
                  tooltip: PdfStrings.forget,
                  onPressed: () => bookmarksCubit.clearFor(e.key),
                ),
                onTap: () => onTap(e.key, e.value),
              );
            },
          ),
        );
      },
    );
  }

  String _shortName(String key) {
    // Strip URL query / path → last segment. Falls back to the raw
    // key when it's a bytes label or non-URL identifier.
    final uri = Uri.tryParse(key);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final slash = key.lastIndexOf(RegExp(r'[/\\]'));
    if (slash >= 0 && slash < key.length - 1) return key.substring(slash + 1);
    return key;
  }
}
