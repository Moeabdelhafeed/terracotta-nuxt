import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart' as pdfrx;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/animations/animation_presets.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/button_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/pdf_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/layout/bar_fit.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../../data/blocs/pdf_bookmarks/pdf_bookmarks_cubit.dart';
import '../../common/text_form_fields/text_form_fields.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_text_button.dart';
import '../container/global_container.dart';
import '../dialog/global_dialog.dart';
import '../image/global_image.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../share/global_share_button.dart';
import '../sheet/global_sheet.dart';
import '../shimmer/global_shimmer.dart';
import '../toast/global_toast.dart';
import 'pdf_handle.dart';
import 'pdf_metadata.dart';
import 'pdf_models.dart';
import 'theme/pdf_theme.dart';

export 'pdf_handle.dart';
export 'pdf_metadata.dart';
export 'pdf_models.dart';
export 'pdf_recent_docs.dart';
export 'theme/pdf_theme.dart';

/// Module-level page-1 thumbnail cache, keyed by source persistKey.
///
/// Populated by the first viewer to mount for a given source (e.g.
/// the compact preview). Reused by later mounts of the same source —
/// in particular, the fullscreen route opened from a compact tap —
/// to render an instant placeholder via `loadingBannerBuilder` while
/// pdfrx re-warms its page raster pipeline. Eliminates the
/// "split-second loading" flash after the Hero flight ends.
final Map<String, Uint8List> _kPdfHeroThumbs = <String, Uint8List>{};

/// Documents already read into memory this session, keyed by persist
/// key and newest-last.
///
/// The module fetches URL documents ITSELF rather than letting pdfrx
/// do it, so that opening the fullscreen viewer from a compact card is
/// free: the destination gets bytes rather than a URL, and the hero
/// lands on a page instead of on a loading banner. The cost is that
/// pdfrx's own range requests and progressive rendering are not used —
/// a whole document is read before the first page paints.
///
/// Bounded, because a document is megabytes and a static map is
/// forever: the oldest entry goes when a fourth arrives.
final Map<String, Uint8List> _kPdfBytes = <String, Uint8List>{};
const int _kPdfBytesCacheEntries = 3;

/// Documents whose resume has already been announced this session.
///
/// Per-STATE was not enough: a compact card and the fullscreen viewer
/// it opens are two states over one document, so both announced the
/// same resume — two identical toasts, stacked — and every re-entry
/// announced it again.
final Set<String> _kPdfResumeAnnounced = <String>{};

/// Invert, then rotate the hue half a turn.
///
/// The product of `invert(1)` and `hue-rotate(180deg)`: lightness ends
/// up flipped while hues land back near where they started, so text
/// goes white-on-black and a photograph survives. A plain inversion
/// turns every picture on the page into a negative.
///
/// These are the SVG `feColorMatrix` hue-rotation coefficients at 180°,
/// negated and offset — not numbers chosen by eye. A hand-guessed
/// version of this matrix was the first attempt and cast every
/// photograph orange, because its rows did not sum to one and so grey
/// stopped inverting to grey.
@visibleForTesting
const List<double> pdfSmartInvertMatrix = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
];

/// Painted side of a toolbar button on a narrow bar.
///
/// What `VisualDensity.compact` used to buy: at phone-width fullscreen
/// (~390–430dp) the toolbar has more buttons than 48dp slots.
const double _kPdfTightBarButton = 40;

/// A full-size bar button, and the width below which the bar switches
/// to compact targets before it starts dropping anything.
const double _kPdfBarButton = 48;
const double _kPdfTightBarWidth = 520;

/// How big a LOCAL document may be before its metadata is not worth
/// reading. Parsing `/Info` means holding the whole file, and doing
/// that to a 100MB scan to find a title nothing is obliged to display
/// is a cost the caller did not ask for.
const int _kPdfMetadataMaxBytes = 64 * 1024 * 1024;

/// Room the "page / N" read-out needs. Fixed, so the bar's arithmetic
/// does not depend on how many digits the document has.
const double _kPdfPageLabelWidth = 64;

/// The spinner that replaces the overflow glyph while a system intent
/// is being prepared.
const double _kPdfBusySpinner = 18;

/// The search row's own breathing room, and the fixed slot its match
/// counter occupies so the buttons beside it do not move as the count
/// changes.
const double _kPdfSearchGap = 8;
const double _kPdfMatchCounterWidth = 64;

/// Builder signature for [PdfViewerVariant.custom].
typedef PdfBuilder =
    Widget Function(
      BuildContext context,
      PdfHandle handle,
      Widget viewer,
    );

/// Password prompt callback. Return null to cancel (viewer reports
/// `errored` + `encrypted` in its snapshot).
typedef PdfPasswordCallback = Future<String?> Function();

/// Reusable PDF viewer built on `pdfrx` with:
///   * paged / continuous / compact / custom variants,
///   * pinch-zoom + page indicator + zoom controls,
///   * password-protected document prompt,
///   * text search (next / prev / clear),
///   * outline panel,
///   * thumbnail strip,
///   * bookmarks persisted via [PdfBookmarksCubit],
///   * "resume reading" — restores `lastReadPage` on open,
///   * dark-mode color invert (cheap night mode).
class GlobalPdfViewer extends StatefulWidget {
  const GlobalPdfViewer({
    super.key,
    required this.source,
    this.variant = PdfViewerVariant.full,
    this.style = const PdfStyle(),
    this.initialPage = 1,
    this.heroTag,
    this.enableHero = true,
    this.enableKeyboardShortcuts = true,
    this.autoResumeAtLastPage = true,
    this.onPasswordRequired,
    this.onPageChanged,
    this.onStateChanged,
    this.onTapCompact,
    this.builder,
  }) : assert(
         variant != PdfViewerVariant.custom || builder != null,
         'PdfViewerVariant.custom requires a builder',
       );

  final PdfSourceSpec source;
  final PdfViewerVariant variant;
  final PdfStyle style;

  /// Page to open at, 1-based. DATA, not styling: where a reader is in
  /// a document is a property of that reading, not of how viewers look.
  final int initialPage;

  /// The `Hero` tag for the compact variant's preview.
  ///
  /// Rarely needed: leave it null and both ends derive the same tag
  /// from the document — see [defaultHeroTag]. Set it when two previews
  /// of the SAME document share a screen, which is the one case the
  /// derived tag cannot handle: `Hero` requires tags to be unique
  /// within a route, and two identical ones throw.
  /// An identity, so it lives here rather than on the style bag.
  final Object? heroTag;

  /// Whether the compact preview flies into the viewer it opens.
  ///
  /// ON. The flight used to require a caller to invent a tag and repeat
  /// it at the destination, so the default experience of tapping a
  /// preview was a cut. Both ends can work the tag out from the
  /// document, and do.
  final bool enableHero;

  /// Whether ⌘F, the arrow keys, +/−, R, ⌘P and Esc drive the viewer.
  ///
  /// ON everywhere. See `_withShortcuts` for why this is not gated to
  /// desktop.
  final bool enableKeyboardShortcuts;

  /// When true, opens the document at the persisted last-read page
  /// for this source (if any). When false, uses [initialPage].
  final bool autoResumeAtLastPage;

  /// Invoked when the document is encrypted and no password is set
  /// on the source. Return null to cancel.
  final PdfPasswordCallback? onPasswordRequired;

  final ValueChanged<int>? onPageChanged;
  final ValueChanged<PdfStateSnapshot>? onStateChanged;

  /// Tap handler for [PdfViewerVariant.compact]. Typical use: push a
  /// full-screen viewer route.
  final VoidCallback? onTapCompact;

  /// Required when [variant] is [PdfViewerVariant.custom]. Receives
  /// the live handle plus the raw pdfrx viewer widget — caller
  /// composes their own chrome around it.
  final PdfBuilder? builder;

  /// The tag both ends of the flight derive when none is given.
  ///
  /// Keyed by the document rather than by the widget, because the two
  /// ends are different widgets on different routes and the document is
  /// the only thing they share. Namespaced so it cannot collide with a
  /// caller's own tag for something else.
  static Object defaultHeroTag(String persistKey) => 'pdf-hero:$persistKey';

  /// Pushes the viewer's own fullscreen route.
  ///
  /// The route a compact card opens by default, exposed so a caller
  /// wiring `onTapCompact` does not have to hand-roll one. Both of the
  /// showcase's did, and both ended up with `AppBar(titleWidget: Text('PDF'))`
  /// over a document called something else — a bar that says less than
  /// the card the reader tapped.
  static Future<void> openFullscreen(
    BuildContext context, {
    required PdfSourceSpec source,
    PdfStyle style = const PdfStyle(),
    Object? heroTag,
    bool enableHero = true,
    String? fileName,
    PdfPasswordCallback? onPasswordRequired,
  }) {
    return Navigator.of(context).push(
      RouteTransition.route<void>(
        context: context,
        name: 'pdf-fullscreen',
        child: _PdfFullscreenRoute(
          source: source,
          fileName: fileName ?? _fileNameFor(source),
          style: style,
          // Derived from the document, so a caller who wires
          // `onTapCompact` to this route gets the flight without
          // knowing a tag exists.
          heroTag: enableHero
              ? (heroTag ?? defaultHeroTag(source.persistKey))
              : null,
          onPasswordRequired: onPasswordRequired,
        ),
      ),
    );
  }

