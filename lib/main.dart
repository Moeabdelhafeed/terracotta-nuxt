// Project imports:
import 'main_dev.dart' as dev_entrypoint;

/// Default entrypoint — aliases the **dev** flavor so `flutter run`
/// without `-t` and IDE "play" buttons launch the dev build.
///
/// All real builds should target a flavor-specific entrypoint:
///   • lib/main_dev.dart
///   • lib/main_staging.dart
///   • lib/main_uat.dart
///   • lib/main_prod.dart
void main() => dev_entrypoint.main();
