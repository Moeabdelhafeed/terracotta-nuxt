/// Every Terracotta API path, in one place.
///
/// One member per PATH, not per verb — `addresses` serves both the GET
/// that lists and the POST that creates; `booking(id)` serves GET, PUT
/// and DELETE. Paths carrying a `{param}` are functions, everything
/// else is a `static const String`.
///
/// House rules that hold across every path below:
/// - **Buying anything is three steps: quote → create → pay.** A quote
///   creates nothing. Create holds the thing UNPAID and reserves the
///   seat / wallet hold / gift code. Pay settles it.
/// - **`amount_due` of `"0.00"` means it ALREADY settled** (wallet or a
///   100% discount covered it). The client must check for that and skip
///   the pay call entirely.
/// - **Pay endpoints are idempotent** — a retry must not double-charge.
/// - **Money is a decimal STRING** (`"65.00"`), never a number. Parse it
///   as a decimal; never round-trip it through `double`.
/// - **VAT is INCLUSIVE** — `vat_amount` is already contained in
///   `total_price`. Never add the two together.
/// - **Workshop times come back in Asia/Riyadh.** Never convert them
///   client-side.
class TerracottaEndpoints {
  const TerracottaEndpoints._();

  // ─── Bases ────────────────────────────────────────────────

  static const String _api = '/api';
  static const String _workshops = '$_api/workshops';
  static const String _bookings = '$_workshops/bookings';
  static const String _shop = '$_api/shop';
  static const String _gifts = '$_api/gifts';
  static const String _notifications = '$_api/notifications';
  static const String _scan = '$_api/scan';

  // ─── Authentication ───────────────────────────────────────
  //
  // Mostly unauthenticated: [config], [login], [register],
  // [forgotPassword], [verifyForgotPasswordOtp], [changeForgotPassword],
  // [checkIdentifier], [verifyLogin] and [guest] need no bearer token.
  //
  // [logout], [sendOtp], [verifyOtp] and [changePassword] act on the
  // signed-in session and DO need one.
  //
  // [user] and [deleteAccount] are declared PUBLIC by the contract —
  // they resolve the caller from whatever session headers the request
  // carries (bearer token or `X-Device-Id` guest session).

  /// Auth capability flags — which identifiers, which social providers,
  /// whether OTP login is on. Fetch before drawing any auth screen.
  static const String config = '$_api/config';

  /// Password sign-in. With OTP mode on, this only sends the code and
  /// [verifyLogin] is what actually returns a token.
  static const String login = '$_api/login';

  /// Create an account.
  static const String register = '$_api/register';

  /// Start a password reset — sends an OTP to the chosen channel.
  static const String forgotPassword = '$_api/forgot-password';

  /// Check a reset OTP without consuming it.
  static const String verifyForgotPasswordOtp =
      '$_api/verify-forgot-password-otp';

  /// Set a new password using a verified reset OTP.
  static const String changeForgotPassword = '$_api/change-forgot-password';

  /// Ask whether an email / phone / username is already taken.
  static const String checkIdentifier = '$_api/check-identifier';

  /// Revoke the current session's token.
  static const String logout = '$_api/logout';

  /// Resend the account-verification OTP to the signed-in user.
  static const String sendOtp = '$_api/send-otp';

  /// Verify the signed-in user's account with an OTP.
  static const String verifyOtp = '$_api/verify-otp';

  /// Change the password of the signed-in user.
  static const String changePassword = '$_api/change-password';

  /// Exchange a login OTP for a bearer token.
  static const String verifyLogin = '$_api/verify-login';

  /// Permanently delete the calling account.
  static const String deleteAccount = '$_api/delete-account';

  /// The caller's own user record — guest or registered.
  static const String user = '$_api/user';

  /// Mint an anonymous guest session keyed to `X-Device-Id`.
  static const String guest = '$_api/guest';

  // ─── Profile ──────────────────────────────────────────────
  //
  // All authenticated except [firebaseLogin], which is how a social
  // sign-in EXCHANGES a Firebase ID token for a bearer token and so
  // runs before one exists.

  /// Trade a Firebase ID token for a Terracotta bearer token.
  static const String firebaseLogin = '$_api/firebase-login';

  /// The social providers linked to this account, plus what may still
  /// be linked.
  static const String socialAccounts = '$_api/social-accounts';

