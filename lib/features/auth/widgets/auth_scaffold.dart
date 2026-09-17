import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/assets/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/app_bar/global_app_bar.dart';
import '../../../shared/module/buttons/button_models.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/preferences_pickers/quick_preference_actions.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/dynamic_asset_image.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../shell/widgets/terracotta_app_bar.dart';

/// Both auth links — "forgot password" and the footer's "create an
/// account" — are drawn at 13 in the `auth` frames, a step below body
/// copy so they read as secondary to the form they sit beside.
const double kAuthLinkFontSize = 13;

/// The chrome every auth screen shares: a back arrow, a hand-drawn arc
/// behind a centred title, and a body that scrolls.
///
/// ## Why this is written start/end and never left/right
///
/// The Pencil design is drawn ARABIC-FIRST, so in the file the back
/// arrow sits on the RIGHT, labels hug the RIGHT, and the CTA's arrow
/// points LEFT. None of that is hardcoded here. Everything uses the
/// logical directions — `EdgeInsetsDirectional`, `TextAlign.start`,
/// `Alignment*Directional`, `Row` in logical order — so the same widget
/// renders the design's RTL layout in Arabic and the mirrored LTR one
/// in English, with no second code path and nothing to keep in sync.
///
/// The one thing that must NOT mirror is the artwork: the arc is a
/// drawing, not a layout, so it is flipped explicitly with the reading
/// direction rather than left alone.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.children,
    this.subtitle,
    this.appBarTitle,
    this.illustration = AuthIllustration.loginRegister,
    this.showMark = true,
    this.footer,
    this.bottomAction,
    this.background,
    this.showBack = true,
    super.key,
  });

  /// Centred heading, e.g. "اهلا بعودتك" / "Welcome back".
  final String title;

  /// Optional line under it.
  final String? subtitle;

  /// The form.
  final List<Widget> children;

  /// Pinned under the form — the "create an account" line.
  final Widget? footer;

  /// Names the FLOW in the app bar — "انشاء حساب" while registering,
  /// "تغيير كلمة السر" while resetting. Separate from [title], which
  /// names the STEP; the OTP screen is reached from both flows and says
  /// the same thing in the body either way.
  final String? appBarTitle;

  /// The line drawing behind the heading. Each step has its own.
  final AuthIllustration illustration;

  /// The vessel mark under the subtitle. Off for the steps whose
  /// drawing already carries a subject of its own.
  final bool showMark;

  /// Sits at the BOTTOM of the page rather than after the form — for a
  /// screen whose only control belongs at the end of the screen.
  final Widget? bottomAction;

  /// Painted behind everything, edge to edge.
  final Widget? background;

  final bool showBack;

  /// Numbers the rows a screen handed us, so no call site has to count
  /// its own column — and so inserting a row cannot silently leave a
  /// hole in the stagger, or put an entrance ABOVE a hero.
  ///
  /// `ScreenEntrance.staged` puts the entrance where that particular child
  /// needs it: inside a hero, around anything else, and nowhere at all
  /// around a spacer.

  /// The step the last row of [children] took, so the footer can follow
  /// it rather than landing in the middle of the column.
  static int _lastStep(List<Widget> children) =>
      ScreenEntrance.formStep +
      children.where((c) => c is! SizedBox).length -
      1;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // The stroke starts ABOVE the back arrow in the design — its box
      // opens at y63 where the arrow sits at y87 — so the body has to
      // reach up behind the (transparent) bar. Without this the artwork
      // begins below the toolbar and the whole header is pushed down by
      // a bar's height of empty white.
      extendBodyBehindAppBar: true,
      appBar: GlobalAppBar(
        showBack: showBack,
        title: appBarTitle,
        // THE SAME CHEVRON THE REST OF THE APP FLIES.
        //
        // It is the same control in the same place, and the auth flow
        // was the one part of the app where it appeared and vanished
        // instead. See [HeroTag.back] — which also decides when it
        // ARRIVES: a push from a screen with no back button falls back
        // to the entrance, and one from a screen that has it flies.
        wrapBack: (back) => SharedHero(
          tag: HeroTag.back,
          entranceDriftFrom: const Offset(-3.5, 0),
          exitsWithRoute: true,
          child: back,
        ),
        variant: AppBarVariant.transparent,
        // `transparent` means the bar has NO SURFACE — it does not mean
        // there is dark media behind it. The module cannot know which,
        // so it assumes the media case and paints white; here the page
        // behind is the white scaffold, which made the back arrow and
        // the status bar's own clock invisible.
        style: AppBarStyle(
          // The BAR's glyph colour, which is the back arrow's — the
          // title sets its own below. Same brown as every other screen.
          foregroundColor: TerracottaAppBar.glyph(context),
          // The bar has no surface and the illustration runs behind it,
          // so a bare glyph competes with the lines it sits on.
          //
          // `TerracottaAppBar`'s pill, not the page's own colour: these
          // are the same two controls the tabs carry, and the auth flow
          // painting them white made them a different pair of buttons
          // in the same positions.
          buttonBackgroundColor: TerracottaAppBar.plate(context),
          // Against the reading start and bold — the flow's name is a
          // heading, not a centred caption. `centerTitle: false` is what
          // makes `start` mean the right in Arabic.
          centerTitle: false,
          titleStyle: context.textTheme.titleMedium?.copyWith(
            color: context.textColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        // Dark glyphs in the system status bar, for the same reason.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        // Language only. The design is light-only, so a theme toggle
        // here would offer a brightness nobody drew.
        actions: [
          // FLOWN under the same tag the rest of the app's trailing
          // controls carry.
          //
          // Those are three boxes — the language pill, the bell and the
          // cart — and this is one, so the flight is not a box holding
          // still: it is the row COLLAPSING to the only control that
          // means anything in a flow with no account yet. Cross-faded
          // for that reason; the default shuttle would paint one end's
          // three buttons over the other end's one from the first
          // frame.
          SharedHero(
            tag: HeroTag.barActions,
            flightShuttleBuilder: crossFadeShuttle,
            // Padded HERE rather than through the module:
            // `actionsPadding` only sets the END inset, so it spaces
            // the row off the edge but not the buttons off each other.
            // The tab bar does the same, and without it the auth toggle
            // sat 4dp from the edge against the tabs' 8.
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: TerracottaAppBar.actionGap,
              ),
              child: QuickPreferenceActions(
                showTheme: false,
                // SMALL, like every other action in the app. Left to
                // the ambient default this painted 48 next to a 40 back
                // button — the same mismatch the bar had at the other
                // end.
                buttonSize: ButtonSize.small,
                buttonBackgroundColor: TerracottaAppBar.plate(context),
                buttonIconColor: TerracottaAppBar.glyph(context),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (background != null) Positioned.fill(child: background!),
          Column(
            children: [
              Expanded(
                child: GlobalScrollable(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // OUTSIDE the form container, and deliberately so: the
                      // stroke is measured against the SCREEN, and a form
                      // container both pads it and caps its width, which scaled
                      // the drawing down and shifted its centre off the screen's.
                      _AuthHeader(
                        title: title,
                        subtitle: subtitle,
                        illustration: illustration,
                        showMark: showMark,
                      ),
                      GlobalContainer.form(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          spacing.md,
                          0,
                          spacing.md,
                          spacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The ROUTE is the cue here, and the form
                            // falls in BEHIND the header: an auth
                            // screen's artwork, title, subtitle and
                            // mark have already taken the first four
                            // slots, and every one of these rows is
                            // present the moment the page is built.
                            //
                            // A bound screen is the opposite on both
                            // counts — nothing ahead of its list, and
                            // nothing in it until the server answers —
                            // which is why those are the defaults and
                            // this is the call that spells them out.
                            ...ScreenEntrance.stage(
                              children,
                              from: ScreenEntrance.formStep,
                              arrival: EntranceArrival.route,
                            ),
                            // Back INSIDE the scroll, right after the
                            // form. Pinned to the bottom of the screen
                            // it claimed a band of the page on every
                            // auth screen for one line of text.
                            if (footer != null) ...[
                              SizedBox(height: spacing.sm),
                              Center(
                                child: SharedHero(
                                  tag: AuthHeroTag.footer,
                                  // Last in, after everything above it.
                                  entranceStep: _lastStep(children) + 1,
                                  flightShuttleBuilder: crossFadeShuttle,
                                  child: footer!,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // OUTSIDE the scrollable: a bottom action belongs to the
              // SCREEN, so it stays put however long the body is.
              if (bottomAction != null)
                SafeArea(
                  top: false,
                  child: GlobalContainer.form(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      spacing.md,
                      spacing.md,
                      spacing.md,
                      spacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (bottomAction != null) bottomAction!,
                        if (bottomAction != null && footer != null)
                          SizedBox(height: spacing.md),
                        if (footer != null) footer!,
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The line drawing behind an auth heading.
///
/// Each step has its own, and they are ASSETS rather than paths built
/// in code: the designer drew four of them, and transcribing each one's
/// béziers by hand is four chances to lose the crossing that makes them
/// read as drawn rather than plotted.
enum AuthIllustration {
  /// The open sweep behind "welcome back" / "welcome to Terracotta".
  ///
  /// The ONLY one that wraps the heading — the design draws the line
  /// around the words. Mirrored in English: a pure directional sweep
  /// that opens toward the reading direction in Arabic closes against
  /// it otherwise.
  loginRegister(
    'assets/images/login-register-illustration.png',
    cmsKey: 'login_register',
    wrapsHeading: true,
    mirrorForLtr: true,
  ),

  /// Clipboard with a tick — entering the code. `auth 6`: 584 × 115.8
  /// at (-96, 147), so it leaves the frame on both sides.
  ///
  /// NOT mirrored: the drawing contains a CHECK MARK, and a mirrored
  /// tick is a tick drawn wrong.
  otp(
    'assets/images/enter-otp-illustration.png',
    cmsKey: 'otp',
    width: 584 / 390,
    height: 115.8 / 390,
    top: 147 / 390,
    titleGap: 59 / 390,
  ),

  /// A handset — asking for the code. `auth 5`: 327.94 × 133.8 at
  /// (98, 137), running off the end edge.
  passwordRequest(
    'assets/images/chnage-password-request-illustration.png',
    cmsKey: 'password_request',
    width: 327.94 / 390,
    height: 133.8 / 390,
    top: 137 / 390,
    titleGap: 58 / 390,
  ),

  /// Padlock and key — setting the new password. `auth 7`: 239.22 × 139
  /// at (72, 135), fully inside the frame.
  passwordChange(
    'assets/images/chnage-password-illustration.png',
    cmsKey: 'password_change',
    width: 239.22 / 390,
    height: 139 / 390,
    top: 135 / 390,
    titleGap: 48 / 390,
  );

  const AuthIllustration(
    this.asset, {
    required this.cmsKey,
    this.wrapsHeading = false,
    this.mirrorForLtr = false,
    this.width = 1,
    this.height = 0,
    this.top = 0,
    this.titleGap = 0,
  });

  final String asset;

  /// This drawing's slot in the CMS — `auth/<cmsKey>`.
  ///
  /// The studio replaces the artwork without a release; until they do,
  /// [asset] is shown AND uploaded into the empty key so there is
  /// something for them to replace. See [DynamicAssetImage].
  final String cmsKey;

  /// The CMS `sub_group` all four sit under.
  static const cmsSection = 'auth';

  /// Whether the drawing sits BEHIND the heading or above it.
  ///
  /// Only the login sweep wraps the words. The other three are objects
  /// — a clipboard, a handset, a padlock — drawn in a band of their own
  /// above the title, and rendering one as a backdrop puts a padlock
  /// through the middle of the copy.
  final bool wrapsHeading;

  /// Whether to flip this drawing horizontally in a LEFT-TO-RIGHT
  /// build.
  ///
  /// The design is drawn ARABIC-FIRST, so the asset on disk IS the
  /// right-to-left composition. Layout mirrors itself from logical
  /// directions; a drawing does not, and has to be flipped deliberately
  /// or left alone deliberately — per drawing, not per screen.
  final bool mirrorForLtr;

  // Band geometry, as fractions of the frame width, off the design's
  // 390pt frames. Unused when [wrapsHeading].

  /// The drawing's own width. Over 1 means it leaves the screen —
  /// CENTRED on the frame either way.
  ///
  /// The design's `x` is a physical left coordinate in an Arabic frame,
  /// so it cannot be read as a logical `start`: doing that mirrors the
  /// offset and pushes the drawing off the wrong side. All three are
  /// centred in the frame, which is what the numbers describe once the
  /// mirroring is undone.
  final double width;

  final double height;

  /// Top of the drawing, measured from the top of the SCREEN — the
  /// design's own absolute y, status bar included.
  final double top;

  /// From the bottom of the drawing to the title.
  final double titleGap;
}

/// The auth header: the step's line drawing, the heading, and (where
/// the drawing has no subject of its own) the vessel mark.
///
/// TWO layouts, picked by the drawing — see
/// [AuthIllustration.wrapsHeading]. The login sweep is a BACKGROUND the
/// copy sits inside; the clipboard, handset and padlock are objects
/// drawn in a band of their own above it. Treating all four the same
/// way put a padlock through the middle of the words.
class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.title,
    required this.illustration,
    required this.showMark,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final AuthIllustration illustration;
  final bool showMark;

  // ─── The wrapping sweep (login / register only) ───────────────
  static const double _artWidth = 620 / 390;
  static const double _artLeft = -115 / 390;
  static const double _artBleed = 46 / 390;

  /// The sweep rides UP with the heading — see [_titleTop]. Without
  /// this the drawing stayed put and the words moved out from under
  /// the curve that is meant to open around them.
  static const double _artShiftUp = 62 / 390;
  static const double _artShiftEnd = 26 / 390;

  /// Design: title at y153 with the sweep's box opening at y63.
  ///
  /// Tightened by 22pt-at-390 to make room for «تذكرني» on the sign-in
  /// screen WITHOUT the form growing — the design's gap is generous
  /// and the checkbox is a single line. The drawing rises with it,
  /// because [_artShiftUp] is measured from the same box.
  static const double _titleTop = (153 - 63 - 22) / 390;

  static const double _markWidth = 27 / 390;
  static const double _markHeight = 38 / 390;

  /// Design: title 351 wide in a 390 frame — a 20pt gutter, the same one
  /// the fields below use.
  static const double _textGutter = 20 / 390;

  /// Design: title 21.03, subtitle 15.
  static const double _titleSize = 21.03;
  static const double _subtitleSize = 15;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final statusInset = MediaQuery.paddingOf(context).top + 8;

    return Padding(
      // Only the WRAPPED layout pads here. The banded one positions from
      // the screen top itself, because the design's numbers for those
      // three already include the status bar.
      padding: EdgeInsetsDirectional.only(
        top: illustration.wrapsHeading ? statusInset : 0,
      ),
      child: illustration.wrapsHeading
          ? _wrapped(context, width)
          : _banded(context, width, statusInset),
    );
  }

  /// The login sweep: drawing BEHIND the heading, bleeding off both
  /// sides, stretched taller than the copy so the curve opens around it.
  Widget _wrapped(BuildContext context, double width) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PositionedDirectional(
          start: (_artLeft + _artShiftEnd) * width,
          top: -(_artBleed + _artShiftUp) * width,
          bottom: -(_artBleed - _artShiftUp) * width,
          width: _artWidth * width,
          child: _art(context),
        ),
        // FULL WIDTH: this is the Stack's only non-positioned child, so
        // it would otherwise size to its widest line and be pinned to
        // the start edge by `Stack.alignment`.
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              SizedBox(height: _titleTop * width - 20),
              ..._copy(context, width),
              SizedBox(height: context.spacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  /// The other three: an object drawn in a band of its OWN above the
  /// heading, at the size and offset the design gives it.
  ///
  /// A `Stack` still, because two of the three run off the frame — but
  /// the drawing and the copy occupy separate vertical space rather
  /// than sharing it.
  Widget _banded(BuildContext context, double width, double statusInset) {
    // The design's `top` is measured from the top of the SCREEN, so the
    // status bar is already inside it — adding an inset on top of it,
    // as the wrapped layout does, pushed the drawing a bar's height too
    // far down on every device with a tall one. Floored at the inset so
    // a very tall status bar can never overlap the artwork.
    // Tightened by the same 22pt-at-390 the wrapped layout takes off
    // its heading, so all five auth screens start at one height.
    final top = math.max(
      statusInset,
      (illustration.top * width) - (22 / 390 * width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: top),
        SizedBox(
          height: illustration.height * width,
          // CENTRED, and allowed to overflow: two of the three are wider
          // than the frame.
          child: OverflowBox(
            maxWidth: double.infinity,
            child: SizedBox(
              width: illustration.width * width,
              child: _art(context),
            ),
          ),
        ),
        SizedBox(height: illustration.titleGap * width),
        ..._copy(context, width),
        SizedBox(height: context.spacing.lg),
      ],
    );
  }

  Widget _art(BuildContext context) {
    final art = _rawArt(context);
    // Only the sweep is shared (sign-in ↔ register). The other three
    // belong to one screen each, and a tag with a single endpoint is a
    // flight that can never happen.
    //
    // Which is exactly why the other three get an ENTRANCE instead: the
    // sweep arrives already animated, carried over from the screen
    // before it, and the three that have nowhere to fly from would
    // otherwise be the only part of the header that just appears. The
    // two are alternatives — an entrance around a hero would move the
    // rect the flight is aiming at.
    return illustration == AuthIllustration.loginRegister
        ? SharedHero(tag: AuthHeroTag.art, child: art)
        : ScreenEntrance.art(child: art);
  }

  Widget _rawArt(BuildContext context) => Transform.flip(
    // The asset is the Arabic composition. English mirrors it; Arabic
    // shows it as drawn.
    flipX:
        illustration.mirrorForLtr &&
        Directionality.of(context) == TextDirection.ltr,
    // THE STUDIO'S, when they have set one. CONTAIN, not fill: the
    // drawings have their own aspect and stretching one to an
    // arbitrary box bends the line weight. And no rounded corners —
    // this is line art, not a photo in a frame.
    child: DynamicAssetImage(
      section: AuthIllustration.cmsSection,
      assetKey: illustration.cmsKey,
      fallback: illustration.asset,
    ),
  );

  /// Title, subtitle and (where the drawing has no subject of its own)
  /// the vessel mark — the same in both layouts.
  List<Widget> _copy(BuildContext context, double width) {
    final text = context.textColors;
    final gutter = EdgeInsetsDirectional.symmetric(
      horizontal: _textGutter * width,
    );

    return [
      // The heading and its line CHANGE on every screen, so they fly
      // with the cross-fading shuttle: the old words dissolve into the
      // new ones as the block travels, rather than the text swapping
      // the instant the flight starts.
      SharedHero(
        tag: AuthHeroTag.title,
        entranceStep: 1,
        flightShuttleBuilder: crossFadeShuttle,
        child: Padding(
          padding: gutter,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.copyWith(
              color: text.primary,
              fontSize: _titleSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      if (subtitle != null) ...[
        SizedBox(height: context.spacing.sm),
        SharedHero(
          tag: AuthHeroTag.subtitle,
          entranceStep: 2,
          flightShuttleBuilder: crossFadeShuttle,
          child: Padding(
            padding: gutter,
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: text.primary,
                fontSize: _subtitleSize,
              ),
            ),
          ),
        ),
      ],
      if (showMark) ...[
        SizedBox(height: context.spacing.lg),
        SharedHero(
          tag: AuthHeroTag.mark,
          entranceStep: 3,
          child: GlobalImage.a(
            Assets.logos.mark.defaultPath,
            width: _markWidth * width,
            height: _markHeight * width,
            // A silhouette, not a photo — nothing to round.
            style: const ImageStyle(borderRadius: BorderRadius.zero),
          ),
        ),
      ],
    ];
  }
}
