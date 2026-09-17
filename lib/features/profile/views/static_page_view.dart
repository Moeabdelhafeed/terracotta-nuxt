import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/page_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/html/global_html.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../cubits/pages_cubit.dart';

/// One of the studio's own pages — terms, privacy, returns, shipping,
/// about.
///
/// Addressed by SLUG, because that is what the CMS row is keyed by and
/// what a link from anywhere else in the app can name without knowing a
/// database id. The five live slugs are in [PagesCubit].
///
/// ## No second request
///
/// `GET /api/pages` carries every page's HTML, so this reads the list
/// the app already has rather than fetching one page again. That is
/// also what lets the register screen link the terms without a spinner
/// between the tap and the words.
class StaticPageView extends StatefulWidget {
  const StaticPageView({required this.slug, this.cubit, super.key});

  final String slug;

  /// A cubit to use instead of the app's — the seam a widget test
  /// needs. Null in the app, which uses the shared singleton.
  final PagesCubit? cubit;

  @override
  State<StaticPageView> createState() => _StaticPageViewState();
}

class _StaticPageViewState extends State<StaticPageView> {
  late final _pages = widget.cubit ?? getIt<PagesCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale-scoped: the words are the server's, in the language the
    // request asked for.
    unawaited(
      _pages.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return BlocBuilder<PagesCubit, PagesState>(
      bloc: _pages,
      builder: (context, state) {
        final page = _pages.bySlug(widget.slug);

        return Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          // The page's OWN name from the CMS, falling back to the slug's
          // house title while it loads — a bar that says nothing for a
          // second reads as a screen that failed to open.
          appBar: TerracottaPageBar(
            title: page?.name ?? PageStrings.title(widget.slug),
          ),
          body: GlobalRefreshable(
            onRefresh: () => _pages.refreshIn(
              Localizations.localeOf(context).languageCode,
            ),
            child: GlobalScrollable(
              // The CALLER has to ask, or a page shorter than the
              // viewport drops the drag recogniser — and the page that
              // most needs pulling is the empty or failed one.
              physics: const AlwaysScrollableScrollPhysics(),
              child: GlobalContainer.prose(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.md,
                  spacing.md,
                  spacing.md,
                  spacing.xxl,
                ),
                child: switch ((page, state)) {
                  // THE STUDIO'S OWN HEADER PICTURE, when it set one.
                  //
                  // `image` is nullable and was null on all five pages
                  // when they were first captured, which is why this
                  // screen was built for text alone. The CMS has since
                  // started filling it in (privacy carries one today),
                  // and a picture the studio uploaded for a page ought
                  // to be ON the page.
                  //
                  // A fixed 16:9 band rather than the image's own
                  // aspect: the pages are edited by hand and a tall
                  // upload would otherwise push the whole document
                  // below the fold.
                  (final p?, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (p.image case final hero?) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            context.radii.md,
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: TerracottaImage(image: hero),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                      ],
                      GlobalHtml(data: p.content),
                    ],
                  ),
                  (null, PagesState(loaded: false)) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 120),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  // LOADED and still not here: either the request
                  // failed, or the studio has not written this one.
                  // Different sentences, because they are different
                  // facts.
                  (null, PagesState(error: final e?)) => ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 360),
                    child: Center(
                      child: GlobalEmptyState(
                        icon: Icons.wifi_off_rounded,
                        title: AuthStrings.errorGeneric,
                        subtitle: e.message,
                      ),
                    ),
                  ),
                  (null, _) => ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 360),
                    child: Center(
                      child: GlobalEmptyState(
                        icon: Icons.article_outlined,
                        title: PageStrings.missing,
                        subtitle: PageStrings.missingBody,
                      ),
                    ),
                  ),
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
