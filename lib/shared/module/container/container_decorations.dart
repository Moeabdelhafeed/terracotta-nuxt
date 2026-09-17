import 'package:flutter/material.dart';

import 'container_defaults.dart';

/// Configuration for a container badge overlay.
@immutable
class ContainerBadge {
  const ContainerBadge({
    this.text,
    this.icon,
    this.widget,
    this.color,
    this.textColor,
    this.position = ContainerBadgePosition.topRight,
    this.offset = Offset.zero,
    this.size,
  });

  /// Badge text (e.g. "3", "NEW").
  final String? text;

  /// Badge icon.
  final IconData? icon;

  /// Custom badge widget. Takes priority.
  final Widget? widget;

  /// Badge background color. Null takes the palette's primary.
  final Color? color;

  /// Badge text color. Null takes what reads ON the badge's fill — it
  /// was a hard-coded `Colors.white`, which disappears the moment the
  /// fill is a light colour.
  final Color? textColor;

  /// Corner position.
  final ContainerBadgePosition position;

  /// Extra offset from the corner.
  final Offset offset;

  /// Badge size (for icon/dot badges).
  final double? size;
}

/// Configuration for a corner ribbon.
@immutable
class ContainerRibbon {
  const ContainerRibbon({
    required this.text,
    this.color,
    this.textColor,
    this.position = ContainerRibbonPosition.topRight,
    this.fontSize = ContainerDefaults.ribbonFontSize,
  });

  final String text;

  /// Null takes the palette's primary.
  final Color? color;

  /// Null takes what reads ON [color].
  final Color? textColor;

  final ContainerRibbonPosition position;
  final double fontSize;
}
