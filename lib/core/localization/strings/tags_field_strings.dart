import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `tags_field_` key prefix (tags input field) — call sites
/// resolve these through this class instead of `S.current` directly.
class TagsFieldStrings {
  TagsFieldStrings._();

  static String get hint => Tr.t('tags_field.hint', S.current.tags_field_hint);
  static String min(int count) =>
      Tr.t('tags_field.min', S.current.tags_field_min(count));
  static String tooLong(int max) =>
      Tr.t('tags_field.too_long', S.current.tags_field_too_long(max));
  static String maxReached(int max) =>
      Tr.t('tags_field.max_reached', S.current.tags_field_max_reached(max));
  static String get notAllowed =>
      Tr.t('tags_field.not_allowed', S.current.tags_field_not_allowed);
}
