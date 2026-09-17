/// A cubit whose payload is LOCALIZED BY THE SERVER, and which
/// therefore has to be reloaded when the reader changes language.
///
/// ## The two things this fixes
///
/// Every tab is a top-level route and the nav bar switches them with
/// `context.go`, which tears the previous page's `State` down. A cubit
/// owned by that `State` dies with it, so home → gallery → home used
/// to re-request the whole home payload every single time. The cubits
/// are singletons now; this is what stops a singleton from being a
/// STALE one.
///
/// And the other way round: `MaterialApp` rebuilds when the language
/// changes but the router's pages are not remounted, so a page that
/// had already loaded kept showing Arabic copy under an English UI
/// until something else happened to reload it. `Accept-Language` is
/// resolved per request from the live `PreferencesCubit`, so the only
/// missing piece was knowing WHEN to ask again.
///
/// ## The rule
///
/// Reload when there is nothing yet, or when the language differs from
/// the one the data on screen was fetched in. Never otherwise. A page
/// the reader was not looking at when they switched picks it up on the
/// way in, because the check is on show, not on the switch.
mixin LocaleScopedLoad {
  /// The language the data on screen arrived in. Null before the first
  /// load.
  String? _loadedLocale;

  /// Whether there is anything on screen to keep. Implemented by the
  /// cubit against its own state.
  bool get hasData;

  /// The unconditional fetch.
  Future<void> load();

  /// The language the current data was loaded in, for tests and for
  /// anything that needs to reason about staleness.
  String? get loadedLocale => _loadedLocale;

  /// Loads only if it would say something new.
  Future<void> ensureLoaded(String locale) async {
    // `hasData` and not "did we ever try": a load that FAILED left the
    // screen with an error and no payload, and coming back to the tab
    // is a fair moment to try again.
    if (hasData && _loadedLocale == locale) return;
    _loadedLocale = locale;
    await load();
  }

  /// Forgets what was loaded, so the next `ensureLoaded` fetches
  /// whatever the reader is now.
  ///
  /// The SESSION is what makes this necessary. These cubits are `getIt`
  /// singletons that outlive every page, and `ensureLoaded` only asks
  /// again when the LANGUAGE changes — so signing out left the last
  /// customer's data on screen until something else happened to
  /// reload it.
  void invalidate() => _loadedLocale = null;

  /// A pull-to-refresh in a language nobody changed. Records the
  /// language so the next `ensureLoaded` does not immediately repeat
  /// the work.
  Future<void> refreshIn(String locale) {
    _loadedLocale = locale;
    return load();
  }
}