  /// Attach another social provider to the signed-in account.
  static const String linkSocialAccount = '$_api/link-social-account';

  /// Detach a social provider from the signed-in account.
  static const String unlinkSocialAccount = '$_api/unlink-social-account';

  /// Edit name / username / email / phone. Changing the identifier
  /// itself goes through [requestIdentifierChange] instead.
  static const String updateProfile = '$_api/update-profile';

  /// Start moving the account to a new email or phone — sends an OTP to
  /// the NEW identifier.
  static const String requestIdentifierChange =
      '$_api/request-identifier-change';

  /// Confirm the new identifier with the OTP it received.
  static const String verifyIdentifierChange = '$_api/verify-identifier-change';

  /// Wallet ledger, paginated. Balances are decimal strings.
  static const String walletTransactions = '$_api/wallet/transactions';

  /// Every device holding a live token for this account.
  static const String devices = '$_api/devices';

  /// One device — DELETE signs it out.
  static String device(String deviceId) => '$_api/devices/$deviceId';

  // ─── Addresses ────────────────────────────────────────────
  //
  // Authenticated, except [deliveryZones] which is public so the
  // delivery fee can be shown before sign-in.

  /// Resolve a Saudi 8-character short address into a full one.
  static const String addressLookup = '$_api/addresses/lookup';

  /// The caller's saved addresses — GET lists, POST creates.
  static const String addresses = '$_api/addresses';

  /// One saved address — PUT updates, DELETE removes.
  static String address(String addressId) => '$_api/addresses/$addressId';

  /// Deliverable cities with their fee and free-over threshold.
  static const String deliveryZones = '$_api/delivery-zones';

  // ─── Workshops ────────────────────────────────────────────
  //
  // The catalogue is public — [workshops], [workshop],
  // [workshopAvailability] and [workshopPrice] all read without a
  // token. Everything under [bookings] is authenticated.
  //
  // Booking is the three-step buy: [workshopPrice] quotes,
  // [workshopBookings] creates an UNPAID booking holding the seat, and
  // [bookingPay] settles. All times are Asia/Riyadh already.

  /// The workshop catalogue, paginated.
  static const String workshops = _workshops;

  /// One workshop's detail.
  static String workshop(String workshopId) => '$_workshops/$workshopId';

  /// Bookable slots for a workshop. Slot times are Asia/Riyadh — show
  /// them as given, never shifted into the device timezone.
  static String workshopAvailability(String workshopId) =>
      '$_workshops/$workshopId/availability';

  /// QUOTE step — prices a prospective booking (seats, celebration
  /// add-on, products, wallet). Creates nothing and holds nothing; the
  /// seat is only reserved once [workshopBookings] is called.
  /// `vat_amount` is already inside `total_price`.
  static String workshopPrice(String workshopId) =>
      '$_workshops/$workshopId/price';

  /// CREATE step — books the workshop UNPAID and reserves the seat.
  /// Settle it with [bookingPay] unless `amount_due` came back
  /// `"0.00"`, which means it already settled.
  static String workshopBookings(String workshopId) =>
      '$_workshops/$workshopId/bookings';

  /// The caller's own bookings, paginated.
  static const String bookings = _bookings;

  /// One booking — GET reads, PUT reschedules, DELETE cancels.
  static String booking(String bookingId) => '$_bookings/$bookingId';

  /// PAY step — settles a booking. Idempotent: calling it twice must
  /// not double-charge. Skip it entirely when `amount_due` is `"0.00"`.
  static String bookingPay(String bookingId) => '$_bookings/$bookingId/pay';

  /// Upload photos of the finished piece for this booking.
  static String bookingImages(String bookingId) =>
      '$_bookings/$bookingId/images';

  /// Remove ONE photograph.
  ///
  /// There is no replace: the API has a create and two deletes and
  /// nothing else, so swapping a picture is a delete followed by an
  /// upload. Removing the last photograph of a piece removes the piece
  /// with it — a piece IS its photographs.
  static String bookingImage(String bookingId, String imageId) =>
      '$_bookings/$bookingId/images/$imageId';

