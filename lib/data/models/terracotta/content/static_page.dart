// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';

part 'static_page.freezed.dart';
part 'static_page.g.dart';

/// A CMS-authored legal / informational page. **One shape, two
/// endpoints:** every element of `GET /api/pages` and the single object
/// from `GET /api/pages/{slug}` are byte-identical — the list endpoint
/// already carries the full [content], so the detail call is redundant
/// for anything the list has already fetched.
///
/// The live capture holds five: `terms`, `privacy`, `returns`,
/// `shipping`, `about`.
///
/// **[content] IS HTML, not plain text.** It arrives wrapped in `<p>`
/// tags. Rendering it in a `Text` widget prints the markup to the user;
/// render it through an HTML widget, or strip the tags deliberately.
///
/// [slug] — not [id] — is what `GET /api/pages/{slug}` takes and what a
/// deep link or a home banner with `link_type: "page"` should be routed
/// on. Treat [id] as the CMS row key only. (Note the banner's
/// `link_target_id` is an int id, so routing from a banner means
/// resolving id → slug against the list.)
///
/// [image] is a header illustration and is **null for all five captured
/// pages** — design the page for text alone and treat the image as a
/// bonus.
@freezed
abstract class StaticPage with _$StaticPage {
  const factory StaticPage({
    /// CMS row key. Home banners reference pages by this via
    /// `link_target_id`.
    required int id,

    /// URL key — `"terms"`, `"privacy"`. The routing identity.
    required String slug,

    /// Display title, already localized by the CMS.
    required String name,

    /// **HTML body.** Never render with `Text`.
    required String content,

    /// Header illustration. **Null for every captured page.**
    ApiImage? image,
  }) = _StaticPage;

  factory StaticPage.fromJson(Map<String, dynamic> json) =>
      _$StaticPageFromJson(json);
}