  /// Asks the device for a PDF and returns it as a source.
  ///
  /// Returns null when the picker is dismissed, which is a normal
  /// outcome and not an error — a caller that treats null as failure
  /// shows an error message to someone who simply changed their mind.
  ///
  /// The two platforms hand back different things and both are handled:
  /// a PATH on native, where the file stays where it is, and BYTES on
  /// web, where there is no path to give. The label carries the file
  /// name either way, so bookmarks and the last-read page key off
  /// something a reader would recognise.
  static Future<PdfSourceSpec?> pickFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      // Web has no filesystem to point at, so the bytes have to come
      // back with the result or there is nothing to open.
      withData: kIsWeb,
    );
    final picked = result?.files.singleOrNull;
    if (picked == null) return null;

    final path = picked.path;
    if (!kIsWeb && path != null) {
      return PdfSourceSpec.file(path);
    }
    final bytes = picked.bytes;
    if (bytes == null) return null;
    return PdfSourceSpec.bytes(bytes, label: picked.name);
  }

  /// Picks a document and opens it fullscreen, in one call.
  ///
  /// Returns false when the picker was dismissed, so a caller can tell
  /// "they cancelled" from "it opened and they came back".
  static Future<bool> openFromDevice(
    BuildContext context, {
    PdfStyle style = const PdfStyle(),
    PdfPasswordCallback? onPasswordRequired,
  }) async {
    final source = await pickFromDevice();
    if (source == null) return false;
    if (!context.mounted) return false;
    await openFullscreen(
      context,
      source: source,
      style: style,
      onPasswordRequired: onPasswordRequired,
    );
    return true;
  }

  @override
  State<GlobalPdfViewer> createState() => _GlobalPdfViewerState();
}

/// The page laid out the way a viewer lays it out: WIDTH-fitted, from
/// the top, and clipped where the box runs out.
///
/// The height must not be allowed to constrain it. Under an `Align`
/// the page is handed a `maxHeight` of the box, and `Image` answers a
/// height it cannot meet by SHRINKING to preserve aspect — so in a
/// short card a full page came back as a small one, floating centred
/// in a box the real viewer fills edge to edge. It is only visible in
/// a short box: on a full screen the page fits its height anyway,
/// which is why the fullscreen end of the flight always looked right
/// and the card end did not.
///
/// `page` is a parameter so a test can measure what the leaf is given
/// without decoding an image.
@visibleForTesting
Widget pdfStillFrame({required Color background, required Widget page}) =>
    ColoredBox(
      color: background,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: page,
        ),
      ),
    );

