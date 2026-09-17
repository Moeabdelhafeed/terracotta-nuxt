// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_image.freezed.dart';
part 'api_image.g.dart';

/// A CMS-hosted image, as the Terracotta API embeds it.
///
/// This is the single most repeated shape in the API — it is nested
/// inside almost every payload that shows anything: `/api/app-settings`
/// (every link's icon), `/api/home` (banners, sections, categories),
/// `/api/shop/products` + `/api/shop/cart` (product thumbnails),
/// `/api/workshops` (workshop covers), `/api/gallery`, `/api/media`.
/// Model it once here and embed it; never redeclare the five fields.
///
/// **TRAP — [url] is RELATIVE and will 404 if you render it.** The API
/// sends `"demo/shop/products/abbasi-cups-1-1-0.png"`, a storage-relative
/// path with no scheme and no host. Handing that to `Image.network` or a
/// `CachedNetworkImage` fails. [imageApi] is the absolute URL
/// (`https://dev-cms.terracotta-ksa.com/storage/demo/...`) and is the
/// only one the UI may paint. Use [display], which picks the right one.
///
/// [blurhash] is the BlurHash placeholder string
/// (`"LDRVRo%L_N-p-pj[M|ay%Mj[IUay"`). The design is image-heavy, so this
/// is what fills the frame while the real bytes download — decode it with
/// a BlurHash widget rather than showing a grey box.
///
/// [type] is the file extension (`"png"`, `"jpg"`), not a MIME type and
/// not a media kind.
///
/// Nullability: every capture of this shape (82 occurrences across the
/// live samples) carries all five keys non-null, so they are required —
/// except [imageApi], typed nullable on purpose so a CMS row that has not
/// finished processing degrades to the relative path via [display]
/// instead of throwing at parse time.
@freezed
abstract class ApiImage with _$ApiImage {
  const factory ApiImage({
    required int id,
    required String url,
    required String type,
    required String blurhash,
    String? imageApi,
  }) = _ApiImage;

  const ApiImage._();

  factory ApiImage.fromJson(Map<String, dynamic> json) =>
      _$ApiImageFromJson(json);

  /// The URL to actually render. [imageApi] when the API sent one,
  /// falling back to the relative [url] otherwise.
  ///
  /// Always read images through this — never through [url] directly.
  String get display => imageApi ?? url;
}
