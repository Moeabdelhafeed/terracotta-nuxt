import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../shared/module/scaffold/global_scaffold.dart';
import '../../gallery/views/gallery_albums_page.dart';
import '../../home/views/home_page.dart';
import '../../profile/views/profile_page.dart';
import '../../shop/views/shop_home_page.dart';
import '../../workshops/views/workshops_page.dart';

/// The five-tab shell.
///
/// Order is READING order — right to left in Arabic, which is the app's
/// primary locale. `GlobalScaffold` mirrors the bar itself from
/// `Directionality`, so the list below is written in logical order
/// (first = the tab the reader meets first) and needs no RTL special
/// casing.
///
/// The fourth destination is the SHOP, not the cart. The design draws a
/// cart glyph there, but the destination behind it is متجر تيراكوتا —
/// confirmed by the highlighted tab on the `shop 1` frame. The real
/// cart is a bottom sheet opened from the shop landing
/// (`features/cart/widgets/cart_sheet.dart`).
///
/// ICONS: the design's glyphs come from 20 different Iconify
/// collections and ship as SVG in `assets/icons/`. `GlobalDestination`
/// takes an `IconData`, so these are the closest Material stand-ins
/// until the bar is given an SVG slot. The four to swap are:
/// `streamline-plump:gallery-2-remix`, `heroicons:paint-brush-16-solid`,
/// `boxicons:cart-filled` and `iconamoon:profile-fill`.
class AppShell extends StatefulWidget {
  const AppShell({this.initialIndex = 0, super.key});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  /// Kept parallel to [_destinations] — tapping a tab also updates the
  /// URL so a deep link, a share and the back button all agree.
  static const _paths = <String>[
    '/home',
    '/gallery',
    '/workshops',
    '/shop',
    '/profile',
  ];

  static const _destinations = <GlobalDestination>[
    GlobalDestination(icon: Icons.home_rounded, label: 'الرئيسية'),
    GlobalDestination(icon: Icons.photo_library_rounded, label: 'المعرض'),
    GlobalDestination(icon: Icons.brush_rounded, label: 'الورشات'),
    GlobalDestination(icon: Icons.storefront_rounded, label: 'المتجر'),
    GlobalDestination(icon: Icons.person_rounded, label: 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) => GlobalScaffold(
    destinations: _destinations,
    selectedIndex: _index,
    onDestinationSelected: (i) {
      setState(() => _index = i);
      context.go(_paths[i]);
    },
    bodyBuilders: [
      (_) => const HomePage(),
      (_) => const GalleryAlbumsPage(),
      (_) => const WorkshopsPage(),
      (_) => const ShopHomePage(),
      (_) => const ProfilePage(),
    ],
  );
}

/// The tab index that owns a given location, or null when the location
/// is not a shell destination. Used by the router to keep the selected
/// tab in step with a deep link.
int? shellIndexForLocation(String location) {
  final i = _AppShellState._paths.indexWhere(
    (p) => location == p || location.startsWith('$p/'),
  );
  return i < 0 ? null : i;
}

/// Guards against the shell and the route table drifting apart.
@visibleForTesting
List<String> debugShellPaths() => _AppShellState._paths;

/// The routes the shell's tabs point at, so a test can assert every one
/// of them actually exists in [AppRoutes].
@visibleForTesting
List<String> debugShellRouteNames() => const [
  'home',
  'gallery',
  'workshops',
  'shop',
  'profile',
];