/// A still page-one frame to fly between the card and the viewer.
///
/// A `Hero` with no shuttle flies the SOURCE widget, which here is a
/// live pdfrx viewer showing wherever the reader happens to be. Coming
/// back from page three that meant the card briefly wore page three,
/// then swapped to its own page one — an in-between state with a flash
/// at the end of it. Both ends of the flight now show the same still
/// image, so there is nothing to swap.
///
/// Falls back to flying the widget when no thumbnail has been rendered
/// yet, which is only ever the first tap on a cold document.
///
/// The card's CHROME travels with it — its corner, its outline and its
/// label bar. A flight that carries only the page lands on a page, and
/// the rounded corner and the file-name bar then appear in one frame,
/// which is the flash left after the framing was fixed. They resolve
/// against the flight's own animation, so the card end of it is the
/// card exactly.
@visibleForTesting
Widget Function(
  BuildContext,
  Animation<double>,
  HeroFlightDirection,
  BuildContext,
  BuildContext,
)?
pdfHeroShuttleFor(
  String persistKey,
  Color background, {
  BorderRadius? borderRadius,
  Color? borderColor,
  Widget? label,
}) {
  final thumb = _kPdfHeroThumbs[persistKey];
  if (thumb == null) return null;
  final frame = pdfStillFrame(
    background: background,
    page: Image.memory(
      thumb,
      fit: BoxFit.fitWidth,
      width: double.infinity,
      gaplessPlayback: true,
    ),
  );
  return (context, animation, direction, from, to) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      // ZERO is the card in BOTH directions: a push runs the arriving
      // route's animation forwards, a pop runs the leaving route's
      // backwards, and the card is the one that is not moving.
      final t = animation.value.clamp(0.0, 1.0);
      final corner = BorderRadius.lerp(borderRadius, BorderRadius.zero, t)!;
      // A shuttle is built in the OVERLAY, not in either route, so the
      // card's own `Material` is not above it and the label's text had
      // no `DefaultTextStyle` to inherit. Flutter paints that red on a
      // yellow double underline — the striping on the file name and the
      // page count for the length of the flight.
      return Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: corner,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor.withValues(alpha: 1 - t)),
          ),
          child: ClipRRect(
            borderRadius: corner,
            child: Stack(
              fit: StackFit.expand,
              children: [
                frame,
                if (label != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Opacity(opacity: 1 - t, child: label),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// The module's in-memory caches, and the way to drop them.
///
/// Three maps outlive any one viewer, deliberately — a document opened
/// twice should not be downloaded twice, and a preview that has already
/// rasterized page one should not do it again for the flight. All three
/// are bounded or tiny, so this is not a leak to be plugged; it is the
/// switch a Settings screen needs, and the one a test needs so state
/// from one case cannot reach the next.
///
/// The thumbnail STRIP's own cache is not here. It belongs to a widget
/// and dies with it.
abstract final class PdfCache {
  /// Everything, for every document.
  static void clearAll() {
    _kPdfBytes.clear();
    _kPdfHeroThumbs.clear();
    _kPdfResumeAnnounced.clear();
  }

  /// Everything held for ONE document.
  ///
  /// The key is the source's `persistKey` — the same one bookmarks and
  /// the last-read page hang off. Note that it does NOT forget those:
  /// they are the reader's, not the cache's.
  static void clearFor(String persistKey) {
    _kPdfBytes.remove(persistKey);
    _kPdfHeroThumbs.remove(persistKey);
    _kPdfResumeAnnounced.remove(persistKey);
  }

  /// How many documents are being held in memory, and how much they
  /// weigh. For a debug overlay or a Settings row that has to say what
  /// clearing would free.
  static int get documentCount => _kPdfBytes.length;

  static int get byteCount =>
      _kPdfBytes.values.fold(0, (sum, bytes) => sum + bytes.lengthInBytes) +
      _kPdfHeroThumbs.values.fold(0, (sum, b) => sum + b.lengthInBytes);
}

/// One keyboard shortcut, on its way to the viewer's `Actions`.
class _PdfShortcutIntent extends Intent {
  const _PdfShortcutIntent(this.command);
  final PdfShortcutCommand command;
}

/// Seeds or clears a cached page-one thumbnail, for tests.
@visibleForTesting
void debugSetPdfHeroThumb(String persistKey, Uint8List? bytes) {
  if (bytes == null) {
    _kPdfHeroThumbs.remove(persistKey);
  } else {
    _kPdfHeroThumbs[persistKey] = bytes;
  }
}

/// Whether returning from a sub-route should put the cached thumbnail
/// back over the viewer.
///
/// Only when there is nothing underneath it worth showing. A viewer
/// that never unmounted still has its document open and its page
/// painted, and covering that is the very stutter the overlay exists
/// to prevent.
@visibleForTesting
bool pdfShouldRecoverOnReturn({required bool loading, required bool errored}) =>
    loading || errored;

/// A file name made presentable for a title bar: extension off —
/// nobody needs telling the PDF viewer is showing a PDF — and the
/// separators that survive a download turned back into spaces.
///
/// A name that cleans away to nothing keeps the original, so a file
/// called `.pdf` still says something.
@visibleForTesting
String pdfDisplayTitle(String fileName) {
  var name = fileName;
  final dot = name.lastIndexOf('.');
  if (dot > 0) name = name.substring(0, dot);
  name = name.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  return name.isEmpty ? fileName : name;
}

/// The document's name, for a title bar.
String _fileNameFor(PdfSourceSpec source) {
  switch (source.kind) {
    case PdfSourceKind.url:
      return Uri.tryParse(source.value)?.pathSegments.lastOrNull ??
          source.value;
    case PdfSourceKind.file:
      return source.value.split(Platform.pathSeparator).last;
    case PdfSourceKind.asset:
      return source.value.split('/').last;
    case PdfSourceKind.bytes:
      return source.value;
  }
}

class _GlobalPdfViewerState extends State<GlobalPdfViewer>
    implements PdfHandle {
  /// Materialized once per dependency change — caller > theme >
  /// defaults > palette. Build code reads this, never the raw bag.
  late ResolvedPdfStyle _rs;

  final _controller = pdfrx.PdfViewerController();
  final _stateController = StreamController<PdfStateSnapshot>.broadcast();
  pdfrx.PdfTextSearcher? _searcher;
  pdfrx.PdfDocument? _document;

  int _pageNumber = 0;
  int _pageCount = 0;
  bool _loading = true;
  bool _errored = false;
  bool _encrypted = false;
  bool _searching = false;
  int _matchCount = 0;
  int _currentMatch = -1;
  int _rotation = 0;
  String? _docTitle;
  String? _docAuthor;
  Uint8List? _cachedBytes;

  /// Guards [_prefetchUrlBytes] against the rebuild it causes.
  bool _prefetching = false;
  Uint8List? _heroThumb;
  String? _suppliedPassword;

  /// Controls the fade-out of the cached-thumbnail overlay that
  /// covers the live viewer while it paints its first page raster.
  /// Starts true → flips false ~150ms after the doc reports loaded.
  bool _thumbOverlayVisible = true;
  Timer? _thumbHideTimer;
  ModalRoute<Object?>? _route;

  PdfBookmarksCubit get _bookmarks => getIt<PdfBookmarksCubit>();
  String get _persistKey => widget.source.persistKey;

  @override
  void initState() {
    super.initState();
    _suppliedPassword = widget.source.password;
    // Searcher creation is deferred to _onViewerReady — its
    // constructor reads `controller.document` which is null until the
    // viewer has mounted + loaded a doc. Wiring it earlier crashes
    // with a null-check exception inside pdfrx.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
    // Track this widget's enclosing route so we can re-trigger the
    // overlay when a sub-route pops back to us (e.g. closing the
    // fullscreen viewer drops us back into the compact card).
    final r = ModalRoute.of(context);
    if (identical(r, _route)) return;
    _route?.secondaryAnimation?.removeStatusListener(_onSecondaryAnimStatus);
    _route = r;
    _route?.secondaryAnimation?.addStatusListener(_onSecondaryAnimStatus);
  }

  @override
  void didUpdateWidget(GlobalPdfViewer old) {
    super.didUpdateWidget(old);
    _rs = widget.style.resolve(context);
  }

  void _onSecondaryAnimStatus(AnimationStatus status) {
    // Sub-route just *started* popping → cover our (cold) viewer
    // with the cached thumbnail again. Sub-route fully gone → fade
    // it back out.
    // Re-cover ONLY a viewer that has nothing to show.
    //
    // This used to re-show the overlay on the way back from any
    // sub-route. But the card never unmounted while the fullscreen
    // route was up: its document is still open and its raster is still
    // painted, so covering it puts a differently-scaled still frame
    // over a live page and then cross-fades back — which is exactly the
    // stutter this overlay exists to prevent, performed on the way out
    // instead of on the way in.
    if (status == AnimationStatus.reverse) {
      if (!_thumbOverlayVisible &&
          !pdfShouldRecoverOnReturn(loading: _loading, errored: _errored)) {
        return;
      }
      if (!_thumbOverlayVisible && mounted) {
        setState(() => _thumbOverlayVisible = true);
      }
    } else if (status == AnimationStatus.dismissed) {
      _scheduleThumbOverlayHide();
    }
  }

  @override
  void dispose() {
    _route?.secondaryAnimation?.removeStatusListener(_onSecondaryAnimStatus);
    _thumbHideTimer?.cancel();
    _searcher
      ?..removeListener(_onSearcherChanged)
      ..dispose();
    _stateController.close();
    super.dispose();
  }

  void _onSearcherChanged() {
    if (!mounted || _searcher == null) return;
    setState(() {
      _searching = _searcher!.isSearching;
      _matchCount = _searcher!.matches.length;
      _currentMatch = _searcher!.currentIndex ?? -1;
    });
    _emit();
  }

  Future<String?> _passwordProvider() async {
    // First attempt — supplied password wins.
    if (_suppliedPassword != null) {
      final pw = _suppliedPassword;
      _suppliedPassword = null; // single-shot
      return pw;
    }
    setState(() => _encrypted = true);
    final cb = widget.onPasswordRequired;
    if (cb == null) {
      Logger.m.w(
        '[GlobalPdfViewer] encrypted PDF but no '
        'onPasswordRequired callback supplied',
      );
      return null;
    }
    final pw = await cb();
    if (pw == null) {
      // User cancelled.
      if (mounted) {
        setState(() {
          _errored = true;
          _loading = false;
        });
      }
    }
    return pw;
  }

  void _onDocumentChanged(pdfrx.PdfDocument? doc) {
    if (!mounted) return;
    _document = doc;
    if (doc == null) return;
    setState(() {
      _pageCount = doc.pages.length;
      _loading = false;
      _errored = false;
    });
    // Mark as opened so it surfaces in `PdfRecentDocsList` even if
    // the user never paged. pdfrx's onPageChanged only fires on a
    // *change*, so the initial page-1 view otherwise leaves no
    // record. Use whatever page we'll actually settle on (resume
    // target if set, else style.initialPage).
    final initial = widget.autoResumeAtLastPage
        ? (_bookmarks.lastReadPage(_persistKey) ?? widget.initialPage)
        : widget.initialPage;
    _bookmarks.setLastReadPage(_persistKey, initial);
    _emit();
    _scheduleThumbOverlayHide();
  }

  /// Fades out the cached-thumbnail overlay shortly after the
  /// document reports loaded. The delay gives pdfrx a frame to
  /// rasterize the first page — fading out earlier exposes a blank
  /// flash before the page paints.
  void _scheduleThumbOverlayHide() {
    if (!_thumbOverlayVisible) return;
    _thumbHideTimer?.cancel();
    // Short delay — just enough for pdfrx to put a first-frame
    // raster underneath. Tight value lets the fade *overlap* the
    // Hero flight (default ~300ms) instead of starting after it,
    // which would read as a second discrete animation.
    _thumbHideTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() => _thumbOverlayVisible = false);
    });
  }

  void _onViewerReady(
    pdfrx.PdfDocument document,
    pdfrx.PdfViewerController controller,
  ) {
    if (!mounted) return;
    // Searcher must be created after the controller has a document
    // (its constructor blows up on `controller.document` otherwise).
    _searcher ??= pdfrx.PdfTextSearcher(controller)
      ..addListener(_onSearcherChanged);

    // Pre-warm the Hero flight shuttle bitmap so the
    // compact→fullscreen transition doesn't flash a cold viewer at
    // end-of-flight. Keyed off `enableHero`, not off a caller-supplied
    // tag — the flight is on by default now, and gating the pre-warm on
    // a tag nobody passes leaves the default path flying a live viewer.
    if (widget.enableHero && _heroThumb == null) {
      unawaited(_loadHeroThumb());
    }

    unawaited(_loadMetadata());

    final lastRead = _bookmarks.lastReadPage(_persistKey);
    final start = widget.autoResumeAtLastPage
        ? (lastRead ?? widget.initialPage)
        : widget.initialPage;
    if (start > 1 && start <= document.pages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(controller.goToPage(pageNumber: start));
          // Once per document per SESSION, and never from a preview.
          // The flag was per-State, so a compact card and the
          // fullscreen viewer it opens each announced the same resume —
          // two identical toasts stacked on top of each other — and
          // every re-entry announced it again.
          if (widget.autoResumeAtLastPage &&
              lastRead != null &&
              lastRead == start &&
              widget.variant != PdfViewerVariant.compact &&
              _kPdfResumeAnnounced.add(_persistKey)) {
            _showResumeSnack(start);
          }
        }
      });
    }
  }

  /// Fills [PdfStateSnapshot.title] and `.author` from the document's
  /// own `/Info` dictionary.
  ///
  /// pdfrx-engine does not expose it, so these two were API surface
  /// that was always null. Parsed out of the bytes instead — see
  /// `pdf_metadata.dart` for what that can and cannot answer.
  ///
  /// Never over the NETWORK. A URL document is already in hand because
  /// this module downloads it itself; if it somehow is not, a title is
  /// not worth a second fetch of the whole file.
  Future<void> _loadMetadata() async {
    if (!mounted || _docTitle != null || _docAuthor != null) return;

    final inHand = _cachedBytes ?? _kPdfBytes[_persistKey];
    if (inHand == null) {
      if (widget.source.kind == PdfSourceKind.url) return;
      if (widget.source.kind == PdfSourceKind.file) {
        final length = await File(widget.source.value).length();
        if (length > _kPdfMetadataMaxBytes) return;
      }
    }

    final bytes = inHand ?? await _resolveBytes();
    if (bytes == null || !mounted) return;

    final info = parsePdfInfo(bytes);
    if (info.isEmpty) return;
    setState(() {
      _docTitle = info.title;
      _docAuthor = info.author;
    });
    _emit();
  }

  Future<void> _loadHeroThumb() async {
    // Generous width — destination route fills the screen, so the
    // cached bitmap needs to scale up cleanly behind the loading
    // banner without going pixelated.
    final bytes = await renderThumbnail(1, maxWidth: 800);
    if (!mounted || bytes == null) return;
    _kPdfHeroThumbs[_persistKey] = bytes;
    setState(() => _heroThumb = bytes);
  }

  void _showResumeSnack(int page) {
    GlobalToast.info(
      PdfStrings.resumedAtPage(page),
      duration: const Duration(seconds: 3),
      actionLabel: PdfStrings.startOver,
      onAction: () => unawaited(_controller.goToPage(pageNumber: 1)),
    );
  }

  void _onPageChanged(int? page) {
    if (page == null || !mounted) return;
    setState(() => _pageNumber = page);
    _bookmarks.setLastReadPage(_persistKey, page);
    widget.onPageChanged?.call(page);
    _emit();
  }

  void _emit() {
    final snap = state;
    widget.onStateChanged?.call(snap);
    if (!_stateController.isClosed) _stateController.add(snap);
  }

  // ─── PdfHandle ───────────────────────────────────────────────

  @override
  PdfStateSnapshot get state => PdfStateSnapshot(
    pageNumber: _pageNumber,
    pageCount: _pageCount,
    zoom: _controller.isReady ? _controller.currentZoom : 1.0,
    rotation: _rotation,
    loading: _loading,
    errored: _errored,
    encrypted: _encrypted,
    searching: _searching,
    matchCount: _matchCount,
    currentMatchIndex: _currentMatch,
    title: _docTitle,
    author: _docAuthor,
  );

  @override
  Stream<PdfStateSnapshot> get stateStream => _stateController.stream;

  @override
  Future<void> goToPage(int page) async {
    if (!_controller.isReady) return;
    final clamped = page.clamp(1, _pageCount);
    await _controller.goToPage(pageNumber: clamped);
  }

  @override
  Future<void> nextPage() => goToPage(_pageNumber + 1);

  @override
  Future<void> prevPage() => goToPage(_pageNumber - 1);

  @override
  Future<void> zoomIn() async {
    if (!_controller.isReady) return;
    await _controller.zoomUp();
  }

  @override
  Future<void> zoomOut() async {
    if (!_controller.isReady) return;
    await _controller.zoomDown();
  }

  @override
  Future<void> resetZoom() async {
    if (!_controller.isReady) return;
    final center = _controller.centerPosition;
    await _controller.setZoom(center, _rs.initialZoom);
  }

  @override
  Future<void> setZoom(double scale) async {
    if (!_controller.isReady) return;
    final center = _controller.centerPosition;
    await _controller.setZoom(center, scale);
  }

  @override
  Future<void> search(String? query, {bool caseSensitive = false}) async {
    final s = _searcher;
    if (s == null) return;
    final q = query?.trim();
    if (q == null || q.isEmpty) {
      s.resetTextSearch();
      return;
    }
    s.startTextSearch(q, caseInsensitive: !caseSensitive);
  }

  @override
  Future<void> nextMatch() async => _searcher?.goToNextMatch();

  @override
  Future<void> prevMatch() async => _searcher?.goToPrevMatch();

  @override
  Future<void> clearSearch() async => _searcher?.resetTextSearch();

  @override
  Future<List<PdfOutlineItem>> loadOutline() async {
    final doc = _document;
    if (doc == null) return const [];
    try {
      final raw = await doc.loadOutline();
      return raw.map(_mapOutline).toList(growable: false);
    } catch (e, st) {
      Logger.m.w(
        '[GlobalPdfViewer] loadOutline failed',
        error: e,
        stackTrace: st,
      );
      return const [];
    }
  }

  PdfOutlineItem _mapOutline(pdfrx.PdfOutlineNode node) => PdfOutlineItem(
    title: node.title,
    pageNumber: node.dest?.pageNumber ?? 0,
    children: node.children.map(_mapOutline).toList(growable: false),
  );

  @override
  Future<Uint8List?> renderThumbnail(int page, {int maxWidth = 200}) async {
    final doc = _document;
    if (doc == null) return null;
    if (page < 1 || page > doc.pages.length) return null;
    try {
      final p = doc.pages[page - 1];
      final scale = maxWidth / p.width;
      final raster = await p.render(
        fullWidth: p.width * scale,
        fullHeight: p.height * scale,
      );
      if (raster == null) return null;
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        raster.pixels,
        raster.width,
        raster.height,
        ui.PixelFormat.bgra8888,
        completer.complete,
      );
      final image = await completer.future;
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      raster.dispose();
      return png?.buffer.asUint8List();
    } catch (e, st) {
      Logger.m.w(
        '[GlobalPdfViewer] renderThumbnail failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  bool isBookmarked(int page) => _bookmarks.isBookmarked(_persistKey, page);

  @override
  Future<void> toggleBookmark(int page) async {
    _bookmarks.toggle(_persistKey, page);
    if (mounted) setState(() {});
  }

  @override
  List<int> get bookmarks => _bookmarks.pagesFor(_persistKey);

  // ─── Rotation ────────────────────────────────────────────────

  @override
  Future<void> rotate({int deltaDeg = 90}) async {
    if (!mounted) return;
    setState(() => _rotation = (_rotation + deltaDeg) % 360);
    _emit();
  }

  // ─── Share / print / save-as ─────────────────────────────────

  Future<Uint8List?> _resolveBytes() async {
    if (_cachedBytes != null) return _cachedBytes;
    try {
      switch (widget.source.kind) {
        case PdfSourceKind.bytes:
          _cachedBytes = widget.source.bytes;
        case PdfSourceKind.file:
          _cachedBytes = await File(widget.source.value).readAsBytes();
        case PdfSourceKind.asset:
          final data = await rootBundle.load(widget.source.value);
          _cachedBytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
        case PdfSourceKind.url:
          final resp = await http.get(Uri.parse(widget.source.value));
          if (resp.statusCode >= 400) return null;
          _cachedBytes = resp.bodyBytes;
      }
    } catch (e, st) {
      Logger.m.w(
        '[GlobalPdfViewer] _resolveBytes failed',
        error: e,
        stackTrace: st,
      );
      return null;
    }
    final bytes = _cachedBytes;
    if (bytes != null) {
      _kPdfBytes[_persistKey] = bytes;
      while (_kPdfBytes.length > _kPdfBytesCacheEntries) {
        _kPdfBytes.remove(_kPdfBytes.keys.first);
      }
    }
    return bytes;
  }

  String _suggestedFilename() {
    final raw = widget.source.value;
    String base;
    switch (widget.source.kind) {
      case PdfSourceKind.url:
        base = Uri.tryParse(raw)?.pathSegments.lastOrNull ?? 'document';
      case PdfSourceKind.file:
        base = raw.split(Platform.pathSeparator).last;
      case PdfSourceKind.asset:
        base = raw.split('/').last;
      case PdfSourceKind.bytes:
        base = raw;
    }
    return base.toLowerCase().endsWith('.pdf') ? base : '$base.pdf';
  }

  @override
  Future<void> share({required Object shareTrigger}) async {
    final bytes = await _resolveBytes();
    if (bytes == null) return;
    final file = XFile.fromData(
      bytes,
      name: _suggestedFilename(),
      mimeType: 'application/pdf',
    );
    // Through the module, which serializes shares and puts every one
    // of them under a timeout.
    await GlobalShare.files(
      [file],
      subject: _docTitle ?? _suggestedFilename(),
    );
  }

  @override
  Future<void> printDocument() async {
    final bytes = await _resolveBytes();
    if (bytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _docTitle ?? _suggestedFilename(),
    );
  }

  @override
  Future<String?> saveAs() async {
    final bytes = await _resolveBytes();
    if (bytes == null) return null;
    final path = await FilePicker.saveFile(
      dialogTitle: PdfStrings.saveDialogTitle,
      fileName: _suggestedFilename(),
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      bytes: bytes,
    );
    return path;
  }

  // ─── Link handling ───────────────────────────────────────────

  Future<void> _onLinkTap(pdfrx.PdfLink link) async {
    // Internal jumps always work.
    if (link.dest != null) {
      await _controller.goToDest(link.dest);
      return;
    }
    // External URLs only when the caller opts in.
    final url = link.url;
    if (url == null || !_rs.openExternalLinks) return;
    try {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok) {
        Logger.m.w('[GlobalPdfViewer] launchUrl returned false for $url');
      }
    } catch (e, st) {
      Logger.m.w('[GlobalPdfViewer] link tap failed', error: e, stackTrace: st);
    }
  }

  // ─── Continuous layout ───────────────────────────────────────

  pdfrx.PdfPageLayout _continuousLayoutPages(
    List<pdfrx.PdfPage> pages,
    pdfrx.PdfViewerParams params,
  ) {
    // Single column, top-aligned, fixed page width (use the widest
    // page so every spread sits flush). Tight gap reads as a book.
    var width = 0.0;
    for (final p in pages) {
      if (p.width > width) width = p.width;
    }
    final layouts = <Rect>[];
    var y = params.margin;
    final gap = _rs.pageGap;
    for (final p in pages) {
      final x = (width - p.width) / 2 + params.margin;
      layouts.add(Rect.fromLTWH(x, y, p.width, p.height));
      y += p.height + gap;
    }
    return pdfrx.PdfPageLayout(
      pageLayouts: layouts,
      documentSize: Size(width + params.margin * 2, y - gap + params.margin),
    );
  }

  // ─── Build ───────────────────────────────────────────────────

  Widget _buildLoadingBanner(
    BuildContext context,
    int bytesDownloaded,
    int? totalBytes,
  ) {
    final pct = (totalBytes != null && totalBytes > 0)
        ? bytesDownloaded / totalBytes
        : null;
    // Cached-thumbnail bypass is handled by `_thumbOverlay` in the
    // variant builders — it overlays the live viewer + fades out
    // after the first page raster paints. The plain loading banner
    // below only runs when there's no cache yet.
    return _PdfLoadingBanner(
      progress: pct,
      background: _rs.background,
      accent: _rs.accent,
    );
  }

  Widget _buildErrorBanner(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
    pdfrx.PdfDocumentRef documentRef,
  ) {
    // Promote the error into snapshot state so callers can react.
    if (!_errored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _errored = true;
          _loading = false;
        });
        _emit();
      });
    }
    final bg = context.backgroundColors;
    final text = context.textColors;
    final is404 = error.toString().contains('404');
    final isEncrypted = _encrypted;
    final title = isEncrypted
        ? PdfStrings.passwordRequired
        : (is404 ? PdfStrings.notFound : PdfStrings.loadFailed);
    final detail = isEncrypted
        ? PdfStrings.encryptedDetail
        : (is404 ? PdfStrings.notFoundDetail : PdfStrings.loadFailedDetail);
    Logger.m.w('[GlobalPdfViewer] load failed: $error', stackTrace: stackTrace);
    return ColoredBox(
      color: bg.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEncrypted
                    ? Icons.lock_outline_rounded
                    : Icons.error_outline_rounded,
                color: context.statusColors.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: text.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: context.textTheme.bodyMedium?.fontSize,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  color: text.secondary,
                  fontSize: context.textTheme.bodySmall?.fontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reads a URL document once, then rebuilds into the real viewer.
  Future<void> _prefetchUrlBytes() async {
    if (_prefetching) return;
    _prefetching = true;
    final bytes = await _resolveBytes();
    if (!mounted) return;
    if (bytes == null) {
      setState(() {
        _errored = true;
        _loading = false;
      });
      _emit();
      return;
    }
    setState(() {});
  }

  Widget _buildViewer(BuildContext context) {
    final params = pdfrx.PdfViewerParams(
      backgroundColor: _rs.background,
      margin: _rs.pageGap,
      // Smart delegate fit-widths the page into the viewport. Without
      // it pdfrx lays pages at natural size which overflows tight
      // containers (compact / message variants).
      sizeDelegateProvider: const pdfrx.PdfViewerSizeDelegateProviderSmart(),
      onDocumentChanged: _onDocumentChanged,
      loadingBannerBuilder: _buildLoadingBanner,
      errorBannerBuilder: _buildErrorBanner,
      textSelectionParams: pdfrx.PdfTextSelectionParams(
        enabled: _rs.enableTextSelection,
      ),
      panEnabled: _rs.panEnabled,
      annotationRenderingMode: switch (_rs.annotationMode) {
        PdfAnnotationMode.none => pdfrx.PdfAnnotationRenderingMode.none,
        PdfAnnotationMode.annotations =>
          pdfrx.PdfAnnotationRenderingMode.annotation,
        PdfAnnotationMode.annotationsAndForms =>
          pdfrx.PdfAnnotationRenderingMode.annotationAndForms,
      },
      linkHandlerParams: pdfrx.PdfLinkHandlerParams(
        onLinkTap: _onLinkTap,
      ),
      layoutPages: widget.variant == PdfViewerVariant.continuous
          ? _continuousLayoutPages
          : null,
      onViewerReady: _onViewerReady,
      onPageChanged: _onPageChanged,
      matchTextColor: _rs.matchColor,
      activeMatchTextColor: _rs.activeMatchColor,
      pagePaintCallbacks: [
        // Lazy adapter — searcher is null until _onViewerReady. The
        // closure picks up the new instance once it lands.
        (canvas, pageRect, page) =>
            _searcher?.pageTextMatchPaintCallback(canvas, pageRect, page),
      ],
    );
    switch (widget.source.kind) {
      case PdfSourceKind.asset:
        return pdfrx.PdfViewer.asset(
          widget.source.value,
          controller: _controller,
          params: params,
          passwordProvider: _passwordProvider,
        );
      case PdfSourceKind.file:
        return pdfrx.PdfViewer.file(
          widget.source.value,
          controller: _controller,
          params: params,
          passwordProvider: _passwordProvider,
        );
      case PdfSourceKind.url:
        // OUR bytes, not pdfrx's fetch. Two viewers over one URL — a
        // compact card and the fullscreen route it opens — each asked
        // the network for the same document, so the hero flew and
        // landed on a loading banner. Downloading once and handing the
        // bytes on costs pdfrx's progressive rendering and buys a
        // transition that does not break.
        final bytes = _cachedBytes ?? _kPdfBytes[_persistKey];
        if (bytes == null) {
          unawaited(_prefetchUrlBytes());
          return _buildLoadingBanner(context, 0, null);
        }
        return pdfrx.PdfViewer.data(
          bytes,
          sourceName: _persistKey,
          controller: _controller,
          params: params,
          passwordProvider: _passwordProvider,
        );
      case PdfSourceKind.bytes:
        return pdfrx.PdfViewer.data(
          widget.source.bytes ?? Uint8List(0),
          sourceName: widget.source.value,
          controller: _controller,
          params: params,
          passwordProvider: _passwordProvider,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case PdfViewerVariant.compact:
        return _buildCompact(context);
      case PdfViewerVariant.full:
        return _buildFull(context);
      case PdfViewerVariant.continuous:
        return _buildContinuous(context);
      case PdfViewerVariant.custom:
        return widget.builder!(context, this, _buildViewer(context));
    }
  }

  Widget _buildCompact(BuildContext context) {
    final bg = context.backgroundColors;
    final style = _rs;
    final borderRadius = style.borderRadius;
    // Both ends derive the same tag from the document, so a preview
    // flies by default rather than only when a caller invented one.
    final heroTag = widget.enableHero
        ? (widget.heroTag ?? GlobalPdfViewer.defaultHeroTag(_persistKey))
        : null;
    // Default tap → push fullscreen viewer route. Caller can override
    // by supplying `onTapCompact`.
    final tap = widget.onTapCompact ?? () => _openDefaultFullscreen(context);

    // Built here and handed to the flight, so the bar does not pop into
    // existence the instant the flight ends.
    final label = _buildCompactLabel(context);

    Widget card = Container(
      height: style.compactHeight,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: borderRadius,
        border: Border.all(color: bg.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Live first-page render via the actual viewer — gives an
          // accurate preview without us re-rendering separately.
          Positioned.fill(
            child: ClipRect(
              child: _withThumbOverlay(
                _maybeRotate(_maybeInvert(context, _buildViewer(context))),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: label),
        ],
      ),
    );

    if (heroTag != null) {
      // Wrap in transparent Material so the text inside the card
      // (filename + page count) keeps its DefaultTextStyle ancestor
      // during Hero flight. Without this, text mid-flight falls back
      // to Flutter's debug "red double-underline" style.
      card = Hero(
        tag: heroTag,
        // The CARD defines the flight in BOTH directions — the
        // fullscreen end deliberately supplies no builder, so this one
        // wins going out (as the source) and coming back (as the
        // destination). It is the end with chrome to reconcile, and one
        // definition cannot disagree with itself.
        flightShuttleBuilder: pdfHeroShuttleFor(
          _persistKey,
          style.background,
          borderRadius: borderRadius,
          borderColor: bg.outlineVariant,
          label: label,
        ),
        child: Material(type: MaterialType.transparency, child: card),
      );
    }
    // The viewer swallows pointers, so an `InkWell` wrapped around the
    // card only ever heard the strip of chrome outside it. Absorbing
    // inside the tap target hands every pixel of the preview back.
    //
    // ONE node, and everything under it excluded. A preview is a button
    // however much is drawn on it, and the live viewer beneath publishes
    // a tree of its own — pages, a scroll view, selectable text — none
    // of which can be acted on here.
    return ExcludeSemantics(
      child: InkWell(
        onTap: tap,
        borderRadius: borderRadius,
        child: AbsorbPointer(child: card),
      ),
    ).semantics(
      button: true,
      label: PdfStrings.openDocument(_displayName()),
      value: _pageCount > 0 ? PdfStrings.pageCount(_pageCount) : null,
      onTap: tap,
    );
  }

  /// The card's bottom bar — a scrim, the file name and the page count.
  ///
  /// Extracted because the hero flight needs the SAME instance: built
  /// only inside the card, it appeared the instant the flight ended,
  /// which is a bar snapping into place over a page that had just
  /// finished moving.
  Widget _buildCompactLabel(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.picture_as_pdf_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _displayName(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: context.textTheme.bodySmall?.fontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_pageCount > 0)
          Text(
            PdfStrings.pageCountShort(_pageCount),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
              fontSize: context.textTheme.labelSmall?.fontSize,
            ),
          ),
      ],
    ),
  );

  void _openDefaultFullscreen(BuildContext context) {
    // Hand the BYTES over when we already have them.
    //
    // The destination used to be given the same URL and fetch it a
    // second time, so the hero flew and then landed on a viewer that
    // was still loading — the seam a hero exists to hide. The label
    // carries the persist key so bookmarks, the last-read page and the
    // thumbnail cache all still resolve to the same document.
    final cached = _cachedBytes ?? _kPdfBytes[_persistKey];
    final source = cached == null
        ? widget.source
        : PdfSourceSpec.bytes(
            cached,
            label: _persistKey,
            password: widget.source.password,
          );

    unawaited(
      GlobalPdfViewer.openFullscreen(
        context,
        source: source,
        fileName: _displayName(),
        style: widget.style,
        heroTag: widget.heroTag,
        enableHero: widget.enableHero,
        onPasswordRequired: widget.onPasswordRequired,
      ),
    );
  }

  /// Reaches the bottom bar's search row for ⌘F and Esc.
  final _barKey = GlobalKey<_BottomBarState>();

  /// Wraps a viewer in its keyboard shortcuts.
  ///
  /// ALWAYS on, not gated to desktop. A tablet with a keyboard attached
  /// is the case gating would break, and on a device with no keyboard
  /// there is nothing to intercept — the platform check the plan called
  /// for would only ever have removed working behaviour.
  ///
  /// Single-letter shortcuts are refused while the search row is open,
  /// so typing "rotate" into it does not rotate the page five times.
  /// The modifier ones stay live, because ⌘F while already searching is
  /// how every other application re-focuses the field.
  Widget _withShortcuts(Widget child) {
    if (!widget.enableKeyboardShortcuts) return child;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowRight): _PdfShortcutIntent(
          PdfShortcutCommand.nextPage,
        ),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PdfShortcutIntent(
          PdfShortcutCommand.prevPage,
        ),
        SingleActivator(LogicalKeyboardKey.pageDown): _PdfShortcutIntent(
          PdfShortcutCommand.nextPage,
        ),
        SingleActivator(LogicalKeyboardKey.pageUp): _PdfShortcutIntent(
          PdfShortcutCommand.prevPage,
        ),
        // Both the shifted and unshifted glyph: "+" is shift-equals on
        // most layouts, and a reader pressing it means zoom either way.
        SingleActivator(LogicalKeyboardKey.equal): _PdfShortcutIntent(
          PdfShortcutCommand.zoomIn,
        ),
        SingleActivator(LogicalKeyboardKey.add): _PdfShortcutIntent(
          PdfShortcutCommand.zoomIn,
        ),
        SingleActivator(LogicalKeyboardKey.minus): _PdfShortcutIntent(
          PdfShortcutCommand.zoomOut,
        ),
        SingleActivator(LogicalKeyboardKey.numpadSubtract): _PdfShortcutIntent(
          PdfShortcutCommand.zoomOut,
        ),
        SingleActivator(LogicalKeyboardKey.digit0, control: true):
            _PdfShortcutIntent(PdfShortcutCommand.resetZoom),
        SingleActivator(LogicalKeyboardKey.digit0, meta: true):
            _PdfShortcutIntent(PdfShortcutCommand.resetZoom),
        SingleActivator(LogicalKeyboardKey.keyR): _PdfShortcutIntent(
          PdfShortcutCommand.rotate,
        ),
        // Control AND meta, rather than a platform switch: a Mac
        // keyboard on Linux and a PC keyboard on a Mac both exist.
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _PdfShortcutIntent(PdfShortcutCommand.search),
        SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _PdfShortcutIntent(PdfShortcutCommand.search),
        SingleActivator(LogicalKeyboardKey.keyP, control: true):
            _PdfShortcutIntent(PdfShortcutCommand.print),
        SingleActivator(LogicalKeyboardKey.keyP, meta: true):
            _PdfShortcutIntent(PdfShortcutCommand.print),
        SingleActivator(LogicalKeyboardKey.escape): _PdfShortcutIntent(
          PdfShortcutCommand.escape,
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PdfShortcutIntent: CallbackAction<_PdfShortcutIntent>(
            onInvoke: (intent) => runPdfShortcut(intent.command),
          ),
        },
        // Autofocus once, at mount: the search field asks for focus
        // when it opens, and that is later, so this cannot take it back.
        child: Focus(autofocus: true, child: child),
      ),
    );
  }

  /// Runs one shortcut. Separated from the key map so a test can drive
  /// a command without synthesising a key event on a viewer that needs
  /// a real engine to build.
  @visibleForTesting
  Object? runPdfShortcut(PdfShortcutCommand command) {
    final searchOpen = _barKey.currentState?.isSearchOpen ?? false;
    // A letter typed into the search row belongs to the search row.
    if (searchOpen && command.isBareKey) return null;

    switch (command) {
      case PdfShortcutCommand.nextPage:
        unawaited(nextPage());
      case PdfShortcutCommand.prevPage:
        unawaited(prevPage());
      case PdfShortcutCommand.zoomIn:
        unawaited(zoomIn());
      case PdfShortcutCommand.zoomOut:
        unawaited(zoomOut());
      case PdfShortcutCommand.resetZoom:
        unawaited(resetZoom());
      case PdfShortcutCommand.rotate:
        unawaited(rotate());
      case PdfShortcutCommand.search:
        _barKey.currentState?.openSearchFromShortcut();
      case PdfShortcutCommand.print:
        unawaited(printDocument());
      case PdfShortcutCommand.escape:
        _barKey.currentState?.closeSearchFromShortcut();
    }
    return null;
  }

  Widget _buildFull(BuildContext context) {
    final style = _rs;
    final padding = style.padding;
    final borderRadius = style.borderRadius;
    final controls = style.controlsColor;

    final body = Column(
      children: [
        Expanded(
          child: ClipRect(
            child: _withThumbOverlay(
              _maybeRotate(_maybeInvert(context, _buildViewer(context))),
            ),
          ),
        ),
        if (style.showThumbnailStrip)
          _ThumbnailStrip(
            handle: this,
            height: style.thumbnailStripHeight,
            accent: style.accent,
          ),
        _BottomBar(
          key: _barKey,
          handle: this,
          style: style,
          controls: controls,
        ),
      ],
    );

    return _withShortcuts(
      ClipRRect(
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: body),
      ),
    );
  }

  Widget _buildContinuous(BuildContext context) {
    // Continuous uses the same chrome as full — pdfrx's
    // `layoutPages` function (set in `_buildViewer`'s params for
    // continuous variant) handles the actual book-style stacking.
    return _buildFull(context);
  }

  /// Wraps the viewer in a ColorFiltered for cheap "night mode" when
  /// the app is in dark theme + the caller opted in.
  /// Night mode without turning the photographs into negatives.
  ///
  /// A plain inversion flips EVERY pixel, so a page of text reads
  /// beautifully and every picture on it becomes a negative. Inverting
  /// and then rotating the hue by half a turn puts the colours back
  /// roughly where they started while keeping the lightness flipped —
  /// the same trick CSS calls `invert(1) hue-rotate(180deg)` and what
  /// iOS means by "Smart Invert". Text still goes white-on-black;
  /// a photograph comes back close to itself.
  ///
  /// An approximation, not a segmentation: strongly saturated flat
  /// artwork still shifts. Doing it properly means knowing which parts
  /// of the page are images, which the raster does not tell us.
  Widget _maybeInvert(BuildContext context, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!_rs.invertColorsInDark || !isDark) return child;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(pdfSmartInvertMatrix),
      child: child,
    );
  }

  /// Stacks a cached page-1 thumbnail on top of the live viewer
  /// when one exists for this source. Fades out via AnimatedOpacity
  /// after the document reports loaded — masks the loading flash
  /// that pdfrx exposes when re-rastering a freshly-mounted viewer.
  /// No-op when no cache exists (first-ever viewer for the source).
  Widget _withThumbOverlay(Widget child) {
    final cached = _kPdfHeroThumbs[_persistKey];
    if (cached == null) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _thumbOverlayVisible ? 1 : 0,
            // Matches Hero flight tail — fade ends ~together with the
            // route transition so it doesn't read as a second motion.
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            // Width-fitted from the TOP, because that is where the
            // live viewer puts page one. Contain-fitted it was centred
            // and scaled to the whole box, so the cross-fade swapped
            // one framing for another — the "it loaded again" flicker
            // at the end of the flight was the still frame and the
            // real page not being the same size.
            child: pdfStillFrame(
              background: _rs.background,
              page: Image.memory(
                cached,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Applies the current whole-view rotation. Wraps the child in a
  /// rotated transform so 90/270 also swap visible width/height via
  /// an outer FittedBox.
  /// The whole-view rotation, TURNED rather than jumped.
  ///
  /// It used to snap between quarter turns, which reads as the page
  /// being replaced rather than rotated — the one moment where the
  /// motion is the entire point of the control.
  ///
  /// The BOX swaps instantly and the contents turn: animating the box
  /// as well makes the page shear as it goes, because the two are
  /// interpolating on different curves.
  Widget _maybeRotate(Widget child) {
    final swap = _rotation % 180 != 0;
    return LayoutBuilder(
      builder: (context, c) {
        final w = swap ? c.maxHeight : c.maxWidth;
        final h = swap ? c.maxWidth : c.maxHeight;
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: _rotation * math.pi / 180),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppDurations.normal,
              curve: Curves.easeInOutCubic,
              builder: (context, angle, child) =>
                  Transform.rotate(angle: angle, child: child),
              child: child,
            ),
          ),
        );
      },
    );
  }

  String _displayName() => _fileNameFor(widget.source);
}

