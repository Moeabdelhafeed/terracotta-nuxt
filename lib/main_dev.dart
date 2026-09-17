// Project imports:
import 'bootstrap.dart';
import 'core/flavor/flavor.dart';

/// Entrypoint for the **dev** flavor.
///
/// Run with:
///   flutter run -t lib/main_dev.dart --flavor dev
void main() => bootstrap(Flavor.dev);
