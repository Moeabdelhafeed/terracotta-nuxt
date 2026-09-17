import '../../../shared/module/scanner/global_scanner.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalScanner].
///
/// The app-wide rebrand hook: the viewfinder's corner follows the same
/// token every other surface in the app rounds by, so a scanner does
/// not arrive with a corner nothing else has.
///
/// The accent is deliberately NOT set — it resolves from
/// `context.primaryColors` at build time so it tracks role, brightness
/// and saturation, which a constant in here cannot. Neither are the
/// control colours: those sit on camera pixels rather than on the
/// app's surfaces.
class MyGlobalScannerTheme {
  MyGlobalScannerTheme._();

  static GlobalScannerTheme build({required AppTokens tokens}) =>
      GlobalScannerTheme(
        style: ScannerStyle(cornerRadius: tokens.radii.md),
      );
}
