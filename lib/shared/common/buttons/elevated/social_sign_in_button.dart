// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../../data/services/auth/social_auth_dispatcher.dart';
import '../../../../data/services/auth/social_auth_service.dart';
import '../../../module/buttons/global_filled_button.dart';

/// Social sign-in button wired to [SocialAuthDispatcher]. Picks the
/// right label + icon per provider; feature code just reads the
/// returned [SocialAuthResult] and pattern-matches.
///
/// ```dart
/// SocialSignInButton(
///   provider: SocialAuthProvider.google,
///   onResult: (result) => switch (result) {
///     SocialAuthSuccess(:final idToken, :final provider) =>
///       authBloc.add(AuthEvent.socialSignIn(provider, idToken)),
///     SocialAuthCancelled() => null,
///     SocialAuthFailure(:final error) => GlobalToast.e(error.message),
///   },
/// );
/// ```
class SocialSignInButton extends StatefulWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onResult,
    this.label,
    this.shrinkWidth = false,
  });

  final SocialAuthProvider provider;
  final ValueChanged<SocialAuthResult> onResult;

  /// Override the default label ("Continue with Google", etc.).
  final String? label;
  final bool shrinkWidth;

  @override
  State<SocialSignInButton> createState() => _SocialSignInButtonState();
}

class _SocialSignInButtonState extends State<SocialSignInButton> {
  bool _loading = false;

  Future<void> _handle() async {
    setState(() => _loading = true);
    try {
      final result = await getIt<SocialAuthDispatcher>().signIn(
        widget.provider,
      );
      if (!mounted) return;
      widget.onResult(result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(widget.provider);
    return GlobalFilledButton(
      text: widget.label ?? SocialButtonStrings.continueWith(spec.brand),
      onPressed: _handle,
      isLoading: _loading,
      shrinkWidth: widget.shrinkWidth,
      style: ButtonStateStyle(
        backgroundColor: spec.backgroundColor,
        foregroundColor: spec.foregroundColor,
        leading: Icon(spec.icon, size: 20, color: spec.foregroundColor),
      ),
    );
  }
}

class _ProviderSpec {
  const _ProviderSpec({
    required this.brand,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  /// Untranslated brand name interpolated into
  /// [SocialButtonStrings.continueWith].
  final String brand;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
}

_ProviderSpec _specFor(SocialAuthProvider provider) {
  switch (provider) {
    case SocialAuthProvider.google:
      return const _ProviderSpec(
        brand: 'Google',
        icon: Icons.g_mobiledata,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F1F1F),
      );
    case SocialAuthProvider.facebook:
      return const _ProviderSpec(
        brand: 'Facebook',
        icon: Icons.facebook,
        backgroundColor: Color(0xFF1877F2),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.apple:
      return const _ProviderSpec(
        brand: 'Apple',
        icon: Icons.apple,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.twitter:
      return const _ProviderSpec(
        brand: 'X',
        icon: Icons.close, // placeholder — swap for FontAwesome X icon
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.github:
      return const _ProviderSpec(
        brand: 'GitHub',
        icon: Icons.code,
        backgroundColor: Color(0xFF24292E),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.microsoft:
      return const _ProviderSpec(
        brand: 'Microsoft',
        icon: Icons.window,
        backgroundColor: Color(0xFF2F2F2F),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.linkedin:
      return const _ProviderSpec(
        brand: 'LinkedIn',
        icon: Icons.business_center,
        backgroundColor: Color(0xFF0A66C2),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.discord:
      return const _ProviderSpec(
        brand: 'Discord',
        icon: Icons.forum,
        backgroundColor: Color(0xFF5865F2),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.yahoo:
      return const _ProviderSpec(
        brand: 'Yahoo',
        icon: Icons.mail,
        backgroundColor: Color(0xFF6001D2),
        foregroundColor: Colors.white,
      );
    case SocialAuthProvider.amazon:
      return const _ProviderSpec(
        brand: 'Amazon',
        icon: Icons.shopping_bag,
        backgroundColor: Color(0xFFFF9900),
        foregroundColor: Colors.black,
      );
    case SocialAuthProvider.instagram:
      return const _ProviderSpec(
        brand: 'Instagram',
        icon: Icons.camera_alt,
        backgroundColor: Color(0xFFE1306C),
        foregroundColor: Colors.white,
      );
  }
}
