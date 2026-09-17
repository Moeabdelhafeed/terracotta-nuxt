import 'package:flutter/material.dart';

import '../../module/container/global_container.dart';
import '../../module/divider/global_divider.dart';
import '../../module/switch/global_switch.dart';

// ---------------------------------------------------------------------------
// Canonical containers
// ---------------------------------------------------------------------------

/// The shapes this app builds out of `GlobalContainer`, named.
///
/// Material's `ListTile`, `Card`, `ExpansionTile` and `SwitchListTile`
/// all draw their own surface from `Theme.of(context)` — a different
/// corner, a different fill and a different shadow from every
/// `GlobalContainer` beside them, and none of them move when the app is
/// rebranded. The container already had the anatomy: with no `child` it
/// builds `Row(leading, Column(title, subtitle), trailing)`, which IS a
/// tile. What it lacked was a name, a floor a finger can hit, and slots
/// that box an oversized glyph.
///
/// Every wrapper here takes `style:` straight through to
/// `ContainerStyle`, so none of them is a wall: anything the container
/// can do, a caller can still ask for.
///
/// Guard: `test/container/container_adoption_test.dart`.

/// A row. What `ListTile` is for.
class AppTile extends StatelessWidget {
  const AppTile({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.subtitleWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.style = const ContainerStyle(),
    this.selected = false,
    this.enabled = true,
    this.dense = false,
    this.semanticLabel,
  });

  final String? title;
  final String? subtitle;

  /// A title that is not a plain string — a highlighted search match.
  /// `ListTile.title` is a Widget, so a wrapper that only takes a String
  /// is a wall.
  final Widget? titleWidget;
  final Widget? subtitleWidget;

  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final ContainerStyle style;
  final bool selected;
  final bool enabled;
  final bool dense;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => GlobalContainer.tile(
    title: title,
    subtitle: subtitle,
    titleWidget: titleWidget,
    subtitleWidget: subtitleWidget,
    leading: leading,
    trailing: trailing,
    onTap: onTap,
    onLongPress: onLongPress,
    style: style,
    selected: selected,
    enabled: enabled,
    dense: dense,
    semanticLabel: semanticLabel,
  );
}

/// A row that GOES somewhere: the chevron is the affordance.
///
/// Three places had already hand-rolled exactly this — the FAQ index,
/// the PDF recents list and the share sheet — each with its own chevron
/// and its own idea of the gap before it.
class AppNavTile extends StatelessWidget {
  const AppNavTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.style = const ContainerStyle(),
    this.enabled = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  final ContainerStyle style;
  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) => AppTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    // Mirrors in Arabic, where "onward" is to the left.
    trailing: const Icon(Icons.chevron_right_rounded, textDirection: null),
    onTap: onTap,
    style: style,
    enabled: enabled,
    dense: dense,
  );
}

/// A row that TOGGLES. What `SwitchListTile` is for.
///
/// The whole row takes the tap, and the switch is excluded from the
/// semantics tree — two nodes saying the same thing, one of them a
/// switch and one a button, is worse than one that says it properly.
class AppSettingTile extends StatelessWidget {
  const AppSettingTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.style = const ContainerStyle(),
    this.enabled = true,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final ContainerStyle style;
  final bool enabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final live = enabled && onChanged != null;
    return Semantics(
      container: true,
      toggled: value,
      enabled: live,
      label: subtitle == null ? title : '$title, $subtitle',
      onTap: live ? () => onChanged!(!value) : null,
      excludeSemantics: true,
      child: AppTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: GlobalSwitch(
          value: value,
          onChanged: live ? onChanged : null,
        ),
        onTap: live ? () => onChanged!(!value) : null,
        style: style,
        enabled: enabled,
        dense: dense,
      ),
    );
  }
}

/// A surface with a title. What `Card` is for.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.child,
    this.footer,
    this.onTap,
    this.style = const ContainerStyle(),
    this.loading = false,
    this.badge,
    this.ribbon,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? child;
  final Widget? footer;
  final VoidCallback? onTap;
  final ContainerStyle style;
  final bool loading;
  final ContainerBadge? badge;
  final ContainerRibbon? ribbon;

  @override
  Widget build(BuildContext context) => GlobalContainer(
    title: title,
    subtitle: subtitle,
    leading: leading,
    trailing: trailing,
    footer: footer,
    onTap: onTap,
    style: style,
    loading: loading,
    badge: badge,
    ribbon: ribbon,
    child: child,
  );
}

