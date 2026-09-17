/// Firebase Remote Config keys with inline fallback defaults.
class RemoteConfigConstants {
  const RemoteConfigConstants._();

  // ─── API ────────────────────────────────────────────────────

  static const String xApiToken = 'x_api_token';
  static const String baseUrl = 'base_url';

  // ─── App Info ──────────────────────────────────────────────

  static const String appName = 'app_name';
  static const String supportEmail = 'support_email';
  static const String supportPhone = 'support_phone';
  static const String websiteUrl = 'website_url';
  static const String privacyPolicyUrl = 'privacy_policy_url';
  static const String termsOfServiceUrl = 'terms_of_service_url';

  // ─── Store URLs ────────────────────────────────────────────

  static const String appStoreUrl = 'app_store_url';
  static const String playStoreUrl = 'play_store_url';

  // ─── Version Control ───────────────────────────────────────
  // Per-platform so iOS / Android can be released independently.
  // Empty value = no gate on that platform. Web is never gated.

  static const String minAppVersionIos = 'min_app_version_ios';
  static const String minAppVersionAndroid = 'min_app_version_android';
  static const String latestAppVersionIos = 'latest_app_version_ios';
  static const String latestAppVersionAndroid = 'latest_app_version_android';

  // ─── Maintenance ───────────────────────────────────────────

  static const String maintenanceMode = 'maintenance_mode';
  static const String maintenanceTitle = 'maintenance_title';
  static const String maintenanceMessage = 'maintenance_message';
  // ISO-8601 timestamp; empty string = no ETA.
  static const String maintenanceEta = 'maintenance_eta';
  static const String maintenanceSupportUrl = 'maintenance_support_url';
  // JSON array of route paths that bypass the gate during an outage.
  // Supports exact match and `/*` prefix wildcard. Example:
  // `["/login","/legal/*","/support"]`. Empty array = block all.
  static const String maintenanceAllowList = 'maintenance_allow_list';

  // ─── Feature Flags ─────────────────────────────────────────

  static const String featureSocialLogin = 'feature_social_login';
  static const String featureInAppReview = 'feature_in_app_review';

  // ─── Feedback ──────────────────────────────────────────────

  /// Master switch. False = `FeedbackButton` no-ops, route returns
  /// 404, screen never renders. Useful for B2B / enterprise.
  static const String feedbackEnabled = 'feedback_enabled';

  /// Backend POST endpoint (joined onto `baseUrl`). Empty = use
  /// mailto only.
  static const String feedbackEndpoint = 'feedback_endpoint';

  /// Support email used for the mailto fallback + as the to: when
  /// the API is empty.
  static const String feedbackSupportEmail = 'feedback_support_email';

  /// Whether the diagnostics block is auto-attached on first open.
  /// User can still toggle off per-submission.
  static const String feedbackAttachDiagnosticsDefault =
      'feedback_attach_diagnostics_default';

  /// Per-user submission cooldown (seconds). Stops accidental double
  /// submits + light client-side rate limit.
  static const String feedbackCooldownSeconds = 'feedback_cooldown_seconds';

  /// How many attachments a report may carry.
  ///
  /// Remote, like the cooldown, because it is the limit an operator
  /// most wants during an incident: "send us more screenshots" is a
  /// config change, not a release.
  static const String feedbackMaxAttachments = 'feedback_max_attachments';

  // ─── Onboarding ────────────────────────────────────────────

  /// Master switch. False = onboarding never surfaces, even if the
  /// `seenOnboarding` flag is unset. Useful for B2B / enterprise
  /// builds that ship with no intro flow.
  static const String onboardingEnabled = 'onboarding_enabled';

  /// Optional JSON array of page definitions. When set, replaces the
  /// app's bundled default pages. Schema (per page):
  /// ```json
  /// {"title": "...", "body": "...", "icon": "rocket_launch_rounded",
  ///  "ctaLabel": "Allow", "permission": "notifications"}
  /// ```
  /// Permission values: `'notifications'`, `'location'`, `'camera'`,
  /// `'contacts'`, or empty for none.
  static const String onboardingPagesJson = 'onboarding_pages_json';

  // ─── Connectivity ──────────────────────────────────────────

  /// HEAD probe URL — pick a tiny, reliable endpoint. Default is
  /// Google's captive-portal canary (returns 204).
  static const String connectivityProbeUrl = 'connectivity_probe_url';

