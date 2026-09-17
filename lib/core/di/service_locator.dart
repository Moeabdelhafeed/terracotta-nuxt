import 'package:get_it/get_it.dart';

import '../../data/blocs/auth/auth_bloc.dart';
import '../../data/blocs/auth/auth_event.dart';
import '../../data/blocs/faq_history/faq_history_cubit.dart';
import '../../data/blocs/pdf_bookmarks/pdf_bookmarks_cubit.dart';
import '../../data/blocs/preferences/preferences_cubit.dart';
import '../../data/blocs/search_history/search_history_cubit.dart';
import '../../data/blocs/wizard_drafts/wizard_drafts_cubit.dart';
import '../../data/notifications/fcm_service.dart';
import '../../data/notifications/in_app_notification_service.dart';
import '../../data/notifications/local_notification_service.dart';
import '../../data/notifications/notification_history.dart';
import '../../data/repositories/secure_credential_store.dart';
import '../../data/services/app_config_service.dart';
import '../../data/services/auth/social_auth_adapters.dart';
import '../../data/services/auth/social_auth_dispatcher.dart';
import '../../data/services/gift_package_service.dart';
import '../../data/services/languages_service.dart';
import '../../data/services/location/directions_service.dart';
import '../../data/services/location/reverse_geocoding_service.dart';
import '../../data/services/media/dynamic_assets.dart';
import '../../data/services/media/recent_uploads_cache.dart';
import '../../data/services/media/upload_service.dart';
import '../../data/services/navigation_service.dart';
import '../../data/services/preferences/locale_service.dart';
import '../../data/services/preferences/role_service.dart';
import '../../data/services/preferences/theme_service.dart';
import '../../data/services/remote_config_watcher.dart';
import '../../data/services/speech_to_text_service.dart';
import '../../features/_shared/favorites_registry.dart';
import '../../features/cart/cubits/cart_cubit.dart';
import '../../features/cart/data/guest_basket.dart';
import '../../features/gallery/cubits/gallery_cubit.dart';
import '../../features/home/cubits/home_cubit.dart';
import '../../features/home/cubits/live_now_cubit.dart';
import '../../features/profile/cubits/app_settings_cubit.dart';
import '../../features/profile/cubits/notifications_cubit.dart';
import '../../features/profile/cubits/pages_cubit.dart';
import '../../features/profile/cubits/profile_counts_cubit.dart';
import '../../features/profile/cubits/wallet_cubit.dart';
import '../../features/profile/data/guest_addresses.dart';
import '../../features/shop/cubits/product_counts_cubit.dart';
import '../../features/shop/cubits/shop_home_cubit.dart';
import '../../features/shop/data/guest_wishlist.dart';
import '../../features/workshops/cubits/my_bookings_cubit.dart';
import '../../features/workshops/cubits/workshops_cubit.dart';
import '../connectivity/connectivity_cubit.dart';
import '../connectivity/offline_action_queue.dart';
import '../loading/loading_cubit.dart';
import '../localization/remote_translations.dart';
import '../maintenance/maintenance_cubit.dart';
import '../update_gate/update_cubit.dart';

/// Central `get_it` instance. Non-widget code (services, repositories,
/// API handlers) looks up dependencies here. Widget code uses
/// `BlocProvider.value` + `context.read` — both end up with the same
/// singleton instance since we register once on boot.
final GetIt getIt = GetIt.instance;

/// Manifest of every type registered in [initServiceLocator]. The
/// debug-overlay's service-locator dump walks this list — `get_it`
/// has no public iteration API, so we keep parallel state at
/// registration sites. Update both lists when adding a registration.
const List<Type> kRegisteredServices = <Type>[
  SecureCredentialStore,
  AuthBloc,
  PreferencesCubit,
  PdfBookmarksCubit,
  SearchHistoryCubit,
  WizardDraftsCubit,
  FaqHistoryCubit,
  MaintenanceCubit,
  ConnectivityCubit,
  OfflineActionQueue,
  UpdateCubit,
  LoadingCubit,
  RemoteConfigWatcher,
  LocaleService,
  ThemeService,
  RoleService,
  LanguagesService,
  RemoteTranslations,
  SpeechToTextService,
  UploadService,
  RecentUploadsCache,
  DirectionsService,
  ReverseGeocodingService,
  SocialAuthDispatcher,
  // The two tab payloads. Singletons because every tab is a top-level
  // route and `context.go` tears the previous page's State down — a
  // page-owned cubit died on every switch and re-requested everything
  // on the way back. See `LocaleScopedLoad` for what keeps them fresh.
  HomeCubit,
  GalleryCubit,
  WalletCubit,
  CartCubit,
  AppConfigService,
  GiftPackageService,
  AppSettingsCubit,
  DynamicAssets,
  NotificationsCubit,
  ProfileCountsCubit,
  GuestBasket,
  GuestWishlist,
  GuestAddresses,
  PagesCubit,
  WorkshopsCubit,
  MyBookingsCubit,
  LiveNowCubit,
  ShopHomeCubit,
  ProductCountsCubit,
  FavoritesRegistry,
];