// ─── Loading ───────────────────────────────────────────────────

/// What a document looks like while it is on its way.
///
/// A spinner that appears and vanishes inside a few frames reads as a
/// GLITCH, not as progress — the flash is worse than the wait it was
/// covering. So: NOTHING for the first `placeholderDelay`, and only
/// then a page-shaped shimmer. The same gate `GlobalImage` applies, for
/// the same reason.
///
/// A spinner is what this used to show from frame one, and a spinner is
/// also the wrong SHAPE: it says "something is happening" where a
/// shimmer says "a page is coming". The determinate bar comes back the
/// moment there is a real percentage to report — a download with a
/// known length — because then there is something better to say than
/// "soon".
class _PdfLoadingBanner extends StatefulWidget {
  const _PdfLoadingBanner({
    required this.progress,
    required this.background,
    required this.accent,
  });

  /// 0..1 when the transfer knows its own length, else null.
  final double? progress;
  final Color background;
  final Color accent;

  @override
  State<_PdfLoadingBanner> createState() => _PdfLoadingBannerState();
}

class _PdfLoadingBannerState extends State<_PdfLoadingBanner> {
  Timer? _delay;
  bool _due = false;

  @override
  void initState() {
    super.initState();
    _delay = Timer(
      ImageDefaults.placeholderDelay,
      () => mounted ? setState(() => _due = true) : null,
    );
  }

