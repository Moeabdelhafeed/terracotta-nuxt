import 'package:flutter/widgets.dart';

/// Ties this build to the app's LANGUAGE.
///
/// A `Strings` value is read at BUILD time — `GalleryStrings.title` is
/// a getter over `S.current`, not a listenable — so a widget that
/// prints one has to rebuild when the language changes, or it keeps
/// showing the words it read the first time.
///
/// Depending on the `Localizations` scope is what makes that happen,
/// and it is needed even though a parent rebuilds. `const` is exactly
/// the case that breaks: when a parent rebuilds with an identical const
/// child, `Element.updateChild` sees `child.widget == newWidget` and
/// REUSES the element without rebuilding it. The child's `build` never
/// runs again, so nothing re-reads the string. An inherited dependency
/// is the one thing that still marks it dirty.
///
/// It bit the gallery and the workshops headers, whose artwork mirrored
/// correctly on a language switch — `IllustratedHeader` reads
/// `Directionality`, so IT rebuilt — while the heading above it stayed
/// in the old language, because the const wrapper that had read the
/// heading never rebuilt at all.
void dependOnLanguage(BuildContext context) => Localizations.localeOf(context);
