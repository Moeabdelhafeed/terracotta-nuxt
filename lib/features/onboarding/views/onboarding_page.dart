import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/onboarding/onboarding_options.dart';
import '../../../core/onboarding/onboarding_page.dart' as model;
import '../../../core/tokens/extensions.dart';
import '../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/preferences_pickers/quick_preference_actions.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/dynamic_asset_image.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/vessel_indicator.dart';
import '../../shell/widgets/terracotta_app_bar.dart';

/// Drop-in onboarding flow. Lives in `features/` because adopters
/// reshape this screen project-by-project (hero layout, copy, CTA
/// strategy, animations). Only the *contract* lives in
/// `core/onboarding/` ([model.OnboardingPage], [OnboardingOptions],
/// [OnboardingRedirect]) — the screen itself is owned by the
/// adopter and is expected to evolve.
///
/// Pages are passed as a list; configure behaviour via
/// [OnboardingOptions].
class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    required this.pagesBuilder,
    required this.onFinish,
    this.options = const OnboardingOptions(),
    this.onSkip,
    super.key,
  });

  /// Builds the pages, and is called on every rebuild rather than once.
  ///
  /// A page's `title` and `body` are plain strings, resolved through a
  /// `Strings` namespace at the moment the list is built. Taking a
  /// ready-made `List` here would freeze that copy at whatever locale
  /// was loaded when the route was FIRST built: switching language
  /// afterwards rebuilds this widget, but the list it was handed still
  /// holds the old language's strings, so the intro would keep showing
  /// English while the rest of the app had already turned Arabic.
  final List<model.OnboardingPage> Function() pagesBuilder;

  final OnboardingOptions options;

  /// Called once the user reaches the end (or skips when
  /// [OnboardingOptions.skipFlagsAsSeen] is true). Caller pushes the
  /// next route from here.
  final void Function(BuildContext context) onFinish;

  /// Optional override for skip — defaults to [onFinish].
  final void Function(BuildContext context)? onSkip;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  late final PageController _controller;
  Timer? _autoAdvance;
  int _index = 0;
  bool _userTouched = false;

  /// Resolved fresh on every read so the copy always reflects the
  /// locale that is loaded RIGHT NOW — see [OnboardingFlowPage.
  /// pagesBuilder]. Cheap: three value objects and six map lookups.
  List<model.OnboardingPage> get _pages => widget.pagesBuilder();

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _scheduleAutoAdvance();
    _emit('step_seen', {'index': 0});
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance() {
    _autoAdvance?.cancel();
    final interval = widget.options.autoAdvance;
    if (interval == null || interval <= Duration.zero) return;
    _autoAdvance = Timer.periodic(interval, (_) {
      if (!mounted || _userTouched) return;
      if (_index >= _pages.length - 1) return;
      _animateTo(_index + 1);
    });
  }

  void _emit(String name, [Map<String, Object?> params = const {}]) {
    widget.options.onAnalyticsEvent?.call(name, params);
  }

  bool _shouldAnimate(BuildContext context) {
    if (!widget.options.respectReduceMotion) return true;
    return !MediaQuery.of(context).disableAnimations;
  }

  void _animateTo(int index) {
    if (_shouldAnimate(context)) {
      _controller.animateToPage(
        index,
        duration: widget.options.transitionDuration,
        curve: widget.options.transitionCurve,
      );
    } else {
      _controller.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (!mounted) return;
    setState(() => _index = index);
    widget.options.onPageChanged?.call(index);
    _emit('step_seen', {'index': index});
  }

  Future<void> _onPrimaryCta() async {
    _userTouched = true;
    final page = _pages[_index];
    _emit('cta_tapped', {'index': _index, 'permission': page.permission.name});
    if (page.permission != model.OnboardingPermission.none) {
      final handler = widget.options.onPermissionRequest;
      var granted = true;
      if (handler != null) granted = await handler(page.permission);
      _emit(
        granted ? 'permission_granted' : 'permission_denied',
        {'permission': page.permission.name},
      );
      if (!granted) {
        GlobalToast.w(widget.options.strings.permissionDeniedHint);
      }
    }
    if (!mounted) return;
    if (_index >= _pages.length - 1) {
      _finish();
    } else {
      _animateTo(_index + 1);
    }
  }

  void _onPrevious() {
    if (_index <= 0) return;
    _userTouched = true;
    _animateTo(_index - 1);
  }

  void _onSkip() {
    _userTouched = true;
    _emit('skipped', {'index': _index});
    if (widget.options.skipFlagsAsSeen) {
      context.read<PreferencesCubit>().markOnboardingSeen();
    }
    final cb = widget.onSkip ?? widget.onFinish;
    cb(context);
  }

  void _finish() {
    _emit('finished', {});
    context.read<PreferencesCubit>().markOnboardingSeen();
    widget.onFinish(context);
  }

  OnboardingBottomBarApi _api(BuildContext context) {
    return OnboardingBottomBarApi(
      currentIndex: _index,
      pageCount: _pages.length,
      next: _onPrimaryCta,
      previous: _onPrevious,
      skip: _onSkip,
      finish: _finish,
      goTo: _animateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    if (pages.isEmpty) {
      // Defensive — operator misconfig. Fall through to onFinish so
      // the user isn't trapped on an empty screen.
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
      return const SizedBox.shrink();
    }

    final api = _api(context);
    final opts = widget.options;
    if (opts.contentBuilder != null) {
      return opts.contentBuilder!(context, pages, _controller, api);
    }

    final theme = Theme.of(context);
    final pageBackground =
        pages[_index].background ?? theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        // Deliberately NOT wrapped in `GlobalContainer.prose`: the
        // hero artwork is drawn running past the screen edge, and a
        // prose container would both cap the width and add a second
        // gutter on top of the 20pt the design already specifies. The
        // horizontal safe-area inset that `prose` normally contributes
        // is covered by the `SafeArea` above.
        //
        // `PageView` clips to the page, which is the screen — the same
        // edge the design's frame clips its bleeding artwork at.
        child: Listener(
          onPointerDown: (_) => _userTouched = true,
          child: Column(
            children: [
              // THE LANGUAGE, BEFORE ANYTHING ELSE IS READ.
              //
              // This is the first screen of the app and every word on
              // it is in one language or the other — a reader who
              // opened it in the wrong one had to walk the whole
              // onboarding, sign in, and find the profile to change it.
              //
              // NOT an `AppBar`: the pages are drawn full-bleed and a
              // bar would take a strip off the top of artwork that is
              // meant to run to the edge. It floats at the reading END
              // instead, on the app's own plate, which is where every
              // other screen puts this control.
              //
              // The theme toggle is deliberately left out — the design
              // is light-only and the switch is withdrawn.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: context.spacing.md,
                    top: context.spacing.xs,
                  ),
                  child: QuickPreferenceActions(
                    showTheme: false,
                    // SMALL, like every other action in the app.
                    buttonSize: ButtonSize.small,
                    buttonBackgroundColor: TerracottaAppBar.plate(context),
                    buttonIconColor: TerracottaAppBar.glyph(context),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: _onPageChanged,
                  itemCount: pages.length,
                  // EACH PAGE CLIPS ITS OWN ARTWORK.
                  //
                  // A bleeding drawing is drawn wider than the page it
                  // is on, and `PageView` clips only at the VIEWPORT —
                  // so mid-swipe the outgoing page's art painted over
                  // the incoming one, and then vanished the moment the
                  // scroll settled and the page left the viewport. It
                  // read as the drawing being cut off on arrival.
                  //
                  // Clipped per page, what is on screen during the
                  // swipe is what is on screen after it: the same crop,
                  // moving.
                  itemBuilder: (ctx, i) => ClipRect(
                    child: _PageBody(page: pages[i], options: opts, index: i),
                  ),
                ),
              ),
              if (opts.bottomBarBuilder != null)
                opts.bottomBarBuilder!(context, api)
              else
                _BottomBar(options: opts, api: api, controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────
// Design metrics
// ─────────────────────────────────────────────────────────────

/// Measurements harvested from the Pencil frames `onboarding 1..3`,
/// which are drawn at 390 × 844. They are kept as raw numbers rather
/// than spacing tokens because they describe ONE screen's rhythm, and
/// rounding them to the nearest token visibly changes it.
///
/// Vertical values are expressed as GAPS, not absolute Y positions:
/// the artwork above them flexes, so anchoring to `y = 514` would put
/// the title in a different place on every device.
abstract final class _Metrics {
  /// Title / button gutter. Design: title width 351 in a 390 frame.
  static const double gutter = 20;

  /// The body copy is inset a little further than the title.
  /// Design: body width 336 in a 390 frame.
  static const double bodyGutter = 27;

  static const double titleSize = 30;
  static const double bodySize = 15;

  /// Design: title bottom 559 → body top 573.
  static const double titleToBody = 14;

  /// Design: body bottom ~619 → indicator top 647.
  static const double bodyToIndicator = 28;

  /// Design: indicator bottom 676 → button top 749.
  static const double indicatorToButton = 73;

  /// Design: button bottom 801 in an 844 frame, less the home
  /// indicator the `SafeArea` already accounts for.
  static const double buttonToBottom = 12;

  /// How much of the hero region BLEEDING artwork fills.
  ///
  /// `BoxFit.fitHeight` scales a drawing to the region's full height,
  /// and the two bleeding pages are the extremes of the set: page 1 is
  /// 2820 × 1401 (twice as wide as it is tall) and page 3 is
  /// 1393 × 1599 (taller than it is wide). Given the whole region, the
  /// first came out well over twice the screen's width and the second
  /// stood the full height of it — both of them the wrong size for a
  /// drawing that is meant to sit above a title.
  ///
  /// Scaling by HEIGHT is what keeps one number in charge of both:
  /// shorter art is narrower art, so this pulls the wide one back
  /// inside a sensible bleed and stands the tall one down at the same
  /// time. Raise it to make the drawings bigger; the contained page is
  /// not affected, since it is fitted to the region rather than filling
  /// it.
  static const double bleedHeightFactor = 0.72;
}

// ─────────────────────────────────────────────────────────────
// Page body (hero + title + body)
// ─────────────────────────────────────────────────────────────

class _PageBody extends StatelessWidget {
  const _PageBody({
    required this.page,
    required this.options,
    required this.index,
  });

  final model.OnboardingPage page;
  final OnboardingOptions options;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;

    // Only the FIRST page animates in. `ScreenEntrance` starts its clock
    // only for a widget built while its route is still arriving, and the
    // later pages are built lazily once onboarding has settled — so they
    // arrive by the PageView's own slide, which is what a swipe should
    // look like.
    return Column(
      children: [
        Expanded(
          child: ScreenEntrance.art(
            child: _HeroFor(page: page, options: options, index: index),
          ),
        ),
        ScreenEntrance(
          step: 1,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: _Metrics.gutter,
            ),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _Metrics.titleSize,
                fontWeight: FontWeight.w600,
                color: tx.primary,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: _Metrics.titleToBody),
        ScreenEntrance(
          step: 2,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: _Metrics.bodyGutter,
            ),
            child: Text(
              page.body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _Metrics.bodySize,
                height: 1.5,
                // The design paints the body in the SAME ink as the
                // title, not a muted secondary.
                color: tx.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The bleeding drawing's own box, so a test can measure what the
/// reader actually sees rather than the box around it.
@visibleForTesting
const Key bleedingArtKey = Key('onboarding-bleeding-art');

class _HeroFor extends StatelessWidget {
  const _HeroFor({
    required this.page,
    required this.options,
    required this.index,
  });

  final model.OnboardingPage page;
  final OnboardingOptions options;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (options.heroBuilder != null) {
      return options.heroBuilder!(context, page, index);
    }
    if (page.heroBuilder != null) return page.heroBuilder!(context);

    final asset = page.imageAsset ?? '';
    if (asset.isNotEmpty) {
      // THE STUDIO'S, when they have set one. A bleeding drawing keeps
      // its natural size and runs off the sides; a contained one is
      // scaled to fit the region. Line art, not a photo in a frame, so
      // no rounded corners either way.
      //
      // `forAsset` looks the bundled path up in [dynamicAssetSlots]:
      // registered, the CMS's file wins and the bundled one seeds the
      // empty key; unregistered, this is the plain asset it always
      // was.
      final image = DynamicAssetImage.forAsset(
        asset,
        fit: page.imageBleeds ? BoxFit.fitHeight : BoxFit.contain,
      );
      return Center(
        child: page.imageBleeds
            // OverflowBox lets the artwork exceed the parent's width
            // without the parent reporting an overflow, which is what
            // the design draws — the line sweeps past both edges.
            //
            // The height goes on the DRAWING, not on a box around it.
            //
            // `OverflowBox` reports the size it was handed rather than
            // the size of what it holds — that is the whole point of
            // it — so sizing the box changed nothing that could be
            // seen or measured. The fraction belongs to the artwork,
            // and `BoxFit.fitHeight` then scales the width to match.
            // See [_Metrics.bleedHeightFactor].
            ? LayoutBuilder(
                builder: (context, constraints) => OverflowBox(
                  maxWidth: double.infinity,
                  alignment: Alignment.center,
                  child: SizedBox(
                    key: bleedingArtKey,
                    height: constraints.maxHeight * _Metrics.bleedHeightFactor,
                    child: image,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: _Metrics.gutter,
                ),
                child: image,
              ),
      );
    }

    if ((page.lottieAsset ?? '').isNotEmpty) {
      return Center(child: Lottie.asset(page.lottieAsset!));
    }

    final btn = context.buttonsColors;
    final color = page.iconColor ?? btn.primary;
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.06),
            ],
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Icon(page.icon ?? Icons.star_rounded, size: 80, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom bar (indicator · primary CTA)
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.options,
    required this.api,
    required this.controller,
  });

  final OnboardingOptions options;
  final OnboardingBottomBarApi api;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final strings = options.strings;
    final label = api.isLast ? strings.getStarted : strings.next;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        _Metrics.gutter,
        _Metrics.bodyToIndicator,
        _Metrics.gutter,
        _Metrics.buttonToBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VesselIndicator(
            count: api.pageCount,
            activeIndex: api.currentIndex,
            onTap: (i) => controller.animateToPage(
              i,
              duration: options.transitionDuration,
              curve: options.transitionCurve,
            ),
          ),
          const SizedBox(height: _Metrics.indicatorToButton),
          // The label changes on the last page — «التالي» becomes
          // «ابدأ الآن» — and swapping the words between two frames
          // reads as a glitch on a control the customer is looking
          // straight at. Keyed on the LABEL, so the switcher only runs
          // when the words actually change and never on a rebuild.
          AnimatedSwitcher(
            duration: AppDurations.normal,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // The two bars are the same size, so they cross-fade in
            // place: the outgoing one leaves upward as the incoming one
            // rises to meet it.
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.35),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: GlobalFilledButton(
              key: ValueKey(label),
              text: label,
              onPressed: api.next,
              style: terracottaCtaStyle(),
            ),
          ),
        ],
      ),
    );
  }
}

/// One vessel in the indicator, which GROWS and DARKENS as it becomes
/// the current page rather than swapping colour between frames.
///
/// The dot is a vessel silhouette, not a dot — so the usual trick of
/// stretching the active one into a pill is out: it would distort the
/// drawing. Scale and colour are the two things that can move without
/// deforming it, and they read as one gesture because they run on the
/// same curve.
///
/// Driven by a `TweenAnimationBuilder` off a 0/1 target rather than by
/// two `Animated*` widgets, so the colour and the size cannot drift out
/// of step, and a tap that lands mid-flight retargets from wherever the
/// vessel currently is instead of restarting.
