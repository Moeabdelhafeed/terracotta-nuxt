import 'package:flutter/material.dart';

import '../../../../core/localization/strings/module_strings.dart';
import '../../../module/toggle_group/global_toggle_group.dart';

/// Delivery channels for notifications.
enum NotificationChannel { push, email, sms }

/// Push / Email / SMS channel picker — settings staple. Complements
/// `NotificationsSwitchRow`: the switch is the master on/off, this
/// picks which channels stay on. Multi-select, localized.
class NotificationChannelsToggle extends StatelessWidget {
  const NotificationChannelsToggle({
    super.key,
    required this.selected,
    required this.onChanged,
    this.style = const ToggleGroupStyle(),
    this.enabled = true,
  });

  final List<NotificationChannel> selected;
  final ValueChanged<List<NotificationChannel>> onChanged;
  final ToggleGroupStyle style;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Locale dependency — labels resolve via Tr/S (static reads).
    Localizations.maybeLocaleOf(context);
    return GlobalToggleGroup<NotificationChannel>(
      items: [
        ToggleGroupItem(
          value: NotificationChannel.push,
          label: ToggleGroupStrings.channelPush,
        ),
        ToggleGroupItem(
          value: NotificationChannel.email,
          label: ToggleGroupStrings.channelEmail,
        ),
        ToggleGroupItem(
          value: NotificationChannel.sms,
          label: ToggleGroupStrings.channelSms,
        ),
      ],
      selectedValues: selected,
      onChanged: onChanged,
      multiSelect: true,
      // Dense — Arabic labels run long ("بريد إلكتروني").
      style: const ToggleGroupStyle(
        itemPadding: EdgeInsets.symmetric(horizontal: 8),
      ).mergedWith(style),
      enabled: enabled,
    );
  }
}