  @override
  void dispose() {
    _delay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_due) return ColoredBox(color: widget.background);

    final progress = widget.progress;
    return ColoredBox(
      color: widget.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // FILLS the surface. Inset inside a padding it read as a card
          // floating on a background rather than as the page itself
          // arriving — the shimmer has to occupy the space the page
          // will, or it is not standing in for anything.
          const GlobalShimmer(
            borderRadius: BorderRadius.zero,
            child: SizedBox.expand(),
          ),
          // Over the shimmer, not stacked above it: a bar in a column
          // would push the placeholder out of the shape it is holding.
          if (progress != null)
            Positioned(
              left: context.spacing.lg,
              right: context.spacing.lg,
              bottom: context.spacing.lg,
              child: GlobalProgress.linear(
                value: progress,
                semanticLabel: CommonStrings.loading,
                style: ProgressStyle(color: widget.accent, showLabel: true),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Bottom bar (full variant) ─────────────────────────────────

/// Which control groups fit into [budget], by index.
///
/// Split out and pure because it is the whole of the bar's behaviour
/// and none of its rendering — the viewer needs a real PDF engine to
/// build at all, so a test that drove the widget could not reach this.
///
/// A group is taken WHOLE or not at all: `slots` is how many button
/// widths it needs, and a two-slot zoom pair either gets both or goes
/// to the overflow menu. Hiding buttons one at a time is what left a
/// minus with no plus.
///
/// Later groups are still considered after an earlier one is dropped —
/// a wide group failing must not strand the narrow ones behind it.
///
/// [budget] must already have the overflow button's own width taken
/// out: dropping a control to make room for the button that holds it
/// would be the wrong way round.
@visibleForTesting
List<int> pdfBarFit({
  required double budget,
  required List<int> slots,
  required double unit,
}) => barFit(budget: budget, slots: slots, unit: unit);

/// One control, or a set of controls that only make sense together.
///
/// A zoom-in with no zoom-out is a broken control, not a compact one —
/// which is what hiding buttons one at a time produced. A group is
/// shown whole or moved into the overflow menu whole.
@immutable
class _BarGroup {
  const _BarGroup({
    required this.slots,
    required this.bar,
    required this.menu,
  });

  /// How many button-widths this group occupies.
  final int slots;

  /// What it looks like on the bar.
  final List<Widget> bar;

  /// And in the overflow menu when it does not fit.
  final List<GlobalPopupMenuItem<String>> menu;
}

class _BottomBar extends StatefulWidget {
  const _BottomBar({
    super.key,
    required this.handle,
    required this.style,
    required this.controls,
  });

  final PdfHandle handle;
  final ResolvedPdfStyle style;
  final Color controls;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  bool _searchOpen = false;

  /// A system intent is in flight — share, print or save-as.
  ///
  /// Each has to read the whole document off the network or off disk
  /// before the OS sheet can open, which on a 5MB file is a second or
  /// two of a screen that looks like it ignored the tap. The overflow
  /// glyph becomes a spinner for exactly that gap.
  bool _busy = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Opens/closes the search row. On open, focuses the field once it
  /// has mounted — replaces the raw TextField's `autofocus: true`.
  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchOpen) _searchFocus.requestFocus();
    });
  }

