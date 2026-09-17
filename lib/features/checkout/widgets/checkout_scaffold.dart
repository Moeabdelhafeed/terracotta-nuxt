import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/app_bar/global_app_bar.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/shared_hero.dart';

/// «الدفع» — the chrome all four payable flows share.
///
/// Booking, shop, delivery and gift all quote into the SAME envelope,
/// which is exactly why one checkout screen can serve them. The only
/// differences are what sits above the breakdown and what the CTA says.
class CheckoutScaffold extends StatelessWidget {
  const CheckoutScaffold({
    required this.ctaLabel,
    required this.children,
    this.onSubmit,
    this.enabled = true,
    this.busy = false,
    super.key,
  });

  final String ctaLabel;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final bool enabled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: GlobalAppBar(
        variant: AppBarVariant.transparent,
        // The same chevron the rest of the app flies. Checkout is a
        // run of pushed pages, so this is where holding it still says
        // the most: the page changes and the way back does not.
        wrapBack: (back) => SharedHero(
          tag: HeroTag.back,
          entranceDriftFrom: const Offset(-3.5, 0),
          // And OUT the same way, at the speed of the pop.
          exitsWithRoute: true,
          child: back,
        ),
      ),
      body: GlobalScrollable(
        child: GlobalContainer.shell(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            0,
            spacing.md,
            spacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                CheckoutStrings.title,
                style: context.textTheme.titleLarge?.copyWith(
                  color: context.textColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: spacing.lg),
              ...children,
              SizedBox(height: spacing.xl),
              GlobalFilledButton(
                text: ctaLabel,
                icon: Icons.arrow_forward_rounded,
                enabled: enabled,
                isLoading: busy,
                onPressed: onSubmit ?? () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