  /// Remove a whole PIECE, and every photograph of it.
  ///
  /// **The same path RENAMES it**, as a PATCH — see
  /// [WorkshopApis.renamePiece]. That verb is not in `/docs.openapi`
  /// yet: the spec lists one create and two deletes on a piece and
  /// nothing else, so `piece_labels[]` is read when a piece is made
  /// and never again. The app sends it anyway, because the alternative
  /// — delete and re-upload — needs files the app does not hold and
  /// would break the `own_pieces` and `painting_session` references
  /// that point at the old id.
  static String bookingPiece(String bookingId, String pieceId) =>
      '$_bookings/$bookingId/pieces/$pieceId';

  /// Prices delivery of the finished piece to a saved address. 422s for
  /// a `make_your_candle` booking, which has no delivery step at all.
  static String bookingDeliveryQuote(String bookingId) =>
      '$_bookings/$bookingId/delivery/quote';

  /// Choose pickup or delivery for the finished piece. 422s for a
  /// `make_your_candle` booking — that product is never delivered.
  static String bookingDelivery(String bookingId) =>
      '$_bookings/$bookingId/delivery';

  // ─── Shop ─────────────────────────────────────────────────
  //
  // Browsing is public — [shopHome], [shopCategories], [shopProducts]
  // and [shopProduct] need no token. Favourites, cart and orders are
  // all authenticated.
  //
  // Checkout is the three-step buy: [shopCartQuote] quotes,
  // [shopCartCheckout] creates an UNPAID order, [shopOrderPay] settles.

  /// The caller's favourited products.
  static const String shopFavorites = '$_shop/favorites';

  /// One favourite — POST adds, DELETE removes.
  static String shopFavorite(String productId) => '$_shop/favorites/$productId';

  /// The active cart — GET reads it, POST adds a line to it.
  static const String shopCart = '$_shop/cart';

  /// One cart line — PUT changes quantity, DELETE removes the line.
  static String shopCartItem(String itemId) => '$_shop/cart/$itemId';

  /// QUOTE step — totals the cart with delivery, discount and wallet
  /// applied. Creates no order. A discount code never reduces the
  /// delivery fee, and `vat_amount` is already inside `total_price`.
  static const String shopCartQuote = '$_shop/cart/quote';

  /// CREATE step — turns the cart into an UNPAID order and empties it.
  /// Settle with [shopOrderPay] unless `amount_due` is `"0.00"`.
  static const String shopCartCheckout = '$_shop/cart/checkout';

  /// PAY step — settles an order. Idempotent: a retry must not
  /// double-charge. Skip when `amount_due` came back `"0.00"`.
  static String shopOrderPay(String orderId) => '$_shop/orders/$orderId/pay';

  /// The caller's orders, paginated.
  static const String shopOrders = '$_shop/orders';

  /// One order — GET reads, DELETE cancels.
  static String shopOrder(String orderId) => '$_shop/orders/$orderId';

  /// Shop landing payload — banners plus featured rails.
  static const String shopHome = '$_shop/home';

  /// Shop category tree.
  static const String shopCategories = '$_shop/categories';

  /// Product listing — filter by category, featured, on-sale, search.
  static const String shopProducts = '$_shop/products';

  /// One product's detail.
  static String shopProduct(String productId) => '$_shop/products/$productId';

  // ─── Raw materials and tools ──────────────────────────────
  //
  // A second STOREFRONT, not a second shop: clay, glazes and tools,
  // browsed and filtered exactly like [shopProducts] and answering the
  // identical wire shape.
  //
  // **It shares the shop's basket.** A material is added through
  // [shopCart] like any other product, and a basket holding a mug and
  // a bag of clay checks out as ONE order with ONE delivery fee. There
  // is deliberately no materials cart, checkout or order history — the
  // three paths below are the whole surface.

  static const String _materials = '/api/materials';

  /// Material category tree. Same shape as [shopCategories].
  static const String materialCategories = '$_materials/categories';

  /// Material listing. Every filter [shopProducts] takes.
  static const String materialProducts = '$_materials/products';

  /// One material's detail. Same shape as [shopProduct].
  static String materialProduct(String productId) =>
      '$_materials/products/$productId';

  // ─── Gifts ────────────────────────────────────────────────
  //
  // [giftPackage] and [gift] (the recipient's preview by token) are
  // public — the recipient is a stranger holding a link. Everything
  // else needs a token.
  //
  // Same three steps: [giftQuote] quotes, [gifts] POST creates the gift
  // UNPAID and reserves its code, [giftPay] settles.

