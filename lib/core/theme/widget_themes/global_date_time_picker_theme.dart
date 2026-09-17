import '../../../shared/module/date_time_picker/date_time_picker.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the `date_time_picker/` family.
///
/// The app-wide rebrand hook. Everything set here is a SIZE that a
/// token already answers, so the pickers round, pad and space like the
/// rest of the app and follow it into a wider window — the module's own
/// floor is fixed numbers, which cannot.
///
/// No colours: they resolve from `context.primaryColors` /
/// `textColors` / `backgroundColors` at build time, so they track role,
/// brightness and saturation. A constant in here could not.
class MyGlobalDateTimePickerTheme {
  MyGlobalDateTimePickerTheme._();

  static GlobalDateTimePickerTheme build({required AppTokens tokens}) =>
      GlobalDateTimePickerTheme(
        style: DateTimePickerStyle(
          radius: tokens.radii.lg,
          triggerRadius: tokens.radii.md,
          triggerGap: tokens.spacing.sm,
          overlayRadius: tokens.radii.lg,
          overlayGap: tokens.spacing.sm,
          gridCellRadius: tokens.radii.md,
          // The day cell's corner is the range bar's end cap, so it
          // wants to be generous — `lg` is what the bar was drawn with
          // by hand before the bag existed.
          dayRadius: tokens.radii.lg,
          wheelSeparatorGap: tokens.spacing.sm,
          headerPadding: tokens.spacing.sm,
        ),
      );
}
