import 'package:flutter/material.dart';

/// Callback the step body uses to read + mutate the in-progress data.
typedef WizardDataSetter = void Function(Map<String, dynamic> patch);

/// Builder for a step's body. Receives current `data` and a `setData`
/// callback. Patch semantics — only the fields you pass are merged
/// into the wizard's data map.
typedef WizardStepBuilder =
    Widget Function(
      BuildContext context,
      Map<String, dynamic> data,
      WizardDataSetter setData,
    );

/// Predicate over the wizard's full data map. Returns `true` when the
/// condition is met.
typedef WizardDataPredicate = bool Function(Map<String, dynamic> data);

/// A single step in a [GlobalWizard]. Builders are responsible for
/// rendering their own fields (compose with `GlobalTextFormField`
/// or the common `*Field` wrappers, or any custom widget) — wizard owns the
/// orchestration only.
@immutable
class WizardStep {
  const WizardStep({
    required this.id,
    required this.title,
    required this.builder,
    this.subtitle,
    this.icon,
    this.validator,
    this.skipWhen,
  });

  /// Stable identifier — used in the stepper labels + `onStepChanged`
  /// callbacks. Doesn't need to match any data key.
  final String id;

  /// Headline shown in the stepper rail + the step body when no
  /// custom builder header is rendered.
  final String title;

  final String? subtitle;

  /// Icon shown in the stepper rail's circle. Falls back to step
  /// number when null.
  final IconData? icon;

  /// Step body builder.
  final WizardStepBuilder builder;

  /// Returns true when the step's data is valid + the user may
  /// advance. Called on every data change and on tap of Next. When
  /// null, the step has no gate (always advanceable).
  final WizardDataPredicate? validator;

  /// When this predicate returns true, the step is skipped during
  /// navigation. Lets you branch the flow without conditionally
  /// constructing the steps list.
  final WizardDataPredicate? skipWhen;
}

/// Stepper visual style — drives the header rail above the step
/// body. Each variant routes through an existing module:
///   * [dots] — uses `GlobalDotIndicator` with the configured effect
///   * [linear] — `LinearProgressIndicator`
///   * [numbered] — `GlobalStepper` horizontal orientation
///   * [chips] — wrap of [Chip]s, future steps muted
///   * [vertical] — `GlobalStepper` vertical orientation (rail on left)
enum WizardVariant {
  dots,
  linear,
  numbered,
  chips,
  vertical,
}

/// Animation applied to the step body when the active step changes.
enum WizardTransition {
  /// Slide horizontally — incoming from right (forward) or left
  /// (back).
  slide,

  /// Fade out + fade in.
  fade,

  /// Combined slide + fade. Default — feels the most polished.
  slideAndFade,

  /// Scale + fade.
  scale,

  /// Hero — caller wires `Hero(tag:)` widgets inside step bodies and
  /// the framework animates between matching tags. Wizard renders a
  /// fast crossfade fallback for non-Hero content.
  hero,

  /// Snap — no animation.
  none,
}

/// Presentation surface when calling `GlobalWizard.show()`.
enum WizardPresentation {
  /// Push a full-screen route.
  fullPage,

  /// Modal bottom sheet (Material `showModalBottomSheet` via
  /// `GlobalBottomSheet`).
  bottomSheet,

  /// Adaptive dialog.
  dialog,

  /// Pick automatically: phone-compact → bottomSheet, medium+ →
  /// dialog. Falls back to fullPage when neither fits.
  adaptive,
}

/// Visual + behavioural config for [GlobalWizard].
@immutable
class WizardStyle {
  const WizardStyle({
    this.variant = WizardVariant.numbered,
    this.transition = WizardTransition.slideAndFade,
    this.headerPadding = const EdgeInsets.fromLTRB(16, 16, 16, 8),
    this.bodyPadding = const EdgeInsets.all(16),
    this.footerPadding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    this.transitionDuration = const Duration(milliseconds: 320),
    this.showStepLabels = true,
    this.allowJumpToCompleted = true,
    this.showBackOnFirstStep = false,
    this.backLabel,
    this.nextLabel,
    this.submitLabel,
    this.cancelLabel,
    this.confirmDiscardDraftOnCancel = true,
    this.scrollable = true,
    this.background,
    this.borderRadius,
  });

  final WizardVariant variant;
  final WizardTransition transition;
  final EdgeInsets headerPadding;
  final EdgeInsets bodyPadding;
  final EdgeInsets footerPadding;
  final Duration transitionDuration;

  /// Show titles beneath the stepper indicator (when supported by
  /// the chosen variant).
  final bool showStepLabels;

  /// Tap a completed-step indicator to jump back. Forward jumps are
  /// always gated by the per-step validators.
  final bool allowJumpToCompleted;

  /// Show Back button on step 0. Default false (hidden when no
  /// previous step exists).
  final bool showBackOnFirstStep;

  /// Chrome button labels — `null` renders the localized defaults.
  final String? backLabel;
  final String? nextLabel;
  final String? submitLabel;
  final String? cancelLabel;

  /// When a draftKey is set and the user backs out, prompt before
  /// discarding the in-progress data.
  final bool confirmDiscardDraftOnCancel;

  /// Wrap the step body in a SingleChildScrollView. Off when callers
  /// supply their own scroll handling (e.g. a `ListView`).
  final bool scrollable;

  final Color? background;
  final BorderRadius? borderRadius;
}
