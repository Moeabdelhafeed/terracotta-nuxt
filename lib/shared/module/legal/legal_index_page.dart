import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/legal/legal_page.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/legal_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/services/remote_config_service.dart';
import '../app_bar/global_app_bar.dart';
import '../container/global_container.dart';
import '../icon/global_icon.dart';
import '../scrollable/global_scrollable.dart';
import '../text/global_text.dart';
import '../toast/global_toast.dart';
import 'legal_style.dart';
import 'theme/legal_theme.dart';

/// "About" hub. Lists every enabled [LegalPage] (per Remote Config),
/// app version, and a tile to Flutter's built-in Open-source Licenses
/// page.
///
/// One column at every width — the list is a handful of rows, and
/// `GlobalContainer.shell` already clamps it to a reading measure.
/// (The doc used to promise a `GlobalGrid` split on tablets. There
/// was never one in the build.)
class LegalIndexPage extends StatefulWidget {
  const LegalIndexPage({this.style = const LegalStyle(), super.key});

  /// How the page LOOKS. Themeable through `GlobalLegalTheme`.
  final LegalStyle style;

  @override
  State<LegalIndexPage> createState() => _LegalIndexPageState();
}

class _LegalIndexPageState extends State<LegalIndexPage> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((i) {
      if (!mounted) return;
      setState(() => _info = i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = LegalPage.values
        .where((p) => RemoteConfigService.legalEnabled(p.slug))
        .toList(growable: false);

    // ONE resolve per build, handed down.
    final style = widget.style.resolve(context);
    return Scaffold(
      // LOCALIZED. It was the literal 'About' — on the page whose own
      // list is entirely localized titles.
      appBar: GlobalAppBar(title: LegalStrings.titleAbout),
      body: SafeArea(
        // See the feedback form: the list scrolls UNDER the gesture
        // bar and ends clear of it, rather than the viewport being
        // shortened and a dead strip left underneath.
        bottom: false,
        child: GlobalContainer.shell(
          child: GlobalScrollable(
            padding: EdgeInsets.only(
              // The shell clamps the WIDTH; it does not hold the
              // content off the screen edge, so on a phone every card
              // ran corner to corner.
              left: style.pagePadding,
              right: style.pagePadding,
              top: style.labelGap,
              bottom: style.labelGap + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AppHeader(info: _info, style: style),
                SizedBox(height: style.sectionGap),
                _SectionLabel(text: LegalStrings.sectionLabel),
                SizedBox(height: style.labelGap),
                for (int i = 0; i < enabled.length; i++) ...[
                  if (i > 0) SizedBox(height: style.tileGap),
                  _LegalTile(page: enabled[i], style: style, info: _info),
                ],
                SizedBox(height: style.sectionGap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// App header — logo placeholder + name + version
// ─────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.info, required this.style});

  final PackageInfo? info;
  final ResolvedLegalStyle style;

  Future<void> _copy(
    BuildContext context,
    String name,
    String version,
    String build,
  ) async {
    // The RAW numbers, not the localized ones: this is going into a
    // support ticket, where Arabic-Indic digits would be unreadable
    // to whoever receives it.
    final line = build.isEmpty ? '$name $version' : '$name $version ($build)';
    await Clipboard.setData(ClipboardData(text: line));
    GlobalToast.s(CommonStrings.copiedToClipboard);
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final bg = context.backgroundColors;
    final name = info?.appName ?? '';
    final version = info?.version ?? '—';
    final build = info?.buildNumber ?? '';
    // TAPPABLE, and it copies. "What version are you on?" is the
    // first thing support asks, and the answer was on screen but not
    // in the reader's clipboard — so they retyped it, or guessed.
    return GlobalContainer(
      onTap: () => _copy(context, name, version, build),
      semanticLabel: '$name. ${LegalStrings.version(version, build)}',
      style: ContainerStyle(
        padding: style.headerPadding,
        backgroundColor: bg.cardBackground,
        borderColor: bg.outlineVariant,
        borderRadius: BorderRadius.circular(style.headerRadius),
      ),
      child: Row(
        children: [
          // The adopter's own mark when they have set one. The default
          // is unmistakably a PLACEHOLDER — right for a template,
          // wrong for a shipped app, and now replaceable once from the
          // theme instead of by editing this file.
          style.markBuilder?.call(context) ??
              Container(
                width: style.markSize,
                height: style.markSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      btn.primary,
                      btn.primary.withValues(alpha: style.markFadeOpacity),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(style.markRadius),
                ),
                child: Icon(
                  Icons.flutter_dash_rounded,
                  size: style.markGlyphSize,
                  color: tx.onPrimary,
                ),
              ),
          SizedBox(width: style.labelGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlobalText(
                  name,
                  // The app's OWN name — its direction follows the
                  // name, not the reader's locale.
                  autoDetectDirection: true,
                  preset: TextPreset.titleLarge,
                  textStyle: GlobalTextStyle(
                    color: tx.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: GlobalText(
                        LegalStrings.version(version, build),
                        preset: TextPreset.bodySmall,
                        textStyle: GlobalTextStyle(color: tx.secondary),
                      ),
                    ),
                    SizedBox(width: context.spacing.xs),
                    // A hint, not a control: the whole card is the
                    // target, so a second tappable inside it would be
                    // a second node saying the same thing.
                    Icon(
                      Icons.copy_rounded,
                      size: context.iconSizes.xs,
                      color: tx.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    return Semantics(
      // A heading, so a reader can jump to the list rather than
      // walking every tile above it.
      header: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
        child: GlobalText(
          text.toUpperCase(),
          preset: TextPreset.labelSmall,
          textStyle: GlobalTextStyle(
            color: tx.secondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tile — one card per legal page
// ─────────────────────────────────────────────────────────────

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.page,
    required this.style,
    required this.info,
  });

  final LegalPage page;
  final ResolvedLegalStyle style;
  final PackageInfo? info;

  void _open(BuildContext context) {
    if (page == LegalPage.licenses) {
      showLicensePage(
        context: context,
        // The app's REAL name and version. It was the literal 'App',
        // so Flutter's own licence page — the one screen here nobody
        // wrote — introduced itself as "App".
        applicationName: info?.appName ?? '',
        applicationVersion: info?.version,
      );
      return;
    }
    context.push('/legal/${page.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final bg = context.backgroundColors;
    // `GlobalContainer`, not a `Material` + `InkWell` + `Container`
    // stack drawing its own fill, ripple, border and corner — the
    // container module does all four, and a tappable one is already
    // one button node to a screen reader.
    return GlobalContainer(
      onTap: () => _open(context),
      semanticLabel: page.title,
      style: ContainerStyle(
        padding: EdgeInsets.all(style.labelGap + 4),
        backgroundColor: bg.cardBackground,
        borderColor: bg.outlineVariant,
        borderRadius: BorderRadius.circular(style.tileRadius),
        shadow: const [],
      ),
      child: Row(
        children: [
          GlobalIcon(
            icon: page.icon,
            style: IconStyle(
              size: context.iconSizes.md,
              color: btn.primary,
              containerSize: style.markSize * 0.625,
              containerShape: IconContainerShape.rounded,
              borderRadius: BorderRadius.circular(style.tileRadius - 4),
              backgroundColor: btn.primary,
              backgroundOpacity: 0.12,
            ),
          ),
          SizedBox(width: style.labelGap),
          Expanded(
            child: GlobalText(
              page.title,
              // Document titles are authored content — direction
              // follows the text, not the app locale.
              autoDetectDirection: true,
              preset: TextPreset.bodyLarge,
              textStyle: GlobalTextStyle(
                fontWeight: FontWeight.w600,
                color: tx.primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tx.secondary),
        ],
      ),
    );
  }
}