  /// Foreground re-probe interval in seconds. `0` disables periodic
  /// probing.
  static const String connectivityProbeIntervalSeconds =
      'connectivity_probe_interval_seconds';

  /// Probe-failure circuit-breaker threshold. After this many fails
  /// the probe is distrusted and connectivity_plus becomes the
  /// authority again.
  static const String connectivityMaxProbeFailures =
      'connectivity_max_probe_failures';

  /// `'allow'` | `'warn'` | `'block'` — see [VpnPolicy].
  static const String connectivityVpnPolicy = 'connectivity_vpn_policy';

  // ─── Legal / About pages ───────────────────────────────────

  /// Global flip — `'backend'` to prefer the backend HTML endpoint,
  /// anything else to use remote markdown / cached / bundled.
  static const String legalSourceMode = 'legal_source_mode';

  /// Per-page keys are derived from a [LegalPage] slug:
  ///   `legal_<slug>_enabled`        — show in index, allow route
  ///   `legal_<slug>_url_md`         — remote markdown URL
  ///   `legal_<slug>_endpoint_html`  — backend HTML endpoint path
  ///                                   (joined onto `baseUrl`)
  static String legalEnabled(String slug) => 'legal_${slug}_enabled';
  static String legalUrlMd(String slug) => 'legal_${slug}_url_md';
  static String legalEndpointHtml(String slug) => 'legal_${slug}_endpoint_html';

  // ─── Defaults ──────────────────────────────────────────────

  /// Pass to `RemoteConfig.setDefaults()` during initialization.
  static Map<String, dynamic> get defaults => {
    // API
    //
    // Seeded EMPTY so `.env` stays the authority until someone
    // publishes real values in Firebase. `_resolveString` only accepts
    // a Remote Config value when it is non-empty, so a placeholder seed
    // here would OUTRANK `envFallback` and silently point every call at
    // the template's `api.example.com` — which is exactly what it did.
    xApiToken: '',
    baseUrl: '',
    // App info
    appName: 'My App',
    supportEmail: 'support@example.com',
    supportPhone: '+1234567890',
    websiteUrl: 'https://example.com',
    privacyPolicyUrl: 'https://example.com/privacy',
    termsOfServiceUrl: 'https://example.com/terms',
    // Store URLs
    appStoreUrl: '',
    playStoreUrl: '',
    // Version (per-platform; empty = no gate on that platform)
    minAppVersionIos: '1.0.0',
    minAppVersionAndroid: '1.0.0',
    latestAppVersionIos: '1.0.0',
    latestAppVersionAndroid: '1.0.0',
    // Maintenance
    //
    // Seeded EMPTY on purpose. This map is built inside `initFirebase`
    // — bootstrap step 4 — and `S.load()` has not run yet, so touching
    // a `Strings` namespace here throws `S.current`'s assertion and
    // takes the whole Remote Config init down with it. An empty seed is
    // also what `MaintenanceScreen` already expects: it falls back to
    // `MaintenanceStrings.defaultTitle` / `.defaultMessage` at render
    // time, where the delegate IS loaded and the locale is known.
    maintenanceMode: false,
    maintenanceTitle: '',
    maintenanceMessage: '',
    maintenanceEta: '',
    maintenanceSupportUrl: '',
    maintenanceAllowList: '[]',
    // Features
    featureSocialLogin: true,
    featureInAppReview: true,
    // Connectivity
    connectivityProbeUrl: 'https://www.gstatic.com/generate_204',
    connectivityProbeIntervalSeconds: 30,
    connectivityMaxProbeFailures: 3,
    connectivityVpnPolicy: 'allow',
    // Onboarding
    onboardingEnabled: true,
    onboardingPagesJson: '',
    // Feedback
    feedbackEnabled: true,
    feedbackEndpoint: '',
    feedbackSupportEmail: 'support@example.com',
    feedbackAttachDiagnosticsDefault: true,
    feedbackMaxAttachments: 3,
    feedbackCooldownSeconds: 60,
    // Legal — defaults to remote-md mode; bundled fallbacks ship
    // in `assets/legal/<slug>.md`. Per-page enabled flags default to
    // `true` for the eight pages wired by `LegalPage` enum.
    legalSourceMode: 'remote_md',
    'legal_about_enabled': true,
    'legal_privacy_enabled': true,
    'legal_tos_enabled': true,
    'legal_licenses_enabled': true,
    'legal_eula_enabled': false,
    'legal_refund_enabled': false,
    'legal_credits_enabled': false,
    'legal_contact_enabled': true,
  };
}
