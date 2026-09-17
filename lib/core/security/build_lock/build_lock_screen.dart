// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import '../../flavor/flavor.dart';
import '../../flavor/flavor_config.dart';
import 'build_lock_gate.dart';

/// Password gate shown for staging / uat builds. Self-contained — uses
/// raw Material widgets so it renders even when other app systems
/// (router, theming, services) haven't initialized.
///
/// On successful unlock, calls [onUnlock]. After [maxAttempts] wrong
/// passwords in a row, the form is locked for [lockoutSeconds].
class BuildLockScreen extends StatefulWidget {
  const BuildLockScreen({
    required this.gate,
    required this.onUnlock,
    this.maxAttempts = 5,
    this.lockoutSeconds = 30,
    super.key,
  });

  final BuildLockGate gate;
  final VoidCallback onUnlock;
  final int maxAttempts;
  final int lockoutSeconds;

  @override
  State<BuildLockScreen> createState() => _BuildLockScreenState();
}

class _BuildLockScreenState extends State<BuildLockScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _busy = false;
  bool _showError = false;
  int _failedAttempts = 0;
  int _lockoutRemaining = 0;
  Timer? _lockoutTimer;

  bool get _isLocked => _lockoutRemaining > 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _isLocked) return;
    final password = _controller.text;
    if (password.isEmpty) return;

    setState(() {
      _busy = true;
      _showError = false;
    });

    final result = await widget.gate.tryUnlock(password);
    if (!mounted) return;

    if (result == UnlockResult.unlocked) {
      widget.onUnlock();
      return;
    }

    setState(() {
      _busy = false;
      _showError = true;
      _failedAttempts++;
      _controller.clear();
      if (_failedAttempts >= widget.maxAttempts) {
        _startLockout();
      }
    });
  }

  void _startLockout() {
    _lockoutRemaining = widget.lockoutSeconds;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining--;
        if (_lockoutRemaining <= 0) {
          timer.cancel();
          _failedAttempts = 0;
        }
      });
    });
  }

  Future<void> _onLogoLongPress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset build lock?'),
        content: const Text(
          'Clears the saved unlock token. You will need to enter the '
          'password again on next launch. For dev convenience only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await widget.gate.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flavor = FlavorConfig.instance.flavor;
    final size = MediaQuery.sizeOf(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: flavor.bannerColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: size.width.clamp(0, 480)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onLongPress: _onLogoLongPress,
                      child: _FlavorBadge(flavor: flavor),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Restricted build',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the build password to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      enabled: !_isLocked && !_busy,
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => _submit(),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'\s')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        errorText: _showError ? 'Incorrect password' : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLocked || _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      // Raw CircularProgressIndicator by DESIGN — this
                      // is `core`, which must not import shared/module,
                      // and the lock screen runs before the app's theme
                      // is anything but a fallback anyway.
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Unlock'),
                    ),
                    const SizedBox(height: 16),
                    _FooterLine(
                      isLocked: _isLocked,
                      lockoutRemaining: _lockoutRemaining,
                      failedAttempts: _failedAttempts,
                      maxAttempts: widget.maxAttempts,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlavorBadge extends StatelessWidget {
  const _FlavorBadge({required this.flavor});

  final Flavor flavor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: flavor.bannerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        flavor.displayName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _FooterLine extends StatelessWidget {
  const _FooterLine({
    required this.isLocked,
    required this.lockoutRemaining,
    required this.failedAttempts,
    required this.maxAttempts,
  });

  final bool isLocked;
  final int lockoutRemaining;
  final int failedAttempts;
  final int maxAttempts;

  @override
  Widget build(BuildContext context) {
    String text;
    if (isLocked) {
      text = 'Too many attempts. Try again in $lockoutRemaining s.';
    } else if (failedAttempts > 0) {
      final remaining = maxAttempts - failedAttempts;
      text = '$remaining attempt${remaining == 1 ? '' : 's'} remaining';
    } else {
      text = 'Long-press the badge to reset the saved unlock.';
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: Colors.white54),
    );
  }
}
