import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/window_size_class.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';

/// The panel every Terracotta bottom sheet sits in.
///
/// Rounded top corners, a grab handle, a start-aligned title, and a
/// scrolling body.
///
/// **The handle belongs to the PANEL, and so it is drawn here.** The
/// app's `BottomSheetThemeData` sets `showDragHandle: true`, which
/// draws one in the route's own surface — and these sheets make that
/// surface transparent so the shell can paint a panel that is
/// sometimes coral. The route's handle therefore floated on the dimmed
/// backdrop above the panel, detached from it, while the shell drew a
/// second one inside. [showTerracottaSheet] turns the route's off so
/// there is exactly one, in the right place. The radius is [BorderRadiusDirectional] so the two
/// top corners are named by reading order rather than by side — they
/// are equal here, but naming them logically keeps the rule intact and
/// means a future asymmetric sheet mirrors for free.
///
/// [tint] paints the panel for a sheet the design colours — the
/// celebration upsell is coral rather than white.
///
/// **The side margin belongs to the CHILDREN, not the panel.** A shell
/// that padded itself clipped every horizontal strip inside it: the
/// date strip has to run to both screen edges so a day can scroll in
/// from off-screen, and a strip inset by the panel loses its first and
/// last tile behind the gutter. Wrap a child in [SheetBleed] to opt it
/// out; everything else is gutter-padded for you.
class SheetShell extends StatelessWidget {
  const SheetShell({
    required this.children,
    this.title,
    this.tint,
    this.footer,
    this.heightFactor = 0.72,
    this.maxHeightFactor,
    this.centerTitle = false,
    super.key,
  });

  final String? title;

  /// Centred rather than start-aligned. The QR sheet's heading sits
  /// over a symbol that is itself centred; start-aligning it left the
  /// two on different axes.
  final bool centerTitle;
  final List<Widget> children;
  final Color? tint;

  /// How much of the screen the panel takes, or NULL to size it to its
  /// own contents.
  ///
  /// A fixed fraction is right for a sheet whose body is a list that
  /// can run long. It is wrong for a short one: the QR sheet has a
  /// symbol, a line of instruction and a button, and 62% of the screen
  /// left a field of empty under them AND put that short content in a
  /// scroll view that could never scroll.
  ///
  final double? heightFactor;

  /// What [heightFactor] becomes in a short window — see the note
  /// where it is applied. Nearly the whole screen, because there is
  /// not much of it and the sheet is what the reader is looking at.
  static const _shortHeightFactor = 0.94;

  /// A CEILING for a content-sized panel — the sheet grows with what is
  /// in it and starts scrolling only once it would be taller than this
  /// much of the screen.
  ///
  /// The selection sheet is the case: one piece should not open a panel
  /// two thirds of the screen tall with a field of empty under it, and
  /// twelve pieces must still be reachable. Read with
  /// [heightFactor] null; meaningless otherwise.
  final double? maxHeightFactor;

  /// Pinned to the panel's foot, below the body.
  ///
  /// A sheet's ACTION belongs at the bottom of the sheet, not at the
  /// bottom of its content — a short list left «تغيير» floating in the
  /// middle of the panel with empty space under it, and a long one
  /// pushed it off-screen.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final onTint = tint == null
        ? context.textColors.primary
        : context.textColors.onPrimary;

    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: tint ?? context.backgroundColors.surface,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(context.radii.xl),
          topEnd: Radius.circular(context.radii.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        // VERTICAL only. The sides are each child's own.
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.md).copyWith(
            // ABOVE THE KEYBOARD.
            //
            // `showModalBottomSheet` does not lift its panel for the
            // keyboard, and nothing here read `viewInsets` — so a
            // sheet with a field in it opened, the keyboard came up in
            // front of it, and the reader typed into something they
            // could not see.
            //
            // `viewInsets.bottom` is the keyboard's own height, zero
            // when it is down, so this costs nothing on a sheet that
            // never asks for one.
            bottom: spacing.md + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Sized to its own contents when no fraction was asked
            // for — otherwise the column tries to fill an unbounded
            // height and the sheet has nothing to measure.
            mainAxisSize: heightFactor == null
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              Center(child: _Handle(onColored: tint != null)),
              SizedBox(height: spacing.md),
              if (title != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.md),
                  child: Text(
                    title!,
                    textAlign: centerTitle ? TextAlign.center : null,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: onTint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: spacing.md),
              ],
              // NO SCROLL VIEW on a content-sized sheet. A body of
              // three short things in a scrollable that can never
              // scroll is a gesture arena entry that eats drags for
              // nothing.
              if (heightFactor == null && maxHeightFactor == null)
                _Body(spacing: spacing.md, children: children)
              else if (heightFactor == null)
                // Flexible, not Expanded: under a ceiling the column
                // shrink-wraps its content and only the overflow
                // scrolls.
                Flexible(
                  child: GlobalScrollable(
                    child: _Body(spacing: spacing.md, children: children),
                  ),
                )
              else
                Expanded(
                  child: GlobalScrollable(
                    child: _Body(spacing: spacing.md, children: children),
                  ),
                ),
              if (footer != null) ...[
                SizedBox(height: spacing.md),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: spacing.md),
                  child: footer,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // A fraction of the screen for a body that can run long; sized to
    // its own contents otherwise, under a ceiling when one was named.
    //
    // MORE OF A SHORT WINDOW. 72% is a comfortable panel on a phone
    // held upright — 600 points of a 844-point screen. Turned
    // sideways the same fraction is 280 points, most of which the
    // handle, the heading and the footer button have already spent:
    // the body ends up a two-line slot the reader scrolls a whole
    // form through. Landscape is where a sheet needs the screen, not
    // where it should give three-quarters of it back.
    if (heightFactor != null) {
      return FractionallySizedBox(
        heightFactor: context.windowHeight == WindowHeightClass.compact
            ? _shortHeightFactor
            : heightFactor,
        child: panel,
      );
    }
    if (maxHeightFactor == null) return panel;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor!,
      ),
      child: panel,
    );
  }
}

/// The children, each gutter-padded unless it asked to bleed.
class _Body extends StatelessWidget {
  const _Body({required this.children, required this.spacing});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final child in children)
        if (child is SheetBleed)
          child.child
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing),
            child: child,
          ),
    ],
  );
}

/// Marks a [SheetShell] child that must reach the panel's own edges.
///
/// A horizontal strip is the case: it carries its own leading inset so
/// the first tile clears the edge, and it has to be able to scroll a
/// tile in from beyond it. Padded by the shell as well, the strip is
/// inset twice and clipped at both ends.
class SheetBleed extends StatelessWidget {
  const SheetBleed({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Opens a sheet whose panel is a [SheetShell].
///
/// The one place these six sheets agree on their route. `showDragHandle`
/// is OFF: the surface is transparent so the shell can paint its own
/// panel — sometimes coral — and a handle drawn by the route lands on
/// the scrim above that panel rather than inside it.
Future<T?> showTerracottaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  showDragHandle: false,
  builder: builder,
);

/// 15%-black on a light panel, 35%-white on a coloured one — the two
/// treatments the design actually uses.
class _Handle extends StatelessWidget {
  const _Handle({required this.onColored});

  final bool onColored;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 98,
    height: 5,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: onColored
            ? context.textColors.onPrimary.withValues(alpha: 0.35)
            : context.textColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(context.radii.full),
      ),
    ),
  );
}
