import 'package:timeago/timeago.dart' as timeago;

import '../utils/loggers/logger.dart';

/// Factory for a timeago [timeago.LookupMessages] instance. Kept as a
/// factory (not a live instance) so we don't allocate every message
/// bundle for locales the app never uses.
typedef _MessagesFactory = timeago.LookupMessages Function();

/// Registry of timeago message classes keyed by locale code. Add an
/// entry here when your app picks up a new language — no other code
/// has to change; [registerTimeagoLocales] will find it automatically.
///
/// The `timeago` package ships 30+ locales; this covers the common
/// ones. Extend as needed.
const Map<String, _MessagesFactory> _kMessages = <String, _MessagesFactory>{
  'en': timeago.EnMessages.new,
  'en_short': timeago.EnShortMessages.new,
  'ar': timeago.ArMessages.new,
  'ar_short': timeago.ArShortMessages.new,
  'de': timeago.DeMessages.new,
  'de_short': timeago.DeShortMessages.new,
  'es': timeago.EsMessages.new,
  'es_short': timeago.EsShortMessages.new,
  'fa': timeago.FaMessages.new,
  'fr': timeago.FrMessages.new,
  'fr_short': timeago.FrShortMessages.new,
  'he': timeago.HeMessages.new,
  'id': timeago.IdMessages.new,
  'it': timeago.ItMessages.new,
  'ja': timeago.JaMessages.new,
  'ko': timeago.KoMessages.new,
  'nl': timeago.NlMessages.new,
  'pl': timeago.PlMessages.new,
  'pt_br': timeago.PtBrMessages.new,
  'pt_br_short': timeago.PtBrShortMessages.new,
  'ru': timeago.RuMessages.new,
  'ru_short': timeago.RuShortMessages.new,
  'sv': timeago.SvMessages.new,
  'tr': timeago.TrMessages.new,
  'uk': timeago.UkMessages.new,
  'vi': timeago.ViMessages.new,
  'zh': timeago.ZhMessages.new,
  'zh_cn': timeago.ZhCnMessages.new,
};

/// Register timeago messages for every locale in [locales] that the
/// registry knows. Unknown locales fall through to English — the
/// built-in default that `timeago` always has loaded — and log a
/// warning so you notice the gap.
///
/// Also registers `'en'` unconditionally as the safety net in case
/// [locales] doesn't include it.
///
/// ```dart
/// // main.dart
/// registerTimeagoLocales(
///   getIt<LanguagesService>().languages.map((l) => l.locale),
/// );
/// ```
void registerTimeagoLocales(Iterable<String> locales) {
  // Always have English as the fallback locale. `timeago` already
  // bakes it in, but re-registering is cheap and documents intent.
  timeago.setLocaleMessages('en', timeago.EnMessages());

  for (final code in locales) {
    if (code == 'en') continue;
    final factory = _kMessages[code];
    if (factory == null) {
      Logger.m.w(
        '[timeago] No messages registered for locale "$code" — '
        'relative-time labels will render in English. Add the '
        'mapping in timeago_locales.dart if your app supports it.',
      );
      continue;
    }
    timeago.setLocaleMessages(code, factory());
  }
}
