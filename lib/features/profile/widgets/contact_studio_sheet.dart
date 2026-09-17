import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/device/system/launcher_utils.dart';
import '../../../data/models/terracotta/core/link_item.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../booking/widgets/sheet_shell.dart';
import '../cubits/app_settings_cubit.dart';

/// «تواصل معنا» — the studio's own channels.
///
/// ## Where the rows come from
///
/// `GET /api/app-settings`, which the app had never called: `contact`
/// (WhatsApp, email) and `social` (Instagram, TikTok) were sitting on
/// the server unread, so «تواصل معنا» in «حسابي» opened the COMPLAINTS
/// screen — the only contact route the app had — and a customer who
/// simply wanted to message the studio had to file a formal complaint
/// against an order to do it.
///
/// Every row carries its own ICON from the CMS, so a channel the
/// studio adds tomorrow arrives drawn.
///
/// The rows open EXTERNALLY. `wa.me`, `mailto:` and an Instagram
/// profile are all somebody else's app, and a webview would be a worse
/// version of each.
class ContactStudioSheet extends StatefulWidget {
  const ContactStudioSheet({this.cubit, super.key});

  /// The seam a test needs — the sheet loads on mount.
  final AppSettingsCubit? cubit;

  @override
  State<ContactStudioSheet> createState() => _ContactStudioSheetState();
}

class _ContactStudioSheetState extends State<ContactStudioSheet> {
  late final _settings = widget.cubit ?? getIt<AppSettingsCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Every row's `text` is the server's — «تواصل عبر واتساب» against
    // «WhatsApp» — so the language it was read in matters.
    unawaited(
      _settings.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  // NOT CLOSED. It is a `getIt` singleton: the sheet can be opened
  // from more than one place and none of them owns it.

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppSettingsCubit, AppSettingsState>(
        bloc: _settings,
        builder: (context, state) {
          final contact = state.settings?.contact ?? const <LinkItem>[];
          final social = state.settings?.social ?? const <LinkItem>[];
          final spacing = context.spacing;

          return SheetShell(
            title: ProfileStrings.contactUs,
            centerTitle: true,
            // Sized to what it holds: a handful of rows does not need
            // most of the screen.
            heightFactor: null,
            maxHeightFactor: 0.8,
            children: [
              if (state.loading && state.settings == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                )
              else if (contact.isEmpty && social.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: spacing.lg),
                  child: Text(
                    ProfileStrings.contactEmpty,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                )
              else ...[
                Text(
                  ProfileStrings.contactBody,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
                SizedBox(height: spacing.lg),

                // THE WAYS TO REACH THEM, as full-width rows.
                //
                // These are the point of the sheet — a customer opens
                // it to message the studio — so they get the width, a
                // chevron and their own name.
                for (final link in contact) ...[
                  _ContactRow(link: link),
                  SizedBox(height: spacing.sm),
                ],

                // AND WHERE TO FOLLOW THEM, as a rail of round icons.
                //
                // Following is browsing, not contacting. Drawn as
                // equal rows it read as four equally likely errands
                // and made the sheet twice as long; as a strip of
                // marks under a quiet heading it is there for whoever
                // wants it and out of the way of whoever does not.
                if (social.isNotEmpty) ...[
                  SizedBox(height: spacing.sm),
                  Text(
                    ProfileStrings.contactSocial,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing.md,
                    runSpacing: spacing.sm,
                    children: [
                      for (final link in social) _SocialMark(link: link),
                    ],
                  ),
                ],
              ],
              SizedBox(height: spacing.lg),
            ],
          );
        },
      );
}

/// A way to REACH the studio — WhatsApp, email. Full width, because
/// this is the errand the sheet exists for.
class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.link});

  final LinkItem link;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      onTap: () => unawaited(LauncherUtils.openUrl(link.url)),
      padding: EdgeInsets.all(spacing.sm),
      child: Row(
        children: [
          // The CMS's own mark, on a tint of the brand so a flat PNG
          // with no background does not float on the card.
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.primaryColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.xs),
              child: SizedBox.square(
                dimension: 26,
                child: TerracottaImage(image: link.image),
              ),
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              // The studio's own word for it, already localized.
              link.text,
              style: context.textTheme.bodyLarge?.copyWith(
                color: context.textColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Forward, not "open in new": every one of these leaves the
          // app, and the arrow Flutter mirrors is the one the rest of
          // the account list uses.
          Icon(
            Icons.arrow_forward_rounded,
            size: context.iconSizes.sm,
            color: context.iconColors.primary,
          ),
        ],
      ),
    );
  }
}

/// One place to FOLLOW the studio — a round mark with its name under
/// it, in a strip.
class _SocialMark extends StatelessWidget {
  const _SocialMark({required this.link});

  final LinkItem link;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Semantics(
      button: true,
      label: link.text,
      child: InkWell(
        onTap: () => unawaited(LauncherUtils.openUrl(link.url)),
        borderRadius: BorderRadius.circular(context.radii.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.backgroundColors.container,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.sm),
                  child: SizedBox.square(
                    dimension: 26,
                    child: TerracottaImage(image: link.image),
                  ),
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                link.text,
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [ContactStudioSheet].
Future<void> showContactStudioSheet(BuildContext context) =>
    showTerracottaSheet<void>(
      context,
      builder: (_) => const ContactStudioSheet(),
    );
