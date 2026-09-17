/// WHERE the loading indicator appears, and how much it blocks.
///
/// Named `LoadingSurface`, not `LoadingStyle`: it says which surface
/// the overlay puts up, and `LoadingStyle` is now the themeable bag
/// that says how that surface LOOKS. Two unrelated "style" words on
/// one widget is what the date-time picker had to untangle, and the
/// buttons module already owns a `ButtonLoadingStyle` besides.
///
/// - [scrim] (default) — fullscreen semi-opaque barrier + centered
///   spinner + optional label. Blocks input. Use for ops where the
///   user must wait (auth, save, payment).
/// - [topBar] — non-blocking 3px linear bar at top. Use for
///   background syncs / refreshes that shouldn't gate input.
/// - [dim] — like [scrim] but lighter scrim, no spinner — pure
///   "input blocked, look elsewhere" cue. Used by callers who
///   render their own progress UI inline.
enum LoadingSurface { scrim, topBar, dim }
