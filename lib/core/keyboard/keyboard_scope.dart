import 'package:flutter/widgets.dart';

import 'keyboard_observer.dart';

/// Installs ONE [KeyboardObserver] for the subtree under it.
///
/// Wired once in `MyApp`'s builder, so anything in the app can ask
/// where the keyboard is without attaching its own observer — and
/// without a global mutable singleton, which is what the old
/// `KeyboardUtils` was.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => GlobalKeyboardScope(child: child!),
/// );
///
/// // anywhere below:
/// final keyboard = GlobalKeyboardScope.maybeOf(context);
/// ```
///
/// Without a scope a widget still resizes correctly off `MediaQuery`;
/// the scope upgrades that to a phase-accurate signal that survives a
/// `Scaffold` consuming the inset.
class GlobalKeyboardScope extends StatefulWidget {
  const GlobalKeyboardScope({super.key, required this.child});

  final Widget child;

  /// The nearest observer, or null when nothing installed one.
  static KeyboardObserver? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_KeyboardScopeMarker>()
      ?.observer;

  @override
  State<GlobalKeyboardScope> createState() => _GlobalKeyboardScopeState();
}

class _GlobalKeyboardScopeState extends State<GlobalKeyboardScope> {
  late final KeyboardObserver _observer;

  @override
  void initState() {
    super.initState();
    _observer = KeyboardObserver()..attach();
  }

  @override
  void dispose() {
    _observer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _KeyboardScopeMarker(observer: _observer, child: widget.child);
}

class _KeyboardScopeMarker extends InheritedWidget {
  const _KeyboardScopeMarker({required this.observer, required super.child});

  final KeyboardObserver observer;

  @override
  bool updateShouldNotify(_KeyboardScopeMarker old) => observer != old.observer;
}
