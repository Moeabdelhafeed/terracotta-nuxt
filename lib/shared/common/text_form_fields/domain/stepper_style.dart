import 'package:flutter/material.dart';

/// Which glyph pair the − / + steppers on [QuantityField] / [MeasurementField]
/// draw. Only the icons change; behaviour (decrement / increment, clamp,
/// long-press repeat) is identical.
enum StepperIcons {
  /// `−` decrement / `+` increment. The default.
  plusMinus,

  /// `⌄` decrement / `⌃` increment — chevron arrows (down = less, up = more).
  arrows;

  /// Icon for the DECREMENT (less) button.
  IconData get decrementIcon => switch (this) {
    StepperIcons.plusMinus => Icons.remove,
    StepperIcons.arrows => Icons.keyboard_arrow_down,
  };

  /// Icon for the INCREMENT (more) button.
  IconData get incrementIcon => switch (this) {
    StepperIcons.plusMinus => Icons.add,
    StepperIcons.arrows => Icons.keyboard_arrow_up,
  };
}
