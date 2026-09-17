import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/terracotta/content/app_settings.dart';
import '../../models/terracotta/content/discount_code.dart';
import '../../models/terracotta/content/home_payload.dart';
import '../../models/terracotta/content/language.dart';
import '../../models/terracotta/content/media_library.dart';
import '../../models/terracotta/content/static_page.dart';
import '../../models/terracotta/content/translation_bundle.dart';
import '../../models/terracotta/gallery/gallery_album.dart';
import '../../models/terracotta/gallery/gallery_album_detail.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Content API calls — translations, managed media, home, gallery,
/// static pages, app settings, languages and discount-code validation.
///
/// Everything here is PUBLIC except [validateDiscountCode], which
/// prices against the caller's own cart / booking and needs a token.
///
/// House rules that touch this group:
/// - **Money is a decimal STRING** (`"65.00"`), never a number. Never
///   round-trip it through `double`.
/// - **VAT is INCLUSIVE** — `vat_amount` is already contained in
///   `total_price`; never add the two together.
/// - **A discount code never reduces the delivery fee** — only the
///   goods total moves.
/// - **Workshop times come back in Asia/Riyadh** already; the
///   `current_booking` block on [getHome] is no exception. Never
///   convert those client-side.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site. Nothing here throws.
class ContentApis {
  ContentApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetTranslations = kApiLogVerbose;
  static ApiLogConfig logUpsertTranslations = kApiLogVerbose;
  static ApiLogConfig logDeleteTranslationKey = kApiLogVerbose;
  static ApiLogConfig logGetMedia = kApiLogVerbose;
  static ApiLogConfig logUploadMedia = kApiLogVerbose;
  static ApiLogConfig logDeleteMedia = kApiLogVerbose;
  static ApiLogConfig logGetHome = kApiLogVerbose;
  static ApiLogConfig logGetGalleryCategories = kApiLogVerbose;
  static ApiLogConfig logGetGalleryCategory = kApiLogVerbose;
  static ApiLogConfig logGetPages = kApiLogVerbose;
  static ApiLogConfig logGetPage = kApiLogVerbose;
  static ApiLogConfig logGetAppSettings = kApiLogVerbose;
  static ApiLogConfig logGetLanguages = kApiLogVerbose;
  static ApiLogConfig logValidateDiscountCode = kApiLogVerbose;
  static ApiLogConfig logGetDiscountCodes = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for the GET endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.translations,
      type: RequestType.get,
      data: {
        'group': 'app',
        'locale': 'en',
        'translations': {
          'general': {'welcome': 'Welcome'},
          'auth': {'login_title': 'Login'},
        },
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.media,
      type: RequestType.get,
      data: {
        'group': 'app',
        'media': {
          'onboarding': {
            'slide_one': {
              'id': 3,
              'url': 'onboarding/slide-one.webp',
              'type': 'webp',
              'image_api': 'https://example.com/onboarding/slide-one.webp',
            },
          },
        },
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.home,
      type: RequestType.get,
      data: {
        'banners': [
          {
            'id': 1,
            'label': 'New Collection',
            'title': 'Touches of Nature',
            'cta_text': 'Shop Now',
            'link_type': 'shop_category',
            'link_target_id': 3,
            'link': null,
            'image': _mockImage,
          },
        ],
        'categories': [
          {'id': 1, 'title': 'Cups', 'image': _mockImage},
        ],
        'current_booking': {
          'id': 10,
          'workshop_title': 'Make Your Own Cup',
          'booking_date': '2026-07-04',
          // Asia/Riyadh already — do not shift.
          'start_time': '13:00',
          'end_time': '15:00',
          'people_count': 2,
          'has_celebration': true,
          'total_price': '95.00',
          'status': 'confirmed',
        },
        'featured_products': [
          {
            'id': 1,
            'title': 'Terracotta Cup',
            'price': '65.00',
            'sale_price': null,
            'image': _mockImage,
            'is_featured': true,
            'is_favorited': false,
          },
        ],
        'offers': [
          {
            'id': 2,
            'title': 'Terracotta Vase',
            'price': '65.00',
            'sale_price': '50.00',
            'image': _mockImage,
            'is_featured': false,
            'is_favorited': true,
          },
        ],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.gallery,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'title': 'April Workshop',
          'cover': _mockImage,
          'images_count': 10,
          'videos_count': 11,
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.galleryCategory('1'),
      type: RequestType.get,
      data: {
        'id': 1,
        'title': 'April Workshop',
        'images_count': 10,
        'videos_count': 11,
        'items': [
          {'id': 1, 'type': 'image', 'image': _mockImage},
        ],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.pages,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'slug': 'about-us',
          'name': 'About Us',
          'content': '<p>We are a company that...</p>',
          'image': _mockImage,
        },
        {
          'id': 2,
          'slug': 'privacy-policy',
          'name': 'Privacy Policy',
          'content': '<p>Your privacy is important to us...</p>',
          'image': null,
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.page('about-us'),
      type: RequestType.get,
      data: {
        'id': 1,
        'slug': 'about-us',
        'name': 'About Us',
        'content': '<p>We are a company that...</p>',
        'image': _mockImage,
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.appSettings,
      type: RequestType.get,
      data: {
        'social': [
          {
            'id': 1,
            'text': 'Follow us on Instagram',
            'url': 'https://instagram.com/terracotta',
            'image': _mockImage,
          },
        ],
        'contact': [
          {
            'id': 2,
            'text': 'support@terracotta.com',
            'url': 'mailto:support@terracotta.com',
            'image': null,
          },
        ],
        'app_store': <Map<String, dynamic>>[],
        'google_play': <Map<String, dynamic>>[],
        'app_gallery': <Map<String, dynamic>>[],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.languages,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'code': 'en',
          'name': 'English',
          'native_name': 'English',
          'direction': 'ltr',
          'is_default': true,
          'image': null,
        },
        {
          'id': 2,
          'code': 'ar',
          'name': 'Arabic',
          'native_name': 'العربية',
          'direction': 'rtl',
          'is_default': false,
          'image': _mockImage,
        },
      ],
    );
  }

  /// Shared image block for the mocks above — every image the API
  /// returns has this shape.
  static const Map<String, dynamic> _mockImage = {
    'id': 3,
    'url': 'shop/products/cup.webp',
    'type': 'webp',
    'blurhash': r'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
    'image_api': 'https://example.com/storage/shop/products/cup.webp',
  };

  // ─── API methods ──────────────────────────────────────────

  /// Translation strings for one consumer group, nested by sub-group.
  ///
  /// [group] accepts `app` or `web` only; omit it and the backend
  /// defaults to `app`. The locale comes from `Accept-Language`, which
  /// the headers interceptor sets — do not pass it here.
  static AsyncResult<TranslationBundle> getTranslations({
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<TranslationBundle>(
      TerracottaEndpoints.translations,
      queryParameters: {
        if (group != null) 'group': group,
      },
      fromJson: TranslationBundle.fromJson,
      logRequest: logGetTranslations.request,
      logResponse: logGetTranslations.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Upsert a flat map of `key => translated string` into one
  /// sub-group, for the locale in `Accept-Language`.
  ///
  /// Trap: this is a **seeding tool that only exists while the backend
  /// runs with `IS_TESTING`** — it is gone in production. Never put it
  /// on a customer path.
  static AsyncResult<Map<String, dynamic>> upsertTranslations({
    required String subGroup,
    required Map<String, String> translations,
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.translations,
      data: {
        if (group != null) 'group': group,
        'sub_group': subGroup,
        'translations': translations,
      },
      fromJson: (json) => json,
      logRequest: logUpsertTranslations.request,
      logResponse: logUpsertTranslations.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Remove one translation key from a sub-group.
  ///
  /// Traps, three of them:
  /// - **`IS_TESTING` only** — this endpoint does not exist in
  ///   production.
  /// - Written as DELETE on purpose. The method-override interceptor
  ///   rewrites it to POST + `X-HTTP-Method-Override` at send time
  ///   because the production host blocks real DELETE. Do not
  ///   hand-write the override, and do not change the verb.
  /// - `ApiService.delete` carries no body, so the fields ride in the
  ///   query string. Laravel's `input()` reads them either way.
  static AsyncResult<Map<String, dynamic>> deleteTranslationKey({
    required String subGroup,
    required String key,
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.translations,
      queryParameters: {
        if (group != null) 'group': group,
        'sub_group': subGroup,
        'key': key,
      },
      fromJson: (json) => json,
      logRequest: logDeleteTranslationKey.request,
      logResponse: logDeleteTranslationKey.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Managed media for one consumer group, nested by sub-group.
  ///
  /// Trap: [group] selects the CONSUMER and accepts `app` or `web`
  /// only. The bucket name (`onboarding`, `home`, …) is the
  /// `sub_group` the response nests by, not something you pass here.
  static AsyncResult<MediaLibrary> getMedia({
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<MediaLibrary>(
      TerracottaEndpoints.media,
      queryParameters: {
        if (group != null) 'group': group,
      },
      fromJson: MediaLibrary.fromJson,
      logRequest: logGetMedia.request,
      logResponse: logGetMedia.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Upload or replace one keyed media item; the type is auto-detected
  /// from the file's mime and the size cap is per type.
  ///
  /// [thumbnailPath] is the poster image for a video and is ignored for
  /// every other type.
  ///
  /// Traps: **`IS_TESTING` only** — gone in production. Sent as
  /// multipart, so [filePath] must be a real on-device path; this call
  /// does not work on web.
  static AsyncResult<Map<String, dynamic>> uploadMedia({
    required String subGroup,
    required String key,
    required String filePath,
    String? group,
    String? thumbnailPath,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.media,
      data: FormData.fromMap({
        if (group != null) 'group': group,
        'sub_group': subGroup,
        'key': key,
        'file': MultipartFile.fromFileSync(filePath),
        if (thumbnailPath != null)
          'thumbnail': MultipartFile.fromFileSync(thumbnailPath),
      }),
      fromJson: (json) => json,
      logRequest: logUploadMedia.request,
      logResponse: logUploadMedia.response,
      cancelToken: cancelToken,
      timeout: timeout ?? kApiUploadTimeout,
    ),
  );

  /// Delete one keyed media item from a sub-group.
  ///
  /// Traps: **`IS_TESTING` only**; written as DELETE and rewritten to
  /// POST by the override interceptor; the fields ride in the query
  /// string because `ApiService.delete` carries no body.
  static AsyncResult<Map<String, dynamic>> deleteMedia({
    required String subGroup,
    required String key,
    String? group,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.media,
      queryParameters: {
        if (group != null) 'group': group,
        'sub_group': subGroup,
        'key': key,
      },
      fromJson: (json) => json,
      logRequest: logDeleteMedia.request,
      logResponse: logDeleteMedia.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The app landing payload — banners, categories, featured products,
  /// offers, and `current_booking` when the caller has one.
  ///
  /// Traps: prices are decimal STRINGS (`"65.00"`), and the
  /// `current_booking` times are Asia/Riyadh already — render them as
  /// given, never shifted into the device timezone.
  static AsyncResult<HomePayload> getHome({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<HomePayload>(
      TerracottaEndpoints.home,
      fromJson: HomePayload.fromJson,
      logRequest: logGetHome.request,
      logResponse: logGetHome.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Gallery categories with their cover and item counts, paginated.
  static AsyncResult<List<GalleryAlbum>> getGalleryCategories({
    int? page,
    int? perPage,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<GalleryAlbum>(
      TerracottaEndpoints.gallery,
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
      fromJson: GalleryAlbum.fromJson,
      logRequest: logGetGalleryCategories.request,
      logResponse: logGetGalleryCategories.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One gallery category and its items, paginated.
  ///
  /// Each item is tagged `type: image | video` and carries an `image`
  /// — and NOTHING else. The supplied documents describe a `video`
  /// block with a `thumbnail`; the live server sends no such thing,
  /// and no video row exists on dev to infer one from. See
  /// `docs/api-contract.md` §14.
  static AsyncResult<GalleryAlbumDetail> getGalleryCategory(
    String categoryId, {
    int? page,
    int? perPage,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<GalleryAlbumDetail>(
      TerracottaEndpoints.galleryCategory(categoryId),
      queryParameters: {
        if (page != null) 'page': page,
        if (perPage != null) 'per_page': perPage,
      },
      fromJson: GalleryAlbumDetail.fromJson,
      logRequest: logGetGalleryCategory.request,
      logResponse: logGetGalleryCategory.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Every static content page, each with its HTML `content`.
  static AsyncResult<List<StaticPage>> getPages({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<StaticPage>(
      TerracottaEndpoints.pages,
      fromJson: StaticPage.fromJson,
      logRequest: logGetPages.request,
      logResponse: logGetPages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One static page, addressed by SLUG rather than id — `terms`,
  /// `privacy`, `returns`, `shipping`, `about`.
  static AsyncResult<StaticPage> getPage(
    String slug, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<StaticPage>(
      TerracottaEndpoints.page(slug),
      fromJson: StaticPage.fromJson,
      logRequest: logGetPage.request,
      logResponse: logGetPage.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Remote app settings — social / contact / store link blocks, plus
  /// the CR number, VAT number and VAT rate.
  ///
  /// Trap: the VAT rate here is the INCLUSIVE one. `vat_amount` on any
  /// quote is already contained in `total_price`; never add them.
  static AsyncResult<AppSettings> getAppSettings({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<AppSettings>(
      TerracottaEndpoints.appSettings,
      fromJson: AppSettings.fromJson,
      logRequest: logGetAppSettings.request,
      logResponse: logGetAppSettings.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Supported languages, each with its code, native name and
  /// `direction` (`ltr` / `rtl`).
  static AsyncResult<List<Language>> getLanguages({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Language>(
      TerracottaEndpoints.languages,
      fromJson: Language.fromJson,
      logRequest: logGetLanguages.request,
      logResponse: logGetLanguages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Preview a discount code against a subtotal without spending it.
  ///
  /// Needs the caller's session — this prices against their own cart or
  /// booking, so it is the one authenticated call in this group.
  ///
  /// Traps:
  /// - [subtotal] is a decimal STRING (`"130.00"`), as is every money
  ///   field that comes back. Never build it from a `double`.
  /// - **A discount code never reduces the delivery fee.** The
  ///   `total` here moves the goods total only; delivery is added on
  ///   top by the real quote endpoint.
  /// - This validates, it does not reserve. A code's use is consumed at
  ///   HOLD time (the create step), not here and not at pay time — so a
  ///   code that validates now can still be exhausted at checkout.
  /// The codes worth SHOWING — public, live, and with room left for
  /// this customer.
  ///
  /// The server does the filtering: a code whose overall or per-user
  /// limit is spent never appears. An empty list means the coupon field
  /// has nothing to advertise, not that codes do not exist — a private
  /// code still works when typed.
  static AsyncResult<List<DiscountCode>> getDiscountCodes({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<DiscountCode>(
      TerracottaEndpoints.discountCodes,
      fromJson: DiscountCode.fromJson,
      logRequest: logGetDiscountCodes.request,
      logResponse: logGetDiscountCodes.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  static AsyncResult<Map<String, dynamic>> validateDiscountCode({
    required String code,
    required String subtotal,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.discountCodeValidate,
      data: {
        'code': code,
        'subtotal': subtotal,
      },
      fromJson: (json) => json,
      logRequest: logValidateDiscountCode.request,
      logResponse: logValidateDiscountCode.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
