import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/device/system/launcher_utils.dart';
import '../../../data/models/terracotta/content/home_banner.dart';
import '../../../data/models/terracotta/content/home_link_type.dart';
import '../../shop/views/product_list_page.dart';

/// Where a home banner sends the reader.
///
/// The CMS names the destination in `link_type`, and which companion
/// field carries it depends on the value — `link_target_id` for the
/// row-level types, `link` for the external one, nothing at all for the
/// section-level ones. [HomeLinkType] documents the mapping; this is
/// the app's half of it.
///
/// **Not every type this build parses can be reached.** Two cannot, and
/// both are answered by refusing the tap rather than by opening
/// something that is not what the banner promised:
///
///   * `page` hands over an **int id** while `GET /api/pages/{slug}`
///     wants a **slug**, and there is no route that resolves one
///     against the other. A banner pointing at a CMS page is dead
///     copy today.
///   * `workshop` names a single workshop, and there is no
///     `/workshops/:id` — the catalogue is an accordion that expands
///     in place. Rather than drop the reader on the list and let them
///     hunt, it goes to the list DELIBERATELY, which is the nearest
///     honest destination and is why it is listed as routable.
///
/// An unrecognised `link_type` already parses as [HomeLinkType.none],
/// so a banner whose destination this build predates goes quiet
/// instead of offering a control that does nothing.
bool bannerIsTappable(HomeBanner banner) => switch (banner.linkType) {
  HomeLinkType.none => false,

  // An int id where the route wants a slug. Nothing to open.
  HomeLinkType.page => false,

  // The URL is the destination, and a banner without one is not a
  // link however the CMS typed it.
  HomeLinkType.externalUrl => (banner.link ?? '').trim().isNotEmpty,

  // These name a ROW, and without its id there is no row.
  HomeLinkType.shopCategory ||
  HomeLinkType.shopProduct ||
  HomeLinkType.galleryCategory => banner.linkTargetId != null,

  // Section-level: the destination is the section itself.
  HomeLinkType.shopHome ||
  HomeLinkType.workshops ||
  HomeLinkType.workshop ||
  HomeLinkType.galleryHome => true,
};

/// Follow the banner. Does nothing when it is not tappable.
///
/// Answers whether it went, so a caller with its own follow-up does not
/// have to guess.
Future<bool> openBanner(BuildContext context, HomeBanner banner) async {
  if (!bannerIsTappable(banner)) return false;
  final target = banner.linkTargetId;

  switch (banner.linkType) {
    case HomeLinkType.shopHome:
      unawaited(context.pushNamed('shop'));

    case HomeLinkType.shopCategory:
      // The browse screen opened on a CATEGORY rather than on one of
      // its sub-categories — the same shape the home rails' "see all"
      // uses, with `0` standing for "no sub-category chosen".
      unawaited(
        context.pushNamed(
          'product-list',
          pathParameters: {'subCategoryId': '0'},
          extra: ProductBrowseArgs(categoryId: target),
        ),
      );

    case HomeLinkType.shopProduct:
      unawaited(
        context.pushNamed(
          'product-detail',
          pathParameters: {'productId': '$target'},
        ),
      );

    // Both land on the catalogue: there is no `/workshops/:id`, because
    // the design draws the list as an accordion that expands in place.
    case HomeLinkType.workshops || HomeLinkType.workshop:
      unawaited(context.pushNamed('workshops'));

    // Albums open as a SHEET on the gallery rather than as a route, so
    // a specific one cannot be addressed from here. The gallery is the
    // nearest thing the banner actually promised.
    case HomeLinkType.galleryHome || HomeLinkType.galleryCategory:
      unawaited(context.pushNamed('gallery'));

    case HomeLinkType.externalUrl:
      // OFF-APP, and it leaves the studio's own surface — handed to the
      // platform rather than opened in a web view we would then have to
      // make safe.
      return LauncherUtils.openUrl(banner.link!.trim());

    // Refused above; listed so a new value cannot be added to the enum
    // without this switch failing to compile.
    case HomeLinkType.none || HomeLinkType.page:
      return false;
  }
  return true;
}
