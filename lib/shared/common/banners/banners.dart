import 'package:flutter/material.dart';

import '../../../core/localization/strings/banner_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/connectivity_strings.dart';
import '../../../core/localization/strings/maintenance_strings.dart';
import '../../module/banner/global_banner.dart';

// ---------------------------------------------------------------------------
// Canonical banners
// ---------------------------------------------------------------------------

/// The three notices this app actually shows, with their copy, glyph
/// and type already decided.
///
/// The MODULE deliberately knows none of this — it must not know what
/// an app calls things — so without these every feature that goes
/// offline invents its own wording, and six screens end up saying six
/// different things about the same state. Same reason
/// `shared/common/empty_states/` exists.

/// The connection is gone. Not dismissible: the state is still true
/// after you close it.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onRetry, this.show = true});

  final VoidCallback? onRetry;
  final bool show;

  @override
  Widget build(BuildContext context) => GlobalBanner(
    title: ConnectivityStrings.offline,
    message: BannerStrings.offlineMessage,
    type: BannerType.warning,
    icon: Icons.wifi_off_rounded,
    show: show,
    dismissible: false,
    actions: onRetry == null
        ? null
        : [BannerAction(label: CommonStrings.retry, onPressed: onRetry)],
  );
}

/// A newer build is available. Dismissible — it is an invitation, not a
/// blocker; the update GATE is what blocks.
class UpdateAvailableBanner extends StatelessWidget {
  const UpdateAvailableBanner({
    super.key,
    this.onUpdate,
    this.onDismiss,
    this.show = true,
  });

  final VoidCallback? onUpdate;
  final VoidCallback? onDismiss;
  final bool show;

  @override
  Widget build(BuildContext context) => GlobalBanner(
    title: BannerStrings.updateTitle,
    message: BannerStrings.updateMessage,
    type: BannerType.info,
    icon: Icons.system_update_rounded,
    show: show,
    onDismiss: onDismiss,
    actions: onUpdate == null
        ? null
        : [
            BannerAction(
              label: BannerStrings.updateAction,
              onPressed: onUpdate,
            ),
          ],
  );
}

/// The backend is down or going down. Not dismissible, and collapsible:
/// the message is often long and the title alone carries the state.
class MaintenanceBanner extends StatelessWidget {
  const MaintenanceBanner({super.key, this.message, this.show = true});

  /// Remote config usually supplies this; the default is the app's own.
  final String? message;
  final bool show;

  @override
  Widget build(BuildContext context) => GlobalBanner(
    title: MaintenanceStrings.defaultTitle,
    message: message ?? MaintenanceStrings.defaultMessage,
    type: BannerType.warning,
    icon: Icons.construction_rounded,
    show: show,
    dismissible: false,
    collapsible: true,
  );
}