/// A card whose picture is the point.
class AppMediaCard extends StatelessWidget {
  const AppMediaCard({
    super.key,
    required this.image,
    this.title,
    this.subtitle,
    this.onTap,
    this.aspectRatio = 16 / 9,
    this.style = const ContainerStyle(),
    this.badge,
    this.ribbon,
  });

  final ImageProvider image;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double aspectRatio;
  final ContainerStyle style;
  final ContainerBadge? badge;
  final ContainerRibbon? ribbon;

  @override
  Widget build(BuildContext context) => GlobalContainer(
    title: title,
    subtitle: subtitle,
    onTap: onTap,
    aspectRatio: aspectRatio,
    badge: badge,
    ribbon: ribbon,
    style: style.copyWith(backgroundImage: image),
  );
}

/// A panel that opens. What `ExpansionTile` is for.
class AppExpansionTile extends StatelessWidget {
  const AppExpansionTile({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.style = const ContainerStyle(),
    this.initiallyExpanded = false,
    this.onToggle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;
  final ContainerStyle style;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) => GlobalExpandableContainer(
    style: style,
    initiallyExpanded: initiallyExpanded,
    onToggle: onToggle,
    header: AppTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      // The panel's own header owns the tap and the chevron.
      style: const ContainerStyle(
        padding: EdgeInsets.zero,
        shadow: [],
        backgroundColor: Color(0x00000000),
      ),
    ),
    child: child,
  );
}

/// A row that swipes away. What `Dismissible` is for.
class AppSwipeTile extends StatelessWidget {
  const AppSwipeTile({
    super.key,
    required this.child,
    required this.onDismiss,
    this.startIcon = Icons.archive_rounded,
    this.startLabel,
    this.startColor,
    this.endIcon = Icons.delete_rounded,
    this.endLabel,
    this.endColor,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final IconData startIcon;
  final String? startLabel;
  final Color? startColor;
  final IconData endIcon;
  final String? endLabel;
  final Color? endColor;

  @override
  Widget build(BuildContext context) => GlobalDismissibleContainer(
    onDismiss: onDismiss,
    startIcon: startIcon,
    startLabel: startLabel,
    startColor: startColor,
    endIcon: endIcon,
    endLabel: endLabel,
    endColor: endColor,
    child: child,
  );
}

/// A card that can be PICKED, out of several.
class AppSelectableCard extends StatelessWidget {
  const AppSelectableCard({
    super.key,
    required this.selected,
    required this.onToggle,
    this.child,
    this.style = const ContainerStyle(),
    this.effect = ContainerSelectionEffect.outline,
    this.mark,
  });

  final bool selected;
  final VoidCallback onToggle;
  final Widget? child;
  final ContainerStyle style;
  final ContainerSelectionEffect effect;
  final ContainerSelectionMark? mark;

  @override
  Widget build(BuildContext context) => GlobalSelectableContainer(
    selected: selected,
    onToggle: onToggle,
    style: style,
    effect: effect,
    mark: mark,
    child: child,
  );
}

/// A GROUP of rows under one heading, with rules between them.
///
/// The shape a settings screen is made of, and the one thing the tile
/// set was still missing — every caller was hand-rolling its own header
/// and its own dividers, which is exactly where two screens start to
/// disagree about the gap above a section.
///
/// The rows sit on the card's own surface, so each one is flat: a
/// shadow per row inside a card that already has one reads as a stack
/// of cards rather than a list.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.style = const ContainerStyle(),
    this.divided = true,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final ContainerStyle style;

  /// A rule between rows. Off for a group whose rows are already cards.
  final bool divided;

  @override
  Widget build(BuildContext context) => GlobalContainer(
    title: title,
    subtitle: subtitle,
    // The card owns the outside; the rows own nothing but their own
    // height, so the padding goes on the rows and not on the card.
    style: style.copyWith(padding: EdgeInsets.zero),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && divided) const GlobalDivider(),
          children[i],
        ],
      ],
    ),
  );
}
