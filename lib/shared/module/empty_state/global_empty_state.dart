import 'package:flutter/material.dart';

import '../../../core/a11y/semantics_extensions.dart';
import 'empty_state_models.dart';
import 'theme/empty_state_theme.dart';

export 'empty_state_models.dart';
export 'theme/empty_state_theme.dart';

/// Marks the entrance wrapper, so a test can find it without matching on
/// `Opacity` — the glyph's disc and the actions mount their own.
const kEmptyStateEntranceKey = ValueKey<String>('empty-state-entrance');

/// Marks the glyph's soft disc.
const kEmptyStateDiscKey = ValueKey<String>('empty-state-disc');

// ---------------------------------------------------------------------------
// GlobalEmptyState
// ---------------------------------------------------------------------------

/// "Nothing here yet": a glyph or illustration, a title, an optional
/// line of explanation, and up to two actions.
///
/// ```dart
/// GlobalEmptyState(
///   title: 'No invoices',
///   subtitle: 'Anything you send will show up here.',
///   primaryAction: GlobalFilledButton(text: 'New invoice', onPressed: …),
/// )
/// ```
class GlobalEmptyState extends StatefulWidget {
  const GlobalEmptyState({
    required this.title,
    super.key,
    this.subtitle,
    this.icon,
    this.illustrationWidget,
    this.primaryAction,
    this.secondaryAction,
    this.variant = EmptyStateVariant.fullPage,
    this.style = const EmptyStateStyle(),
    this.semanticLabel,
  });

  /// The headline. Says what is missing, not that something is missing.
  final String title;

  /// One line under it, explaining what would put something here.
  final String? subtitle;

  /// Glyph above the title. Ignored when [illustrationWidget] is set.
  final IconData? icon;

  /// A Lottie, an SVG, an image — anything. Outranks [icon].
  final Widget? illustrationWidget;

  final Widget? primaryAction;
  final Widget? secondaryAction;

  /// Full page, or inline inside a card.
  final EmptyStateVariant variant;

  /// Themeable style bag. Merges over `GlobalEmptyStateTheme`.
  final EmptyStateStyle style;

  /// Spoken instead of "title. subtitle".
  final String? semanticLabel;

  @override
  State<GlobalEmptyState> createState() => _GlobalEmptyStateState();
}

class _GlobalEmptyStateState extends State<GlobalEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _entrance;

  /// Whether the entrance has been started. It cannot run from
  /// `initState`, because whether it runs at all depends on a
  /// `MediaQuery` — which is not readable there.
  bool _started = false;

  /// What was last announced, so the same sentence is not repeated on
  /// every rebuild.
  String? _announced;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _entrance = const AlwaysStoppedAnimation(1);
  }

  @override
  void didUpdateWidget(GlobalEmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A search-as-you-type screen keeps ONE empty state mounted and
    // swaps its text, so without this the block only ever arrives once
    // and every later message appears with no motion and no
    // announcement — the two things that say "this changed".
    if (_spokenLabel == _labelOf(oldWidget)) return;
    _started = false;
    _controller.value = 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ResolvedEmptyStateStyle _resolve() => widget.style.resolve(
    context,
    variant: widget.variant,
    disableAnimations: MediaQuery.disableAnimationsOf(context),
  );

  /// Announces the empty state, once per message.
  ///
  /// A list going empty is a content change with no focus change, so a
  /// screen reader says nothing about it — the rows are simply gone and
  /// the user is told why only if they go looking.
  void _announce(ResolvedEmptyStateStyle rs) {
    final message = _spokenLabel;
    if (!rs.announceOnAppear || _announced == message) return;
    _announced = message;
    // After the frame: an announcement fired during build races the
    // semantics tree it is describing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) announceForAccessibility(context, message);
    });
  }

  /// Arms the entrance on the first build that can see a `MediaQuery`.
  ///
  /// The controller used to be built in `initState` from the raw style,
  /// so reduced motion never reached it — the block faded and rose
  /// whatever the device asked for.
  void _armEntrance(ResolvedEmptyStateStyle rs) {
    if (_started || !rs.animateEntrance) return;
    _started = true;
    _controller.duration = rs.animationDuration;
    _entrance = CurvedAnimation(
      parent: _controller,
      curve: rs.animationCurve,
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final rs = _resolve();
    _armEntrance(rs);
    _announce(rs);

    final content = Padding(
      padding: rs.padding,
      child: Column(
        // A full-page empty state fills the height it is GIVEN, which
        // is what centres it; a compact one takes only what it needs.
        mainAxisSize: widget.variant.isCompact
            ? MainAxisSize.min
            : MainAxisSize.max,
        mainAxisAlignment: widget.variant.isCompact
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: [
          _illustration(rs),
          SizedBox(height: rs.spacing),
          // The title and subtitle are spoken by the wrapper, once, as
          // one sentence — reading them twice is what an unlabelled
          // Text inside a labelled Semantics does.
          // The reading measure caps the SENTENCES, not the block: the
          // glyph and the actions size themselves, and a subtitle
          // running the full width of a tablet stops scanning as one
          // line. Same reason `GlobalContainer.prose` exists.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rs.maxContentWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    widget.title,
                    style: rs.titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  SizedBox(height: rs.subtitleGap),
                  ExcludeSemantics(
                    child: Text(
                      widget.subtitle!,
                      style: rs.subtitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.primaryAction != null ||
              widget.secondaryAction != null) ...[
            SizedBox(height: rs.actionGap),
            if (widget.primaryAction != null) widget.primaryAction!,
            if (widget.secondaryAction != null) ...[
              SizedBox(height: rs.subtitleGap),
              widget.secondaryAction!,
            ],
          ],
        ],
      ),
    );

    return Semantics(
      label: _spokenLabel,
      // The actions keep their OWN nodes: an empty state whose button
      // has been folded into its description cannot be pressed by name.
      explicitChildNodes: true,
      child: rs.animateEntrance ? _wrapEntrance(content, rs) : content,
    );
  }

  String get _spokenLabel => _labelOf(widget);

  static String _labelOf(GlobalEmptyState w) =>
      w.semanticLabel ??
      (w.subtitle == null ? w.title : '${w.title}. ${w.subtitle}');

  Widget _illustration(ResolvedEmptyStateStyle rs) {
    if (widget.illustrationWidget != null) return widget.illustrationWidget!;
    return Container(
      key: kEmptyStateDiscKey,
      padding: rs.iconPadding,
      decoration: BoxDecoration(
        color: rs.iconBackgroundColor,
        borderRadius: rs.discRadius,
      ),
      child: Icon(
        widget.icon ?? Icons.inbox_rounded,
        size: rs.iconSize,
        color: rs.iconColor,
      ),
    );
  }

  Widget _wrapEntrance(Widget content, ResolvedEmptyStateStyle rs) =>
      AnimatedBuilder(
        key: kEmptyStateEntranceKey,
        animation: _entrance,
        builder: (context, child) => Opacity(
          // An Opacity at ZERO drops its subtree from the semantics
          // tree, so for the whole entrance a screen reader landing on
          // this page found nothing at all — no title, no action. The
          // content is present the entire time; only its paint is
          // catching up.
          alwaysIncludeSemantics: true,
          opacity: _entrance.value,
          child: Transform.translate(
            offset: Offset(0, rs.entranceOffset * (1 - _entrance.value)),
            child: child,
          ),
        ),
        child: content,
      );
}
