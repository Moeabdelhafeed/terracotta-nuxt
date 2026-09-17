// Dart imports:
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';

// Flutter imports:
// Package imports:
// Project imports:
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../image/global_image.dart';
import '../pdf/global_pdf.dart';
import '../popup/popup.dart';
import '../progress/global_progress.dart';
import '../share/global_share_button.dart';
import '../toast/global_toast.dart';
import '../video/global_video.dart';
import 'media_picker_models.dart';

/// Full-screen preview for picker items. Each page is one item in a
/// swipeable [PageView]:
///
///   - Image → pinch-zoom via [InteractiveViewer], 90° rotate button
///     in the top bar, tap-in-the-whitespace dismiss,
///     drag-to-dismiss with live translate + backdrop fade.
///   - Video → inline `media_kit` player.
///   - File → icon + filename + Open button (`open_filex`).
///
/// Drag-to-dismiss directions default to vertical for multi-item
/// lightboxes (so horizontal swipes stay with the PageView) and to
/// all four edges for single-item lightboxes.
///
/// ## [heroTag]
///
/// The picture the reader TAPPED, flying up into the full-screen view
/// rather than being replaced by it. Give it the tag the thumbnail
/// carries and the two become one object.
///
/// It goes on [initialIndex] and nowhere else, deliberately. A
/// `PageView` builds its neighbours, so one tag across every page
/// would put two `Hero`s with the same tag on this route — which is an
/// assertion, not a warning. The pages either side were never on the
/// screen the reader came from and have nothing to fly from anyway.
Future<int?> showPickerLightbox({
  required BuildContext context,
  required List<PickerItem> items,
  required List<AttachmentKind> kinds,
  int initialIndex = 0,
  ValueChanged<int>? onDelete,
  String openLabel = 'Open',
  bool showTitle = true,
  String? heroTag,
}) {
  assert(items.length == kinds.length, 'items/kinds length mismatch');
  return Navigator.of(context, rootNavigator: true).push<int>(
    PageRouteBuilder<int>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, _) => _Lightbox(
        items: items,
        kinds: kinds,
        initialIndex: initialIndex,
        onDelete: onDelete,
        openLabel: openLabel,
        showTitle: showTitle,
        heroTag: heroTag,
      ),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// Fades the two ends of a photograph's flight across each other.
///
/// See `_PageBody` for why: the thumbnail is cropped to fill and the
/// viewer is letterboxed to fit, and a `BoxFit` cannot be interpolated.
Widget _crossFadeCrop(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) {
  final from = (fromContext.widget as Hero).child;
  final to = (toContext.widget as Hero).child;

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      // `fromHero` and `toHero` arrive in that order for BOTH
      // directions — only the clock differs. A push is driven off
      // `toRoute.animation` (0 → 1) and a pop off `fromRoute.animation`
      // (1 → 0), so inverting the value is enough; swapping the pair
      // as well would cancel it out and fade the wrong way home.
      final t = direction == HeroFlightDirection.push
          ? animation.value
          : 1 - animation.value;
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Opacity(opacity: 1 - t, child: from),
            Opacity(opacity: t, child: to),
          ],
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Lightbox body
// ---------------------------------------------------------------------------

class _Lightbox extends StatefulWidget {
  const _Lightbox({
    required this.items,
    required this.kinds,
    required this.initialIndex,
    required this.onDelete,
    required this.openLabel,
    required this.showTitle,
    this.heroTag,
  });

  /// The thumbnail's tag, on [initialIndex] only — see
  /// `showPickerLightbox`.
  final String? heroTag;

  /// Whether to name the thing on screen.
  ///
  /// A FILE picker's lightbox should — "report.pdf" is what the reader
  /// is looking for. A photograph's should not: the name is the CMS's
  /// upload slug, `serving-plates-1-1-6.jpg`, which tells the customer
  /// nothing and sits over the picture they opened it to see.
  final bool showTitle;

  final List<PickerItem> items;
  final List<AttachmentKind> kinds;
  final int initialIndex;
  final ValueChanged<int>? onDelete;
  final String openLabel;

  @override
  State<_Lightbox> createState() => _LightboxState();
}

class _LightboxState extends State<_Lightbox> {
  late final PageController _page;
  late int _current;
  // Per-image PhotoView controllers. Lazy so only visited image
  // pages allocate one; survives page transitions so rotation /
  // zoom state doesn't reset when the user swipes back.
  final Map<int, PhotoViewController> _imgControllers = {};

  /// Whether each image page is zoomed. A drag at rest dismisses the
  /// page; zoomed in, the same drag pans the picture.
  final Map<int, PhotoViewScaleStateController> _imgScaleStates = {};
  // 0.0 = no drag, 1.0 = fully dismissed. Controls backdrop fade.
  double _dragProgress = 0;

  /// Which menu action is still running, if any.
  ///
  /// The ROW says so — a spinner where its glyph was — rather than a
  /// scrim over the picture. The menu is what the reader is looking
  /// at, and it is the thing that has not answered yet.
  _LightboxAction? _busyAction;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex.clamp(0, widget.items.length - 1);
    _page = PageController(initialPage: _current);
    // EDGE TO EDGE, not immersive.
    //
    // It hid the status bar and the navigation bar for the life of the
    // viewer. On a photograph that is defensible; in this app it is
    // not what is wanted — the bars are part of the frame everywhere
    // else, and a viewer that removes them makes the phone itself feel
    // like it changed mode.
    //
    // It also had a failure the immersive version could not avoid: the
    // restore lives in `dispose`, so any route the framework tears
    // down without it — a crash in a page below, a hot restart —
    // leaves the phone with no bars and nothing in the app to bring
    // them back.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    // AFTER THE SUBTREE HAS GONE.
    //
    // `PhotoViewCore` removes its own listeners from these in ITS
    // dispose, and `IgnorableChangeNotifier.removeIgnorableListener`
    // reads `_listeners!` — null the moment the notifier is disposed.
    // Disposing them here, inline, is a null-check crash on the way
    // out of the viewer whenever the core is torn down after us
    // («Null check operator used on a null value»,
    // ignorable_change_notifier.dart:39).
    //
    // Handing them to the next frame costs nothing and is correct in
    // BOTH orders: the core has either already let go, or it does so
    // before this runs.
    final controllers = [..._imgControllers.values];
    final scaleStates = [..._imgScaleStates.values];
    _imgControllers.clear();
    _imgScaleStates.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final c in controllers) {
        c.dispose();
      }
      for (final c in scaleStates) {
        c.dispose();
      }
    });
    _page.dispose();
    // Restored anyway: the viewer no longer takes them, but something
    // else in the tree might have, and leaving is the moment the app
    // is sure of what it wants.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  PhotoViewController _controllerFor(int i) =>
      _imgControllers.putIfAbsent(i, PhotoViewController.new);

  PhotoViewScaleStateController _scaleStateFor(int i) =>
      _imgScaleStates.putIfAbsent(i, PhotoViewScaleStateController.new);

  /// Whether a drag on page [i] belongs to the LIGHTBOX.
  ///
  /// Only an image can be zoomed; a video and a document own their own
  /// gestures entirely, so the page never takes a drag from them.
  bool _canDragPage(int i) {
    if (widget.kinds[i] != AttachmentKind.image) return false;
    final state = _imgScaleStates[i];
    return state == null || state.scaleState == PhotoViewScaleState.initial;
  }

  void _rotateCurrent() {
    // PhotoView's rotation is radians; +π/2 = one quarter-turn
    // counter-clockwise on top of whatever the user has pinched.
    final c = _controllerFor(_current);
    c.rotation += math.pi / 2;
  }

  void _resetRotationCurrent() {
    _controllerFor(_current).rotation = 0;
  }

  /// «١ / ٢» — which of them is on screen.
  String get _counter => '${_current + 1} / ${widget.items.length}';

  /// What the bar calls the thing on screen.
  static String _titleFor(PickerItem item) => switch (item) {
    PickerItemFile(:final displayName) => displayName,
    PickerItemUrl(:final displayName) => displayName,
    PickerItemBytes(:final displayName) => displayName,
  };

  /// What the overflow menu offers for the item on screen.
  ///
  /// Only what can actually work: a local file can be shared and
  /// opened, a remote one can have its link copied, and delete
  /// appears only when the caller gave it something to do. A menu
  /// entry for something impossible is an entry that lies.
  List<GlobalPopupMenuItem<_LightboxAction>> _menuItems() {
    final item = widget.items[_current];
    final isFile = item is PickerItemFile;
    return [
      if (isFile)
        _menuItem(
          _LightboxAction.share,
          MediaStrings.share,
          Icons.ios_share_rounded,
        ),
      if (!isFile)
        _menuItem(
          _LightboxAction.copyLink,
          CommonStrings.copy,
          Icons.link_rounded,
        ),
      if (isFile)
        _menuItem(
          _LightboxAction.open,
          widget.openLabel,
          Icons.open_in_new_rounded,
        ),
      if (widget.onDelete != null)
        _menuItem(
          _LightboxAction.delete,
          CommonStrings.delete,
          Icons.delete_outline_rounded,
        ),
    ];
  }

  /// One row, which SPINS while its own action is running.
  ///
  /// The share sheet and the open handler are native round trips of a
  /// second or two on a cold start, and the menu simply sat there —
  /// so the second press queued a second sheet behind the first.
  ///
  /// The spinner takes the LEADING slot, where that row's glyph was:
  /// it is the row that has not answered, and the menu is what the
  /// reader is looking at. Every other row goes quiet meanwhile,
  /// because two native sheets at once is not a thing to allow.
  GlobalPopupMenuItem<_LightboxAction> _menuItem(
    _LightboxAction action,
    String label,
    IconData icon,
  ) {
    final busy = _busyAction == action;
    return GlobalPopupMenuItem(
      value: action,
      label: label,
      enabled: _busyAction == null,
      icon: busy ? null : icon,
      leading: busy
          ? SizedBox(
              width: _menuGlyphSize,
              height: _menuGlyphSize,
              child: GlobalProgress.loading(
                type: ProgressType.circular,
                style: const ProgressStyle(thickness: 2),
              ),
            )
          : null,
      semanticLabel: busy ? '$label — ${MediaStrings.preparing}' : null,
    );
  }

  /// Runs a menu action, and SHOWS that it is running.
  ///
  /// The share sheet and the open handler are both native round trips
  /// — a second or two on a cold start — and until one appeared the
  /// screen looked as though the menu item had not worked, so the
  /// second press queued a second sheet behind the first.
  Future<void> _runAction(_LightboxAction action) async {
    if (_busyAction != null) return;
    final item = widget.items[_current];
    // Delete is instant and pops the page; a scrim for it would be a
    // flash of grey on the way out.
    if (action == _LightboxAction.delete) {
      widget.onDelete?.call(_current);
      _pop();
      return;
    }
    setState(() => _busyAction = action);
    try {
      switch (action) {
        case _LightboxAction.share:
          if (item is PickerItemFile) {
            // `GlobalShare`, not the old `ShareUtils`: that facade
            // swallowed the reason a share failed, printed with
            // `debugPrint`, and passed no `sharePositionOrigin` — so
            // on an iPad the popover had nothing to anchor to.
            await GlobalShare.files([XFile(item.file.path)]);
          }
        case _LightboxAction.copyLink:
          if (item is PickerItemUrl) {
            await Clipboard.setData(ClipboardData(text: item.url));
            GlobalToast.success(MediaStrings.urlCopied);
          }
        case _LightboxAction.open:
          if (item is PickerItemFile) {
            final r = await OpenFilex.open(item.file.path);
            if (r.type != ResultType.done) {
              GlobalToast.error(MediaStrings.openFailed(r.message));
            }
          }
        case _LightboxAction.delete:
          break;
      }
    } finally {
      // The sheet closing is the app coming BACK, so this is where the
      // scrim goes — not on the way out, where it would leave the
      // spinner up under a sheet the reader is still using.
      if (mounted) setState(() => _busyAction = null);
    }
  }

  void _pop() {
    if (!mounted) return;
    Navigator.of(context).pop(_current);
  }

  @override
  Widget build(BuildContext context) {
    final single = widget.items.length == 1;
    final bgOpacity = (1 - _dragProgress).clamp(0.0, 1.0);
    final currentKind = widget.kinds[_current];
    final canRotate = currentKind == AttachmentKind.image;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Backdrop — fades as the user drags the tile off screen.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                color: Colors.black.withValues(alpha: bgOpacity * 0.88),
              ),
            ),
          ),
          // Pages — each wraps in drag-to-dismiss + tap-background
          // dismiss. Horizontal drag dismiss is only enabled in
          // single mode to avoid stealing from PageView's swipe.
          PageView.builder(
            controller: _page,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (ctx, i) => _DismissibleWrap(
              allowHorizontal: single,
              canDrag: () => _canDragPage(i),
              onDismiss: _pop,
              onProgress: (p) => setState(() => _dragProgress = p),
              child: _PageBody(
                item: widget.items[i],
                kind: widget.kinds[i],
                imageController: widget.kinds[i] == AttachmentKind.image
                    ? _controllerFor(i)
                    : null,
                imageScaleState: widget.kinds[i] == AttachmentKind.image
                    ? _scaleStateFor(i)
                    : null,
                openLabel: widget.openLabel,
                onBackgroundTap: _pop,
                // The tapped picture FLIES up into this one — on the
                // page the reader opened and nowhere else. See
                // `showPickerLightbox`.
                heroTag: i == widget.initialIndex ? widget.heroTag : null,
              ),
            ),
          ),
          // The APP's bar, not a hand-rolled one.
          //
          // The old one was a `Stack` of pills inside a `SafeArea`,
          // and under `immersiveSticky` a `SafeArea` reads `padding`,
          // which immersive mode ZEROES — so the close button and the
          // counter sat under the dynamic island. `viewPadding` is the
          // one that still reports the housing there, which is the
          // same call the video module's fullscreen page makes.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // ONE top inset, not two. The bar has a `SafeArea` of its
            // own; padding it by hand as well is the extra strip of
            // black above it. What it needs instead is the RIGHT
            // number: `immersiveSticky` zeroes `padding`, and
            // `viewPadding` is the one that still reports the housing
            // — so the bar is handed that as its padding and applies
            // it once.
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(
                  top: MediaQuery.viewPaddingOf(context).top,
                ),
              ),
              child: GlobalAppBar(
                variant: AppBarVariant.transparent,
                // The NAME of the thing being looked at, as a STRING —
                // the bar styles its own title and marquees it when it
                // overflows. Handing it a `Text` in a `GlobalMarquee`
                // meant a hand-written 16-point weight-600 title beside
                // every other bar in the app wearing the theme's.
                // With no name, the COUNTER takes the title slot.
                //
                // A subtitle only renders under a title, so leaving the
                // counter there took it off screen with the filename —
                // and which of two pictures you are looking at is the
                // one thing worth saying.
                title: widget.showTitle
                    ? _titleFor(widget.items[_current])
                    : (single ? null : _counter),
                subtitle: widget.showTitle && !single ? _counter : null,
                // LIGHT INK, always.
                //
                // The bar is transparent over a PHOTOGRAPH, and the
                // theme's title colour is the one chosen to read on the
                // page — near-black in the light theme, which is
                // exactly what it cannot be here. Whatever the studio
                // uploaded is behind these words.
                style: AppBarStyle(
                  titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  subtitleStyle: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                  foregroundColor: Colors.white,
                ),
                // The same button as the actions: it had no disc at
                // all, so a white cross on a white photograph was
                // invisible.
                leading: _BarIconButton(
                  icon: Icons.close_rounded,
                  tooltip: CommonStrings.close,
                  onPressed: _pop,
                ),
                actions: [
                  if (canRotate) ...[
                    // Realign comes FIRST, and it is the one that
                    // appears and disappears — so rotate keeps its
                    // place. The other way round, pressing rotate
                    // pushed rotate itself sideways and the second
                    // press landed on the button that had just taken
                    // its spot.
                    StreamBuilder<PhotoViewControllerValue>(
                      stream: _controllerFor(_current).outputStateStream,
                      builder: (ctx, snap) {
                        final rot =
                            snap.data?.rotation ??
                            _controllerFor(_current).rotation;
                        if (rot.abs() < 0.001) {
                          return const SizedBox.shrink();
                        }
                        return _BarIconButton(
                          icon: Icons.restart_alt_rounded,
                          tooltip: MediaStrings.realign,
                          onPressed: _resetRotationCurrent,
                        );
                      },
                    ),
                    _BarIconButton(
                      icon: Icons.rotate_90_degrees_ccw_rounded,
                      tooltip: MediaStrings.rotate,
                      onPressed: _rotateCurrent,
                    ),
                  ],
                  // Everything else is behind ONE control. Share,
                  // save, copy, open and delete are five glyphs, and
                  // five glyphs on a bar over a picture is a bar
                  // nobody reads — the video module's gear makes the
                  // same call.
                  _BarIconButton.menu(
                    icon: Icons.more_vert_rounded,
                    tooltip: MediaStrings.moreActions,
                    items: _menuItems(),
                    onSelected: _runAction,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular icon button with a translucent dark background so the
// icon stays readable on top of bright / full-bleed images.
// ---------------------------------------------------------------------------

/// The glyph a menu row carries, which the spinner has to match — a
/// smaller one leaves the label jumping sideways as it swaps in.
const double _menuGlyphSize = 18;

/// What the lightbox's overflow menu can do.
enum _LightboxAction { share, copyLink, open, delete }

/// A control on the lightbox bar.
///
/// `GlobalIconButton` on a scrim disc — the same button the video
/// controls and the scanner use, for the same reason: these float over
/// arbitrary pixels, so the disc is what makes them legible rather
/// than the palette.
///
/// It was a hand-rolled `Material` + `InkWell` + `Icon`, so close,
/// rotate and realign were three different sizes on two different
/// backgrounds — the close button had none at all.
class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// The glyph, and the disc it sits on. Every control on this bar is
  /// this size; a bar where the close is bigger than the rotate reads
  /// as two bars.
  static const glyphSize = 22.0;
  static const scrim = Color(0x73000000);

  /// The same button, opening a MENU rather than firing a callback.
  ///
  /// The popup owns the gesture, so the button carries no `onPressed`
  /// — and `enabled` is set anyway, or `GlobalIconButton` would draw
  /// itself dulled as though nothing will happen. Same call the video
  /// module's gear makes.
  static Widget menu<T>({
    required IconData icon,
    required String tooltip,
    required List<GlobalPopupMenuItem<T>> items,
    required ValueChanged<T> onSelected,
  }) => GlobalPopup.menu<T>(
    items: items,
    onSelected: onSelected,
    semanticLabel: tooltip,
    anchor: GlobalIconButton(
      iconData: icon,
      iconSize: glyphSize,
      enabled: true,
      tooltip: tooltip,
      semanticLabel: tooltip,
      style: ButtonStateStyle(
        foregroundColor: Colors.white,
        backgroundColor: scrim,
        borderRadius: BorderRadius.circular(glyphSize * 2),
        width: glyphSize * 1.8,
        height: glyphSize * 1.8,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => GlobalIconButton(
    iconData: icon,
    iconSize: glyphSize,
    onPressed: onPressed,
    tooltip: tooltip,
    semanticLabel: tooltip,
    style: ButtonStateStyle(
      foregroundColor: Colors.white,
      backgroundColor: scrim,
      borderRadius: BorderRadius.circular(glyphSize * 2),
      // Sized to the GLYPH: left unset the painted box falls back to
      // the 48dp touch target and the disc stands well off the icon.
      // `MinTouchTarget` keeps the hit area at 48 either way.
      width: glyphSize * 1.8,
      height: glyphSize * 1.8,
    ),
  );
}

// ---------------------------------------------------------------------------
// Drag-to-dismiss — live translate + progress callback for the
// parent to fade the backdrop. Pops past a distance or velocity
// threshold; otherwise springs back on release.
// ---------------------------------------------------------------------------

class _DismissibleWrap extends StatefulWidget {
  const _DismissibleWrap({
    required this.child,
    required this.onDismiss,
    required this.onProgress,
    required this.allowHorizontal,
    required this.canDrag,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final ValueChanged<double> onProgress;

  /// Whether the horizontal axis is ours. With several items the
  /// `PageView` owns it, so only the vertical component moves the
  /// picture there.
  final bool allowHorizontal;

  /// Whether a drag belongs to THIS, right now.
  ///
  /// False while the picture is zoomed: a drag there is a pan of the
  /// picture, and dismissing under the reader's finger while they are
  /// looking at a corner of it is the wrong answer.
  final bool Function() canDrag;

  @override
  State<_DismissibleWrap> createState() => _DismissibleWrapState();
}

class _DismissibleWrapState extends State<_DismissibleWrap> {
  Offset _offset = Offset.zero;

  /// Where the finger went down, and when.
  Offset? _start;
  Duration? _startedAt;
  bool _dragging = false;

  static const _slop = 12.0;
  static const _dismissDistance = 140.0;
  static const _dismissVelocity = 900.0;

  void _update(Offset delta) {
    var next = delta;
    if (!widget.allowHorizontal) next = Offset(0, next.dy);
    setState(() => _offset = next);
    widget.onProgress((next.distance / 400).clamp(0.0, 1.0));
  }

  void _settle(Offset velocity) {
    final v = velocity.distance;
    final d = _offset.distance;
    if (d > _dismissDistance || v > _dismissVelocity) {
      widget.onDismiss();
    } else {
      setState(() => _offset = Offset.zero);
      widget.onProgress(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A `Listener`, not a `GestureDetector`.
    //
    // The picture underneath is a `PhotoView`, and its scale
    // recogniser is in the arena for every drag that starts on it —
    // so an ancestor pan recogniser never wins and the page could not
    // be dragged at all. A `Listener` sees pointers WITHOUT joining
    // the arena, which is the same reason the video module drives its
    // tap-to-show that way.
    //
    // What keeps the two from fighting is `canDrag`: at rest the drag
    // dismisses, and zoomed in it belongs to the picture.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _start = e.position;
        _startedAt = e.timeStamp;
        _dragging = false;
      },
      onPointerMove: (e) {
        final start = _start;
        if (start == null || !widget.canDrag()) return;
        final total = e.position - start;
        // Past the slop it is a drag; before it, it may still be a tap
        // or the start of a pinch.
        if (!_dragging) {
          if (total.distance < _slop) return;
          // A DIRECTION LOCK, decided once and kept for the gesture.
          //
          // With more than one item the horizontal axis belongs to the
          // `PageView`, and `allowHorizontal` said so — but only by
          // zeroing the `dx` of a drag this had already claimed. So a
          // swipe meant for the next picture still lifted the current
          // one by whatever vertical wobble the thumb put into it, and
          // the page moved under a finger that was trying to turn it.
          //
          // Ceded by dropping the pointer rather than by ignoring the
          // axis: `_start` is nulled, so every later move on this
          // pointer returns above and the picture stays put for as
          // long as the finger is down.
          if (!widget.allowHorizontal && total.dx.abs() > total.dy.abs()) {
            _start = null;
            _startedAt = null;
            return;
          }
          _dragging = true;
        }
        _update(total);
      },
      onPointerUp: (e) {
        final start = _start;
        final startedAt = _startedAt;
        _start = null;
        _startedAt = null;
        if (!_dragging || start == null || startedAt == null) return;
        _dragging = false;
        // A `Listener` reports no velocity, so it is measured: the
        // distance travelled over the time it took.
        final seconds =
            (e.timeStamp - startedAt).inMicroseconds /
            Duration.microsecondsPerSecond;
        final travelled = e.position - start;
        _settle(seconds <= 0 ? Offset.zero : travelled / seconds);
      },
      onPointerCancel: (_) {
        _start = null;
        _startedAt = null;
        if (!_dragging) return;
        _dragging = false;
        _settle(Offset.zero);
      },
      child: Transform.translate(offset: _offset, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// One page body. Taps on surrounding whitespace dismiss; taps on
// the inner content are absorbed so the user can't close by
// tapping the image itself.
// ---------------------------------------------------------------------------

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.item,
    required this.kind,
    required this.imageController,
    required this.imageScaleState,
    required this.openLabel,
    required this.onBackgroundTap,
    this.heroTag,
  });

  final PickerItem item;
  final AttachmentKind kind;

  /// Non-null only for `AttachmentKind.image`. PhotoView needs its
  /// own controller per page so pinch-rotate state persists and
  /// the top-bar rotate button can nudge it.
  final PhotoViewController? imageController;

  /// Non-null only for an image — see `_canDragPage`.
  final PhotoViewScaleStateController? imageScaleState;

  final String openLabel;
  final VoidCallback onBackgroundTap;

  /// The thumbnail's tag when this page is the one that was opened.
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    // Image path already handles taps via PhotoView.onTapUp. The
    // other kinds use the outer-tap-dismisses / inner-tap-absorbs
    // pattern so only the surrounding whitespace closes.
    if (kind == AttachmentKind.image) {
      final page = _ImagePage(
        item: item,
        controller: imageController!,
        scaleState: imageScaleState!,
        onBackgroundTap: onBackgroundTap,
      );
      return heroTag == null
          ? page
          : Hero(
              tag: heroTag!,
              // CROSS-FADED, because the two ends CROP DIFFERENTLY.
              //
              // A thumbnail fills its box — `cover`, so the picture is
              // zoomed in and its edges are cut off. This viewer shows
              // the whole file — `contain`, letterboxed. The default
              // shuttle paints the destination's child for the entire
              // flight, so the crop changed on frame one: the picture
              // un-zoomed where it stood and only then travelled, which
              // is the jump.
              //
              // `Hero` can only interpolate the RECT; a `BoxFit` is not
              // a number and cannot be lerped. So the two croppings are
              // faded across each other instead, inside the one box
              // that is travelling — at the start you see what was
              // under your finger, at the end what you are landing on,
              // and the difference between them is never a cut.
              flightShuttleBuilder: _crossFadeCrop,
              child: page,
            );
    }
    // A player and a document are CENTRED and bounded, like the
    // picture is — the backdrop shows around them rather than being
    // covered by a full-bleed black page. Filling the screen made the
    // video look like a different screen from the image, and it left
    // no margin for the `PageView` to take a swipe in.
    // The backdrop closes whatever is on it. A player and a document
    // absorb their own taps — the inner detector is what stops a tap
    // on the controls closing the page — but the empty space around
    // them belongs to the lightbox, exactly as it does for a picture.
    if (kind == AttachmentKind.video) {
      return _BackdropDismiss(
        onTap: onBackgroundTap,
        child: _VideoPage(item: item),
      );
    }
    if (kind == AttachmentKind.file && _FilePage.isPdfItem(item)) {
      return _BackdropDismiss(
        onTap: onBackgroundTap,
        // A document is placed by its OWN top inset — it has to start
        // under the bar, and centring it would put half the bar's
        // height at each end.
        alignment: Alignment.topCenter,
        child: _FilePage(item: item, openLabel: openLabel),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onBackgroundTap,
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: _FilePage(item: item, openLabel: openLabel),
        ),
      ),
    );
  }
}

/// Centres [child] and closes the page when the space AROUND it is
/// tapped.
///
/// The child absorbs its own taps, so a press on a play button or on a
/// page of a document does not dismiss.
class _BackdropDismiss extends StatelessWidget {
  const _BackdropDismiss({
    required this.onTap,
    required this.child,
    this.alignment = Alignment.center,
  });

  final VoidCallback onTap;
  final Widget child;

  /// Where the content sits. A player is centred; a document starts
  /// under the bar and pays its own inset.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: child,
      ),
    ),
  );
}

// ─── Image ─────────────────────────────────────────────────────────

class _ImagePage extends StatelessWidget {
  const _ImagePage({
    required this.item,
    required this.controller,
    required this.scaleState,
    required this.onBackgroundTap,
  });
  final PickerItem item;
  final PhotoViewController controller;
  final PhotoViewScaleStateController scaleState;
  final VoidCallback onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    // The zoomable page comes from the image module. This lightbox
    // cannot simply BE that viewer — it also shows videos and files,
    // and deletes — but the way an IMAGE behaves inside it should not
    // be a second implementation, which is how the two drifted apart on
    // loading and error states.
    //
    // The shared controller stays: the top-bar rotate button adds a 90°
    // turn on top of whatever the user has pinched to.
    return GlobalZoomableImage(
      source: switch (item) {
        PickerItemFile(:final file) => GlobalImageSource.file(file),
        PickerItemUrl(:final url) => GlobalImageSource.network(url),
        PickerItemBytes(:final bytes) => GlobalImageSource.memory(bytes),
      },
      controller: controller,
      scaleStateController: scaleState,
      onTap: onBackgroundTap,
    );
  }
}

// ─── Video ─────────────────────────────────────────────────────────

/// The app's OWN player, filling the page.
///
/// It was a raw `media_kit` `Player` + `Video` — a second video
/// implementation with no controls, no seek bar, no keyboard, none of
/// the chrome the video module spent its own pass on, and nothing that
/// a `VideoStyle` or `GlobalVideoTheme` could reach. A reader who tapped
/// a picked clip got a bare texture.
///
/// `GlobalVideo` in a fullscreen SHAPE rather than its fullscreen
/// route: this lightbox already IS the full screen, and pushing the
/// module's own page on top of it would be a second bar over the first.
class _VideoPage extends StatelessWidget {
  const _VideoPage({required this.item});

  final PickerItem item;

  @override
  Widget build(BuildContext context) {
    // The player keeps its own SHAPE. It is as wide as the page and as
    // tall as that shape needs — never taller than the screen — and
    // the backdrop shows above and below it, which is what the image
    // page does and what makes the two read as one viewer.
    //
    // The swipe gestures are OFF: with several items the `PageView`
    // owns the horizontal axis, and a player that seeks on a swipe
    // takes every page change with it. The seek buttons and the bar
    // are still there, which is the point of using the real player.
    const style = VideoStyle(
      showSeekButtons: true,
      // The reader is already IN a full screen, but this is what takes
      // a portrait clip to landscape — and it is the control they look
      // for first.
      showFullscreenButton: true,
      enableSwipeGestures: false,
      // SQUARE. A rounded frame inside a black page draws a card the
      // reader did not ask for; the picture beside it has none.
      borderRadius: BorderRadius.zero,
      // The transport in the MIDDLE of the bar with the other controls
      // either side — the music-player shape, where the thing pressed
      // most is found without looking.
      transportPlacement: VideoTransportPlacement.barCentered,
      // Elapsed at the start of the timeline, total at its end: each
      // number at the end it describes.
      clockPlacement: VideoClockPlacement.split,
    );
    final maxHeight = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: switch (item) {
        // Bytes have no path, and `media_kit` opens paths and URLs.
        // A clip that only exists in memory has to be written down
        // before it can be played, and that is the app's call to make
        // — the module says what it cannot do rather than guessing.
        PickerItemBytes() => const _UnplayableBytes(),
        PickerItemFile(:final file) => GlobalVideo.file(
          file.path,
          style: style,
          autoPlay: true,
        ),
        PickerItemUrl(:final url) => GlobalVideo.network(
          url,
          style: style,
          autoPlay: true,
        ),
      },
    );
  }
}

// ─── File ──────────────────────────────────────────────────────────

class _FilePage extends StatelessWidget {
  const _FilePage({required this.item, required this.openLabel});
  final PickerItem item;
  final String openLabel;

  /// Clear air between a document and the bar above it. There is none
  /// below: the viewer's own control bar carries the bottom inset.
  static const _pdfGap = 12.0;

  /// Whether this is something the app can READ rather than hand to
  /// another one.
  ///
  /// Static as well, because the page ABOVE this has to know: a
  /// document fills the screen where a generic file is a centred
  /// plate.
  static bool isPdfItem(PickerItem item) {
    final name = switch (item) {
      PickerItemFile(:final displayName) => displayName,
      PickerItemUrl(:final displayName) => displayName,
      PickerItemBytes(:final displayName) => displayName,
    };
    return name.toLowerCase().endsWith('.pdf');
  }

  bool get _isPdf => isPdfItem(item);

  @override
  Widget build(BuildContext context) {
    // A PDF opens HERE. Handing it to `open_filex` sends the reader
    // into another app for a document this one already has a viewer
    // for — with bookmarks, search, night mode and a resume position.
    if (_isPdf) {
      // Bounded, and bounded by what is ACTUALLY free — not by a
      // fraction someone guessed.
      //
      // A fraction cannot know where the bar ends: 82% of an 844-point
      // screen is 76 points of margin at the top, and the bar with its
      // housing inset is nearer 115, so the first page slid under the
      // title. What is left below the bar and above the home indicator
      // is a number this can compute, so it does.
      final media = MediaQuery.of(context);
      // The bar's real height: its toolbar plus the housing inset it
      // sits under. `viewPadding`, because `immersiveSticky` zeroes
      // `padding` — the same reason the bar itself is handed that.
      final barHeight =
          media.viewPadding.top + const AppBarStyle().preferredToolbarHeight;
      // It runs to the BOTTOM EDGE of the screen, and pays nothing for
      // the home indicator: the viewer's own control bar is wrapped in
      // a `SafeArea`, so it already does. Paying it here as well left
      // exactly what showed up on a device — the bar's own white
      // inset, and then a strip of black under it.
      final free = media.size.height - barHeight - _pdfGap;
      // TOP-aligned, not centred. Centring a box that is short by the
      // bar's height puts half that space at each end — which is half
      // a bar of overlap at the top, and dead black at the bottom.
      return Padding(
        padding: EdgeInsets.only(top: barHeight + _pdfGap),
        child: SizedBox(
          height: free > 0 ? free : null,
          child: GlobalPdfViewer(
            source: switch (item) {
              PickerItemFile(:final file) => PdfSourceSpec.file(file.path),
              PickerItemUrl(:final url) => PdfSourceSpec.url(url),
              // The viewer takes bytes directly, so this one needs no
              // file written for it.
              PickerItemBytes(:final bytes, :final filename) =>
                PdfSourceSpec.bytes(bytes, label: filename),
            },
            // The lightbox owns the frame and its own dismissal, so
            // the viewer must not fly out of a hero it was never
            // given, and must not take a drag that belongs to the
            // page.
            enableHero: false,
            style: const PdfStyle(
              panEnabled: false,
              // SQUARE, like the player beside it — a rounded document
              // inside a black page is a card nobody asked for.
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      );
    }
    return _buildGenericFile(context);
  }

  Widget _buildGenericFile(BuildContext context) {
    final name = switch (item) {
      PickerItemFile(:final displayName) => displayName,
      PickerItemUrl(:final displayName) => displayName,
      PickerItemBytes(:final displayName) => displayName,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.insert_drive_file_rounded,
          size: 96,
          color: Colors.white70,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        GlobalFilledButton(
          text: openLabel,
          icon: Icons.open_in_new_rounded,
          shrinkWidth: true,
          onPressed: _open,
        ),
      ],
    );
  }

  // GlobalToast is overlay-hosted, so the copy / open-failure
  // feedback survives the lightbox route being popped mid-await —
  // no BuildContext (or mounted guard) needed here.
  Future<void> _open() async {
    switch (item) {
      // Nothing to open: `open_filex` hands a PATH to another app, and
      // bytes have none. The share sheet is the way out for those, and
      // it is in the menu.
      case PickerItemBytes():
        break;
      case PickerItemFile(:final file):
        final r = await OpenFilex.open(file.path);
        if (r.type != ResultType.done) {
          GlobalToast.error(MediaStrings.openFailed(r.message));
        }
      case PickerItemUrl(:final url):
        await Clipboard.setData(ClipboardData(text: url));
        GlobalToast.success(MediaStrings.urlCopied);
    }
  }
}

/// A clip that only exists in memory.
///
/// `media_kit` opens paths and URLs; bytes have neither. Writing one
/// down to play it is a decision about where the app keeps things, so
/// the module says what it cannot do instead of guessing.
class _UnplayableBytes extends StatelessWidget {
  const _UnplayableBytes();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.videocam_off_rounded,
          color: Colors.white70,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          MediaStrings.cannotPreviewBytes,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
