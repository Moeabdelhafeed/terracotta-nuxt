import 'package:flutter/material.dart';

/// One option in a picker. Generic on the value type so each picker
/// can pass its native enum / model.
@immutable
class PickerItem<T> {
  const PickerItem({
    required this.value,
    required this.label,
    this.icon,
    this.subtitle,
    this.leading,
  });

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;

  /// Custom leading widget. Wins over [icon] when both are provided.
  final Widget? leading;
}