/// Types registered OUTSIDE [initServiceLocator] — `NavigationService`
/// in `bootstrap_di.dart` (needs the GoRouter instance) and the
/// notification services in `notifications_config.dart` (skipped when
/// notifications are disabled). Absence at runtime is legitimate for
/// these, so the debug overlay renders them as their own group instead
/// of flagging manifest drift.
const List<Type> kLateRegisteredServices = <Type>[
  NavigationService,
  LocalNotificationService,
  InAppNotificationService,
  FCMService,
  NotificationHistoryService,
];

/// "Instantiated yet?" probes for the debug overlay — lazy singletons
/// only construct on first read. `get_it`'s check API is generic-only,
/// so the closures live here where the type arguments can be written
/// out. Callers must gate on `getIt.isRegistered(type: t)` first: the
/// probe throws for unregistered types.
final Map<Type, bool Function()> kServiceInstanceProbes =
    <Type, bool Function()>{
      SecureCredentialStore: () =>
          getIt.checkLazySingletonInstanceExists<SecureCredentialStore>(),
      AuthBloc: () => getIt.checkLazySingletonInstanceExists<AuthBloc>(),
      PreferencesCubit: () =>
          getIt.checkLazySingletonInstanceExists<PreferencesCubit>(),
      PdfBookmarksCubit: () =>
          getIt.checkLazySingletonInstanceExists<PdfBookmarksCubit>(),
      SearchHistoryCubit: () =>
          getIt.checkLazySingletonInstanceExists<SearchHistoryCubit>(),
      WizardDraftsCubit: () =>
          getIt.checkLazySingletonInstanceExists<WizardDraftsCubit>(),
      FaqHistoryCubit: () =>
          getIt.checkLazySingletonInstanceExists<FaqHistoryCubit>(),
      MaintenanceCubit: () =>
          getIt.checkLazySingletonInstanceExists<MaintenanceCubit>(),
      ConnectivityCubit: () =>
          getIt.checkLazySingletonInstanceExists<ConnectivityCubit>(),
      OfflineActionQueue: () =>
          getIt.checkLazySingletonInstanceExists<OfflineActionQueue>(),
      UpdateCubit: () => getIt.checkLazySingletonInstanceExists<UpdateCubit>(),
      LoadingCubit: () =>
          getIt.checkLazySingletonInstanceExists<LoadingCubit>(),
      RemoteConfigWatcher: () =>
          getIt.checkLazySingletonInstanceExists<RemoteConfigWatcher>(),
      LocaleService: () =>
          getIt.checkLazySingletonInstanceExists<LocaleService>(),
      ThemeService: () =>
          getIt.checkLazySingletonInstanceExists<ThemeService>(),
      RoleService: () => getIt.checkLazySingletonInstanceExists<RoleService>(),
      LanguagesService: () =>
          getIt.checkLazySingletonInstanceExists<LanguagesService>(),
      RemoteTranslations: () =>
          getIt.checkLazySingletonInstanceExists<RemoteTranslations>(),
      SpeechToTextService: () =>
          getIt.checkLazySingletonInstanceExists<SpeechToTextService>(),
      UploadService: () =>
          getIt.checkLazySingletonInstanceExists<UploadService>(),
      RecentUploadsCache: () =>
          getIt.checkLazySingletonInstanceExists<RecentUploadsCache>(),
      DirectionsService: () =>
          getIt.checkLazySingletonInstanceExists<DirectionsService>(),
      ReverseGeocodingService: () =>
          getIt.checkLazySingletonInstanceExists<ReverseGeocodingService>(),
      SocialAuthDispatcher: () =>
          getIt.checkLazySingletonInstanceExists<SocialAuthDispatcher>(),
      NavigationService: () =>
          getIt.checkLazySingletonInstanceExists<NavigationService>(),
      LocalNotificationService: () =>
          getIt.checkLazySingletonInstanceExists<LocalNotificationService>(),
      InAppNotificationService: () =>
          getIt.checkLazySingletonInstanceExists<InAppNotificationService>(),
      FCMService: () => getIt.checkLazySingletonInstanceExists<FCMService>(),
      NotificationHistoryService: () =>
          getIt.checkLazySingletonInstanceExists<NotificationHistoryService>(),
    };