  /// The caller's purchased gifts, paginated — GET lists, POST is the
  /// CREATE step that buys one UNPAID and reserves its code.
  static const String gifts = _gifts;

  /// QUOTE step — prices a gift. Creates nothing, reserves no code.
  /// `vat_amount` is already inside `total_price`.
  /// BOTH SIDES in one list — what the caller bought and what they
  /// claimed — over a `totals` block that does NOT follow the
  /// `direction` filter. Registered customers only; a guest gets 401.
  static const String giftHistory = '$_gifts/history';

  static const String giftQuote = '$_gifts/quote';

  /// PAY step — settles a gift. Idempotent; skip it when `amount_due`
  /// is `"0.00"`.
  static String giftPay(String giftId) => '$_gifts/$giftId/pay';

  /// Redeem a gift into the caller's wallet using its token.
  static String giftRedeem(String token) => '$_gifts/$token/redeem';

  /// Gift packaging options and prices.
  static const String giftPackage = '$_gifts/package';

  /// Public preview of a gift by its token — what the recipient sees
  /// before signing in to redeem it.
  static String gift(String token) => '$_gifts/$token';

  // ─── Content ──────────────────────────────────────────────
  //
  // All public except [discountCodeValidate], which prices against the
  // caller's own cart / booking and needs a token.

  /// Translation strings — GET reads a group, POST upserts keys,
  /// DELETE removes one.
  static const String translations = '$_api/translations';

  /// Managed media — GET lists a group, POST uploads or replaces,
  /// DELETE removes.
  static const String media = '$_api/media';

  /// App landing payload.
  static const String home = '$_api/home';

  /// Gallery categories, paginated.
  static const String gallery = '$_api/gallery';

  /// One gallery category's items, paginated.
  static String galleryCategory(String categoryId) =>
      '$_api/gallery/$categoryId';

  /// Static content pages (terms, privacy, about).
  static const String pages = '$_api/pages';

  /// One static page, addressed by slug rather than id.
  static String page(String slug) => '$_api/pages/$slug';

  /// Remote app settings / feature flags.
  static const String appSettings = '$_api/app-settings';

  /// Supported languages.
  static const String languages = '$_api/languages';

  /// The codes the customer could actually use right now.
  ///
  /// PUBLIC codes only, and only those with room left for THIS
  /// customer — the server drops one whose usage or per-user limit is
  /// spent. An empty list means the coupon field has nothing to
  /// advertise, not that codes do not exist: a private code still
  /// validates when typed.
  static const String discountCodes = '$_api/discount-codes';

  /// Check a discount code against a cart or booking. Note it never
  /// reduces the delivery fee — only the goods total moves.
  static const String discountCodeValidate = '$_api/discount-codes/validate';

  // ─── Notifications ────────────────────────────────────────
  //
  // All authenticated — every path here is scoped to the caller.

  /// The caller's notifications, paginated, optionally unread-only.
  static const String notifications = _notifications;

  /// Mark every notification read in one call.
  static const String notificationsReadAll = '$_notifications/read-all';

  /// Mark one notification read.
  static String notificationRead(String notificationId) =>
      '$_notifications/$notificationId/read';

  /// Broadcast-channel authorisation handshake for the realtime
  /// private channel.
  static const String broadcastingAuth = '$_api/broadcasting/auth';

  // ─── Complaints ───────────────────────────────────────────
  //
  // Same path, split auth: POST is public so a signed-out visitor can
  // complain, GET needs a token because it lists the caller's own.

  /// GET lists the caller's complaints (auth required); POST files a
  /// new one (public).
  static const String complaints = '$_api/complaints';

  // ─── Scanner ──────────────────────────────────────────────
  //
  // Staff-facing, all authenticated — a token belonging to an operator
  // account, not a customer.

  /// Sessions for a given day, defaulting to today.
  static const String scanSessions = '$_scan/sessions';

  /// Check a booking in from its scanned code.
  static const String scanCheckIn = '$_scan/check-in';

  /// Start a session for the checked-in party.
  static const String scanSessionStart = '$_scan/sessions/start';

  /// Finish a running session.
  static const String scanSessionFinish = '$_scan/sessions/finish';
}
