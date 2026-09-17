import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `banner_` key prefix family — the copy behind the
/// canonical banners in `shared/common/banners/`.
///
/// The MODULE has none of these: it must not know what an app calls
/// things. The commons wrappers do.
abstract final class BannerStrings {
  static String get updateTitle =>
      Tr.t('banner.update_title', S.current.banner_update_title);

  static String get updateMessage =>
      Tr.t('banner.update_message', S.current.banner_update_message);

  static String get updateAction =>
      Tr.t('banner.update_action', S.current.banner_update_action);

  static String get offlineMessage =>
      Tr.t('banner.offline_message', S.current.banner_offline_message);
}
