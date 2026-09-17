import 'package:flutter/material.dart';

import '../../../core/feedback/feedback_options.dart';
import '../../../core/feedback/feedback_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../data/services/remote_config_service.dart';
import '../../common/containers/containers.dart';
import '../buttons/global_icon_button.dart';
import 'feedback_screen.dart';

/// Drop-in trigger that opens [FeedbackScreen] as a modal route. Use
/// in drawers, settings rows, dev hub, debug overlays.
///
/// Variants:
/// - [FeedbackButton.icon] — `IconButton` for AppBar actions
/// - [FeedbackButton.tile] — `ListTile` for settings menus
/// - [FeedbackButton.fab] — floating action button
/// - default — text button
///
/// Renders nothing when feedback is disabled (compile-time
/// `options.enabled` or RC `feedback_enabled`).
class FeedbackButton extends StatelessWidget {
  const FeedbackButton({
    this.label,
    this.icon = Icons.feedback_outlined,
    this.options = const FeedbackOptions(),
    this.style = FeedbackButtonStyle.text,
    super.key,
  });

  const FeedbackButton.icon({
    this.icon = Icons.feedback_outlined,
    this.options = const FeedbackOptions(),
    super.key,
  }) : label = '',
       style = FeedbackButtonStyle.icon;

  const FeedbackButton.tile({
    this.label,
    this.icon = Icons.feedback_outlined,
    this.options = const FeedbackOptions(),
    super.key,
  }) : style = FeedbackButtonStyle.tile;

  const FeedbackButton.fab({
    this.icon = Icons.feedback_outlined,
    this.options = const FeedbackOptions(),
    super.key,
  }) : label = '',
       style = FeedbackButtonStyle.fab;

  /// `null` renders the localized default ("Send feedback").
  final String? label;
  final IconData icon;
  final FeedbackOptions options;
  final FeedbackButtonStyle style;

  bool _shouldRender() =>
      options.enabled && RemoteConfigService.feedbackEnabled;

  Future<void> _open(BuildContext context) async {
    await Navigator.of(context).push(
      // A task screen: up from the bottom, and no leading-edge swipe
      // — a half-written report should not be lost to a stray drag.
      RouteTransition.route<void>(
        context: context,
        name: 'feedback',
        fullscreenDialog: true,
        style: TransitionStyle.modal,
        child: FeedbackScreen(options: options),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender()) return const SizedBox.shrink();
    switch (style) {
      case FeedbackButtonStyle.text:
        return TextButton.icon(
          onPressed: () => _open(context),
          icon: Icon(icon),
          label: Text(label ?? FeedbackStrings.sendFeedback),
        );
      case FeedbackButtonStyle.icon:
        return GlobalIconButton(
          tooltip: FeedbackStrings.sendFeedback,
          onPressed: () => _open(context),
          iconData: icon,
        );
      case FeedbackButtonStyle.tile:
        return AppNavTile(
          leading: Icon(icon),
          title: label ?? FeedbackStrings.sendFeedback,
          onTap: () => _open(context),
        );
      case FeedbackButtonStyle.fab:
        return FloatingActionButton(
          tooltip: FeedbackStrings.sendFeedback,
          onPressed: () => _open(context),
          child: Icon(icon),
        );
    }
  }
}

enum FeedbackButtonStyle { text, icon, tile, fab }