/// Register app-wide singletons. Call once from `main.dart`, after
/// `HydratedBloc.storage` is ready (the `PreferencesCubit` is a
/// `HydratedCubit` and reads storage in its constructor).
Future<void> initServiceLocator() async {
  // ─── Repositories ──────────────────────────────────────────────
  getIt.registerLazySingleton<SecureCredentialStore>(
    () => SecureCredentialStore(),
  );

  // ─── Blocs / Cubits ────────────────────────────────────────────
  getIt.registerLazySingleton<AuthBloc>(
    () =>
        AuthBloc(getIt<SecureCredentialStore>())
          ..add(const AuthEvent.bootstrapped()),
  );
  getIt.registerLazySingleton<PreferencesCubit>(() => PreferencesCubit());
  getIt.registerLazySingleton<PdfBookmarksCubit>(() => PdfBookmarksCubit());
  getIt.registerLazySingleton<SearchHistoryCubit>(() => SearchHistoryCubit());
  getIt.registerLazySingleton<WizardDraftsCubit>(() => WizardDraftsCubit());
  getIt.registerLazySingleton<FaqHistoryCubit>(() => FaqHistoryCubit());
  getIt.registerLazySingleton<MaintenanceCubit>(() => MaintenanceCubit());

  // ─── Connectivity ──────────────────────────────────────────────
  // Cubit owns the live connectivity verdict (online/offline/VPN).
  // Queue depends on the cubit (subscribes to recovery edge to
  // auto-replay). Both are started in bootstrap, after RC seed.
  getIt.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  getIt.registerLazySingleton<OfflineActionQueue>(
    () => OfflineActionQueue(cubit: getIt<ConnectivityCubit>()),
  );

  // ─── Update gate ──────────────────────────────────────────────
  // Holds verdict + dismissal state across cold start. Re-seeded
  // from RC + package_info during boot and on every RC update.
  getIt.registerLazySingleton<UpdateCubit>(() => UpdateCubit());

  // ─── Global loading overlay ───────────────────────────────────
  // Single cubit drives the app-wide overlay. App-level options can
  // be passed at mount-time via `LoadingOverlay(options: ...)`; the
  // cubit's options are updated in place so callers / interceptor
  // see the same config.
  getIt.registerLazySingleton<LoadingCubit>(() => LoadingCubit());

  // ─── Remote Config live watcher ────────────────────────────
  // Single source of truth for "RC just changed". Snapshot-style
  // consumers subscribe to `watcher.updates` and reseed their state.
  getIt.registerLazySingleton<RemoteConfigWatcher>(() => RemoteConfigWatcher());

  // ─── Services (thin wrappers over PreferencesCubit) ────────────
  getIt.registerLazySingleton<LocaleService>(
    () => LocaleService(getIt<PreferencesCubit>()),
  );
  getIt.registerLazySingleton<ThemeService>(
    () => ThemeService(getIt<PreferencesCubit>()),
  );
  getIt.registerLazySingleton<RoleService>(
    () => RoleService(getIt<PreferencesCubit>()),
  );

  // ─── Stateful services ─────────────────────────────────────────
  // LanguagesService / RemoteTranslations: `await
  // getIt<X>().init()` during boot to warm their caches.
  getIt.registerLazySingleton<LanguagesService>(() => LanguagesService());
  getIt.registerLazySingleton<RemoteTranslations>(() => RemoteTranslations());
  getIt.registerLazySingleton<SpeechToTextService>(() => SpeechToTextService());
  getIt.registerLazySingleton<UploadService>(() => UploadService());
  getIt.registerLazySingleton<RecentUploadsCache>(() => RecentUploadsCache());
  // Google Maps clients — pass the API key at registration time.
  // Pull from Remote Config / AppConfig; placeholder leaves them in
  // their "unconfigured" state (every call returns null).
  getIt.registerLazySingleton<DirectionsService>(() => DirectionsService());
  getIt.registerLazySingleton<ReverseGeocodingService>(
    () => ReverseGeocodingService(),
  );
  // NavigationService depends on the GoRouter instance — register
  // from `main.dart` after GoRouter is constructed.

  // ─── Social auth ───────────────────────────────────────────────
  // One adapter per provider; dispatcher routes enum → adapter.
  // Stub adapters surface a "not wired yet" error until you add
  // the SDK + fill in the body — see social_auth_adapters.dart.
  // Drop a provider entirely by removing its line here.
  // BEFORE the cubits that read it — each takes it at construction.
  getIt.registerLazySingleton<FavoritesRegistry>(FavoritesRegistry.new);

  // What a visitor collects before they have an account. Both read
  // `HydratedBloc.storage`, which `initStorage` has already built by
  // the time DI runs — see the bootstrap order in CLAUDE.md.
  getIt.registerLazySingleton<GuestBasket>(GuestBasket.new);
  getIt.registerLazySingleton<GuestWishlist>(GuestWishlist.new);
  // The third of the device-owned stores, for the same reason as the
  // other two: every address route answers 401 without a session, and
  // someone filling in a delivery address is about to buy something.
  getIt.registerLazySingleton<GuestAddresses>(GuestAddresses.new);
  // The studio's own writing, shared by the profile section that lists
  // it and by the register screen's terms link — one request for five
  // pages, and `GET /api/pages` carries their HTML with them.
  getIt.registerLazySingleton<PagesCubit>(PagesCubit.new);
  getIt.registerLazySingleton<HomeCubit>(
    () => HomeCubit(registry: getIt<FavoritesRegistry>()),
  );
  getIt.registerLazySingleton<GalleryCubit>(GalleryCubit.new);
  // A TAB cubit for the same reason the others are: `context.go` tears
  // the profile page's State down on every switch away from it.
  getIt.registerLazySingleton<WalletCubit>(WalletCubit.new);
  // App-wide because the BADGE is: the count sits on the app bar of
  // every screen, and a cart owned by the sheet would read zero until
  // someone opened it.
  // Handed the device's basket so it can serve a guest from it. Which
  // half it uses is decided per call, not at construction: the reader
  // signs in while the app is running and the SAME cubit has to follow
  // them across.
  // APP-WIDE, because the BADGE is. Every bar in the app carries the
  // bell, and a page-owned cubit meant the number was whatever the
  // inbox screen last loaded — which was nothing, on every screen but
  // that one.
  // `GET /api/config` — the broadcast topic names among other things.
  getIt.registerLazySingleton<AppConfigService>(AppConfigService.new);
  getIt.registerLazySingleton<GiftPackageService>(GiftPackageService.new);
  // «تواصل معنا» — the studio's own channels, from
  // `GET /api/app-settings`. A singleton: the sheet can be opened from
  // more than one place and none of them owns it.
  getIt.registerLazySingleton<AppSettingsCubit>(AppSettingsCubit.new);
  // The studio's own artwork, with the bundle as the fallback — and
  // the bundle seeded INTO an empty key so there is something to edit.
  getIt.registerLazySingleton<DynamicAssets>(DynamicAssets.new);
  getIt.registerLazySingleton<NotificationsCubit>(NotificationsCubit.new);
  // The numbers beside the account rows. A singleton like every other
  // tab cubit: `context.go` tears the profile page's `State` down.
  getIt.registerLazySingleton<ProfileCountsCubit>(ProfileCountsCubit.new);
  getIt.registerLazySingleton<CartCubit>(
    () => CartCubit(basket: getIt<GuestBasket>()),
  );
  getIt.registerLazySingleton<WorkshopsCubit>(WorkshopsCubit.new);
  // «ورشاتي» sits on the same tab as the catalogue, and that tab is a
  // top-level route — `context.go` disposes its State, so a page-owned
  // cubit re-requested the customer's bookings on every visit.
  getIt.registerLazySingleton<MyBookingsCubit>(MyBookingsCubit.new);
  // The two "happening now" strips, which sit on THREE top-level
  // routes — home, workshops and shop. `context.go` disposes each of
  // their States, so a page-owned cubit would ask the server again on
  // every tab switch.
  getIt.registerLazySingleton<LiveNowCubit>(LiveNowCubit.new);
  getIt.registerLazySingleton<ShopHomeCubit>(
    () => ShopHomeCubit(registry: getIt<FavoritesRegistry>()),
  );
  // How many pieces «عرض الكل» opens onto. Two top-level routes draw
  // it — home and shop — and a count reads the same in both
  // languages, so it is asked for once per launch.
  getIt.registerLazySingleton<ProductCountsCubit>(ProductCountsCubit.new);

  getIt.registerLazySingleton<SocialAuthDispatcher>(
    () => SocialAuthDispatcher(const [
      GoogleSocialAuthAdapter(),
      FacebookSocialAuthAdapter(),
      AppleSocialAuthAdapter(),
      TwitterSocialAuthAdapter(),
      GithubSocialAuthAdapter(),
      MicrosoftSocialAuthAdapter(),
      LinkedinSocialAuthAdapter(),
      DiscordSocialAuthAdapter(),
      YahooSocialAuthAdapter(),
      AmazonSocialAuthAdapter(),
      InstagramSocialAuthAdapter(),
    ]),
  );
}

/// Tear down for tests / logout "forget everything" flows.
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
