// Project imports:
import 'bootstrap.dart';
import 'core/flavor/flavor.dart';

/// Entrypoint for the **prod** flavor.
///
/// Run with:
///   flutter run -t lib/main_prod.dart --flavor prod --release
void main() => bootstrap(Flavor.prod);
