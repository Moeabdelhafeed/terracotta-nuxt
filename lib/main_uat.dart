// Project imports:
import 'bootstrap.dart';
import 'core/flavor/flavor.dart';

/// Entrypoint for the **uat** flavor (client sandbox / acceptance testing).
///
/// Run with:
///   flutter run -t lib/main_uat.dart --flavor uat
void main() => bootstrap(Flavor.uat);
