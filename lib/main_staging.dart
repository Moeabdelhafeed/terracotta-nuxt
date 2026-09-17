// Project imports:
import 'bootstrap.dart';
import 'core/flavor/flavor.dart';

/// Entrypoint for the **staging** flavor.
///
/// Run with:
///   flutter run -t lib/main_staging.dart --flavor staging
void main() => bootstrap(Flavor.staging);
