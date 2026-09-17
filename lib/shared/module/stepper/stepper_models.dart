import 'package:flutter/material.dart';

/// A single step in the stepper.
class GlobalStepItem {
  const GlobalStepItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.content,
    this.isActive = false,
    this.isCompleted = false,
    this.isError = false,
    this.isDisabled = false,
    this.customIndicator,
    this.timestamp,
    this.connectorLabel,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Content widget shown when step is active (vertical/timeline mode).
  final Widget? content;

  final bool isActive;
  final bool isCompleted;
  final bool isError;

  /// When true, the step is greyed out and non-tappable.
  final bool isDisabled;

  /// Custom widget for the step indicator circle.
  final Widget? customIndicator;

  /// Timestamp text shown on the left side in timeline mode.
  final String? timestamp;

  /// Label shown on the connector after this step (e.g. "2 hours", "3 days").
  final String? connectorLabel;

  /// Action buttons shown below content (e.g. Continue, Cancel).
  final List<Widget>? actions;
}

/// Orientation/layout of the stepper.
enum StepperOrientation {
  horizontal,
  vertical,

  /// Timeline: timestamps left, content right, indicators center.
  timeline,

  /// Alternating: content alternates left/right sides.
  alternating,
}

/// Style of the connector line between steps.
enum StepperConnectorStyle {
  solid,
  dashed,
  dotted,
  none,
}

/// Transition animation for step content when switching steps.
enum StepContentTransition {
  /// No animation — instant switch.
  none,

  /// Fade in/out.
  fade,

  /// Slide in from the direction of navigation.
  slide,

  /// Combined fade + slide.
  fadeSlide,

  /// Scale up from small.
  scale,
}