  /// Reached from the viewer ABOVE this bar, which owns the keyboard
  /// shortcuts but not the search row's state. A key rather than
  /// hoisting the state: the row is the bar's business, and ⌘F is the
  /// only thing outside it that has an opinion.
  void openSearchFromShortcut() {
    if (_searchOpen) {
      _searchFocus.requestFocus();
      return;
    }
    _toggleSearch();
  }

  /// Esc. Returns whether there was anything to close, so the key can
  /// fall through to whatever else wants it when search is not open.
  bool closeSearchFromShortcut() {
    if (!_searchOpen) return false;
    _toggleSearch();
    unawaited(widget.handle.clearSearch());
    return true;
  }

  bool get isSearchOpen => _searchOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PdfStateSnapshot>(
      stream: widget.handle.stateStream,
      initialData: widget.handle.state,
      builder: (context, snap) {
        final s = snap.data!;
        final style = widget.style;
        final color = widget.controls;
        return Material(
          color: style.background,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchOpen)
                  _SearchRow(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    state: s,
                    onChanged: (v) => widget.handle.search(v),
                    onNext: () => widget.handle.nextMatch(),
                    onPrev: () => widget.handle.prevMatch(),
                    onClose: () {
                      widget.handle.clearSearch();
                      setState(() => _searchOpen = false);
                    },
                  ),
                LayoutBuilder(
                  builder: (context, c) =>
                      _buildBar(context, c, s, style, color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The transport bar, laid out by what actually FITS.
  ///
  /// It used to hide controls one at a time under a single width
  /// threshold, which left the zoom pair half-present — a minus with no
  /// plus — and still overflowed, because the zoom buttons were the two
  /// that never took the compact sizing. Controls are declared as
  /// GROUPS now: a group is shown whole or not at all, and everything
  /// dropped moves into the overflow menu rather than disappearing.
  Widget _buildBar(
    BuildContext context,
    BoxConstraints c,
    PdfStateSnapshot s,
    ResolvedPdfStyle style,
    Color color,
  ) {
    // Compact sizing shrinks what a button PAINTS. It used to shrink
    // the touch target with it — 40dp, on exactly the narrow screens
    // where a control is hardest to hit — and the width that bought was
    // width taken off a finger.
    //
    // The target stays 48 and the cell it occupies stays 48, so tight
    // mode is now a density, not a saving. What pays for a narrow bar
    // instead is the overflow menu, which is what it is for: a control
    // reachable at full size in a menu beats one on the bar too small
    // to press.
    final tight = c.maxWidth < _kPdfTightBarWidth;
    const unit = _kPdfBarButton;
    final horizontal = tight ? 4.0 : 12.0;

    ButtonStateStyle barButton(Color fg) => ButtonStateStyle(
      foregroundColor: fg,
      width: tight ? _kPdfTightBarButton : null,
      height: tight ? _kPdfTightBarButton : null,
    );

    Widget iconButton(
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      Color? tint,
    }) => GlobalIconButton(
      tooltip: tooltip,
      iconData: icon,
      onPressed: onPressed,
      style: barButton(tint ?? color),
    );

    final bookmarked = widget.handle.isBookmarked(s.pageNumber);

    // Ordered by what a reader gives up LAST. Paging is the one control
    // a pager cannot be without, so it is not in the droppable set at
    // all — it is pinned below.
    final groups = <_BarGroup>[
      if (style.showZoomControls)
        _BarGroup(
          slots: 2,
          bar: [
            iconButton(
              Icons.remove_circle_outline_rounded,
              PdfStrings.zoomOut,
              widget.handle.zoomOut,
            ),
            iconButton(
              Icons.add_circle_outline_rounded,
              PdfStrings.zoomIn,
              widget.handle.zoomIn,
            ),
          ],
          menu: [
            GlobalPopupMenuItem(
              value: 'zoomIn',
              label: PdfStrings.zoomIn,
              icon: Icons.add_circle_outline_rounded,
            ),
            GlobalPopupMenuItem(
              value: 'zoomOut',
              label: PdfStrings.zoomOut,
              icon: Icons.remove_circle_outline_rounded,
            ),
          ],
        ),
      if (style.showRotateButton)
        _BarGroup(
          slots: 1,
          bar: [
            iconButton(
              Icons.rotate_90_degrees_cw_rounded,
              PdfStrings.rotate90,
              widget.handle.rotate,
            ),
          ],
          menu: [
            GlobalPopupMenuItem(
              value: 'rotate',
              label: PdfStrings.rotate90,
              icon: Icons.rotate_90_degrees_cw_rounded,
            ),
          ],
        ),
      if (style.showOutlineButton)
        _BarGroup(
          slots: 1,
          bar: [
            iconButton(
              Icons.list_alt_rounded,
              PdfStrings.outline,
              () => _openOutline(context),
            ),
          ],
          menu: [
            GlobalPopupMenuItem(
              value: 'outline',
              label: PdfStrings.outline,
              icon: Icons.list_alt_rounded,
            ),
          ],
        ),
      _BarGroup(
        slots: 1,
        bar: [
          GestureDetector(
            onLongPress: () => _openBookmarksList(context),
            child: iconButton(
              bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_outline_rounded,
              '${bookmarked ? PdfStrings.removeBookmark : PdfStrings.bookmarkPage}'
              ' · ${PdfStrings.bookmarkListHint}',
              s.pageNumber > 0
                  ? () => widget.handle.toggleBookmark(s.pageNumber)
                  : null,
              tint: bookmarked ? style.accent : color,
            ),
          ),
        ],
        menu: [
          GlobalPopupMenuItem(
            value: 'bookmark',
            label: bookmarked
                ? PdfStrings.removeBookmark
                : PdfStrings.bookmarkPage,
            icon: bookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
          ),
          GlobalPopupMenuItem(
            value: 'bookmarks',
            label: PdfStrings.bookmarks,
            icon: Icons.collections_bookmark_outlined,
          ),
        ],
      ),
      if (style.showSearchButton)
        _BarGroup(
          slots: 1,
          bar: [
            iconButton(
              Icons.search_rounded,
              CommonStrings.search,
              _toggleSearch,
            ),
          ],
          menu: [
            GlobalPopupMenuItem(
              value: 'search',
              label: CommonStrings.search,
              icon: Icons.search_rounded,
            ),
          ],
        ),
    ];

    // Paging, plus the overflow button itself when there is one.
    final pagingSlots = style.showPageIndicator ? 2 : 0;
    final pageLabel = style.showPageIndicator && !tight;
    final fixed =
        pagingSlots * unit +
        (pageLabel ? _kPdfPageLabelWidth : 0) +
        horizontal * 2;

    final fits = pdfBarFit(
      budget: c.maxWidth - fixed - unit,
      slots: [for (final g in groups) g.slots],
      unit: unit,
    );
    final shown = [for (final i in fits) groups[i]];
    final hidden = [
      for (var i = 0; i < groups.length; i++)
        if (!fits.contains(i)) groups[i],
    ];

    final overflow = [
      for (final group in hidden) ...group.menu,
      GlobalPopupMenuItem(
        value: 'share',
        label: CommonStrings.share,
        icon: Icons.share_rounded,
      ),
      GlobalPopupMenuItem(
        value: 'print',
        label: PdfStrings.print,
        icon: Icons.print_rounded,
      ),
      GlobalPopupMenuItem(
        value: 'save',
        label: PdfStrings.saveAs,
        icon: Icons.save_alt_rounded,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 6),
      child: Row(
        children: [
          for (final group in shown) ...group.bar,
          if (style.showActionsMenu)
            GlobalPopup.menu<String>(
              tooltip: ButtonStrings.moreTooltip,
              onSelected: (v) => _onOverflow(context, v),
              items: overflow,
              anchor: _busy
                  ? SizedBox(
                      width: unit,
                      height: unit,
                      child: Center(
                        child: SizedBox.square(
                          dimension: _kPdfBusySpinner,
                          child: GlobalProgress.loading(
                            type: ProgressType.circular,
                            semanticLabel: CommonStrings.loading,
                            style: ProgressStyle(
                              thickness: 2,
                              color: color,
                              // No grace period: the tap is the reason
                              // it is here, so it has to answer at once.
                              appearAfter: Duration.zero,
                            ),
                          ),
                        ),
                      ),
                    )
                  : iconButton(
                      Icons.more_horiz_rounded,
                      ButtonStrings.moreTooltip,
                      null,
                    ),
            ),
          const Spacer(),
          if (style.showPageIndicator) ...[
            iconButton(
              Icons.chevron_left_rounded,
              PdfStrings.previousPage,
              s.pageNumber > 1 ? widget.handle.prevPage : null,
            ),
            if (pageLabel)
              // "3 / 128" is read out as two numbers and a slash, and
              // it is also a BUTTON — nothing about the bare text says
              // that tapping it jumps to a page.
              InkWell(
                onTap: s.pageCount > 0
                    ? () => _openJumpToPage(context, s)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    s.pageCount > 0 ? '${s.pageNumber} / ${s.pageCount}' : '—',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: context.textTheme.bodySmall?.fontSize,
                    ),
                  ).excludeFromSemantics(),
                ),
              ).semantics(
                button: s.pageCount > 0,
                label: s.pageCount > 0
                    ? PdfStrings.pageOf(s.pageNumber, s.pageCount)
                    : PdfStrings.jumpToPage,
                hint: s.pageCount > 0 ? PdfStrings.jumpToPage : null,
                // The page it names changes under a reader who did not
                // ask for it — a swipe, a bookmark, a link.
                liveRegion: true,
              ),
            iconButton(
              Icons.chevron_right_rounded,
              PdfStrings.nextPage,
              s.pageNumber < s.pageCount ? widget.handle.nextPage : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Runs a system intent with the bar showing that it is working.
  Future<void> _runSystemIntent(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onOverflow(BuildContext context, String value) {
    switch (value) {
      case 'zoomIn':
        widget.handle.zoomIn();
      case 'zoomOut':
        widget.handle.zoomOut();
      case 'rotate':
        widget.handle.rotate();
      case 'outline':
        _openOutline(context);
      case 'search':
        _toggleSearch();
      case 'bookmark':
        widget.handle.toggleBookmark(widget.handle.state.pageNumber);
      case 'bookmarks':
        _openBookmarksList(context);
      case 'share':
        unawaited(
          _runSystemIntent(() => widget.handle.share(shareTrigger: context)),
        );
      case 'print':
        unawaited(_runSystemIntent(widget.handle.printDocument));
      case 'save':
        unawaited(_runSystemIntent(widget.handle.saveAs));
    }
  }

  Future<void> _openJumpToPage(BuildContext context, PdfStateSnapshot s) async {
    final result = await GlobalDialog.builder<int>(
      context,
      builder: (ctx) {
        var page = s.pageNumber;
        return Padding(
          padding: EdgeInsets.all(ctx.spacing.lg),
          child: StatefulBuilder(
            builder: (ctx, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(PdfStrings.jumpToPage, style: ctx.textTheme.titleLarge),
                SizedBox(height: ctx.spacing.md),
                Slider(
                  value: page.toDouble(),
                  min: 1,
                  max: s.pageCount.toDouble(),
                  divisions: s.pageCount - 1,
                  label: '$page',
                  onChanged: (v) => setSt(() => page = v.round()),
                ),
                Center(child: Text(PdfStrings.pageOf(page, s.pageCount))),
                SizedBox(height: ctx.spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlobalTextButton(
                      text: CommonStrings.cancel,
                      shrinkWidth: true,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    SizedBox(width: ctx.spacing.sm),
                    GlobalFilledButton(
                      text: PdfStrings.go,
                      shrinkWidth: true,
                      onPressed: () => Navigator.of(ctx).pop(page),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) await widget.handle.goToPage(result);
  }

  Future<void> _openBookmarksList(BuildContext context) async {
    final pages = widget.handle.bookmarks;
    if (!context.mounted) return;
    await GlobalBottomSheet.show<void>(
      context: context,
      title: PdfStrings.bookmarks,
      subtitle: pages.isEmpty ? null : '${pages.length} pages',
      icon: Icons.bookmark_rounded,
      style: const SheetStyle(floating: true),
      content: pages.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(PdfStrings.noBookmarks),
              ),
            )
          : Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in pages)
                    GlobalContainer.tile(
                      leading: const Icon(Icons.bookmark_rounded),
                      titleWidget: Text(PdfStrings.pageNumber(p)),
                      trailing: GlobalIconButton(
                        iconData: Icons.close_rounded,
                        tooltip: PdfStrings.removeBookmark,
                        onPressed: () async {
                          await widget.handle.toggleBookmark(p);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.handle.goToPage(p);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _openOutline(BuildContext context) async {
    final outline = await widget.handle.loadOutline();
    if (!context.mounted) return;
    await GlobalBottomSheet.show<void>(
      context: context,
      title: PdfStrings.outline,
      subtitle: outline.isEmpty ? null : '${_countNodes(outline)} entries',
      icon: Icons.list_alt_rounded,
      style: const SheetStyle(floating: true),
      content: outline.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(PdfStrings.noOutline)),
            )
          : Material(
              // `_SheetContainer` paints a plain Container — there's
              // no Material ancestor for ListTile's InkWell to render
              // its splash through. Wrap with a transparent Material
              // so taps highlight correctly.
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _outlineTiles(context, outline, depth: 0),
              ),
            ),
    );
  }

  int _countNodes(List<PdfOutlineItem> nodes) {
    var n = 0;
    for (final node in nodes) {
      n += 1 + _countNodes(node.children);
    }
    return n;
  }

  List<Widget> _outlineTiles(
    BuildContext context,
    List<PdfOutlineItem> items, {
    required int depth,
  }) {
    final out = <Widget>[];
    for (final item in items) {
      out.add(
        GlobalContainer.tile(
          // The outline's indent, which used to be `contentPadding`.
          style: ContainerStyle(
            padding: EdgeInsetsDirectional.only(
              start: 16.0 + depth * 16,
              end: 16,
            ).resolve(Directionality.of(context)),
            shadow: const [],
            backgroundColor: const Color(0x00000000),
          ),
          titleWidget: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: item.pageNumber > 0
              ? Text(PdfStrings.pageNumber(item.pageNumber))
              : null,
          onTap: item.pageNumber > 0
              ? () {
                  Navigator.of(context).pop();
                  widget.handle.goToPage(item.pageNumber);
                }
              : null,
        ),
      );
      if (item.children.isNotEmpty) {
        out.addAll(_outlineTiles(context, item.children, depth: depth + 1));
      }
    }
    return out;
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.state,
    required this.onChanged,
    required this.onNext,
    required this.onPrev,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final PdfStateSnapshot state;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = context.textColors;
    return Padding(
      // Even top and bottom: it was 6 above and 0 below, so the row sat
      // hard against the transport bar under it.
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchTextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: (_) => onNext(),
              isLoading: state.searching,
              // In-document search filtered per keystroke before the
              // sweep; keep it instant (the 250ms default raced Enter).
              debounce: Duration.zero,
            ),
          ),
          const SizedBox(width: _kPdfSearchGap),
          // FIXED width, centred. It swings between "—", "…", "1 / 3"
          // and "128 / 660", and left to size itself every one of those
          // shoved the three buttons beside it to a different place —
          // which is what made the row look mis-spaced as you typed.
          SizedBox(
            width: _kPdfMatchCounterWidth,
            child: Text(
              state.matchCount > 0
                  ? '${state.currentMatchIndex + 1} / ${state.matchCount}'
                  : (state.searching ? '…' : '—'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text.secondary,
                fontWeight: FontWeight.w600,
                fontSize: context.textTheme.bodySmall?.fontSize,
              ),
            ).excludeFromSemantics(),
            // A dash and an ellipsis are typography, not an answer. The
            // count is also the only thing that reports whether a search
            // found anything, so it announces itself as it changes.
          ).semantics(
            liveRegion: true,
            label: state.matchCount > 0
                ? PdfStrings.matchOf(
                    state.currentMatchIndex + 1,
                    state.matchCount,
                  )
                : (state.searching
                      ? PdfStrings.searching
                      : PdfStrings.noMatches),
          ),
          const SizedBox(width: _kPdfSearchGap),
          GlobalIconButton(
            iconData: Icons.keyboard_arrow_up_rounded,
            tooltip: PdfStrings.previousMatch,
            onPressed: state.matchCount > 0 ? onPrev : null,
          ),
          GlobalIconButton(
            iconData: Icons.keyboard_arrow_down_rounded,
            tooltip: PdfStrings.nextMatch,
            onPressed: state.matchCount > 0 ? onNext : null,
          ),
          GlobalIconButton(
            iconData: Icons.close_rounded,
            tooltip: CommonStrings.close,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─── Thumbnail strip ───────────────────────────────────────────

/// Horizontal scroll of page thumbnails. Tap to jump. Uses
/// [PdfHandle.renderThumbnail] under the hood (caches per-page
/// inside this widget — a fresh strip mount triggers re-renders).
class _ThumbnailStrip extends StatefulWidget {
  const _ThumbnailStrip({
    required this.handle,
    required this.height,
    required this.accent,
  });

  final PdfHandle handle;
  final double height;
  final Color accent;

  @override
  State<_ThumbnailStrip> createState() => _ThumbnailStripState();
}

class _ThumbnailStripState extends State<_ThumbnailStrip> {
  final _cache = <int, Uint8List?>{};

  Future<Uint8List?> _thumbFor(int page) async {
    if (_cache.containsKey(page)) return _cache[page];
    final bytes = await widget.handle.renderThumbnail(
      page,
      maxWidth: (widget.height * 1.4).round(),
    );
    if (mounted) setState(() => _cache[page] = bytes);
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PdfStateSnapshot>(
      stream: widget.handle.stateStream,
      initialData: widget.handle.state,
      builder: (context, snap) {
        final s = snap.data!;
        if (s.pageCount <= 0) return SizedBox(height: widget.height);
        final bg = context.backgroundColors;
        final text = context.textColors;
        return SizedBox(
          height: widget.height,
          child: ColoredBox(
            // The SURFACE, not the container. In dark the container is
            // a deep navy that reads as a different app behind the
            // pages rather than as a strip belonging to the viewer —
            // the pages are white and it framed them in something
            // nothing else on the screen was.
            color: bg.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: s.pageCount,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final page = i + 1;
                final isCurrent = page == s.pageNumber;
                return GestureDetector(
                  onTap: () => widget.handle.goToPage(page),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isCurrent ? widget.accent : bg.outlineVariant,
                        width: isCurrent ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: 0.72,
                      child: FutureBuilder<Uint8List?>(
                        future: _thumbFor(page),
                        builder: (context, snap) {
                          if (snap.data == null) {
                            return ColoredBox(
                              color: bg.container,
                              child: Center(
                                child: Text(
                                  '$page',
                                  style: TextStyle(
                                    color: text.secondary,
                                    fontSize:
                                        context.textTheme.labelSmall?.fontSize,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Image.memory(
                            snap.data!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Fullscreen route
// ---------------------------------------------------------------------------

/// The default destination for a compact card's tap.
///
/// A widget rather than an inline `Scaffold` so the bar can carry the
/// page count, which it could not before.
///
/// The FILE NAME is the title, cleaned up. Reaching for the document's
/// own `/Info` title first was the obvious idea and the wrong one: half
/// the PDFs in the world have `Title: PDF`, or the name of whatever
/// exported them, or an empty string that is not quite empty. The file
/// name is what the reader clicked on, so it is what they are looking
/// for at the top of the screen.
class _PdfFullscreenRoute extends StatefulWidget {
  const _PdfFullscreenRoute({
    required this.source,
    required this.fileName,
    required this.style,
    this.heroTag,
    this.onPasswordRequired,
  });

  final PdfSourceSpec source;
  final String fileName;
  final PdfStyle style;
  final Object? heroTag;
  final PdfPasswordCallback? onPasswordRequired;

  @override
  State<_PdfFullscreenRoute> createState() => _PdfFullscreenRouteState();
}

class _PdfFullscreenRouteState extends State<_PdfFullscreenRoute> {
  PdfStateSnapshot _state = PdfStateSnapshot.empty;

  String get _title => pdfDisplayTitle(widget.fileName);

  @override
  Widget build(BuildContext context) {
    final pages = _state.pageCount;

    final viewer = GlobalPdfViewer(
      source: widget.source,
      variant: PdfViewerVariant.full,
      style: widget.style,
      onPasswordRequired: widget.onPasswordRequired,
      onStateChanged: (s) {
        // Only the part the bar shows, or every page turn rebuilds it.
        if (s.pageCount == _state.pageCount) return;
        if (mounted) setState(() => _state = s);
      },
    );

    return Scaffold(
      appBar: GlobalAppBar(
        title: _title,
        subtitle: pages > 0 ? PdfStrings.pageCount(pages) : null,
        style: const AppBarStyle(centerTitle: true),
      ),
      body: widget.heroTag == null
          ? viewer
          // No shuttle HERE. Flutter takes the destination's builder
          // first, so supplying one at both ends means the outbound
          // flight is defined by this end and the return flight by the
          // card — two definitions for one movement, and only the card
          // knows about the corner and the label bar it has to land on.
          // Left null, the card's builder wins in both directions.
          : Hero(
              tag: widget.heroTag!,
              child: Material(child: viewer),
            ),
    );
  }
}
