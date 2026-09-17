import 'package:flutter/widgets.dart';

import '../../../shared/module/sheet/global_sheet.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for the sheet module (bottom / top /
/// combined / responsive surfaces).
///
/// Colors are intentionally left null — they resolve at build time from
/// `context.<group>Colors` (role + saturation aware). Per-call `style:`
/// overrides win.
class MyGlobalSheetTheme {
  MyGlobalSheetTheme._();

  static GlobalSheetTheme build({required AppTokens tokens}) {
    return const GlobalSheetTheme(
      // Scalar defaults live in SheetStyle.defaults — this factory is
      // the app-wide rebrand hook, and the corner is the one thing
      // Terracotta wants different.
      style: SheetStyle(
        // A FIXED 20, not the device's own screen corner.
        //
        // The module defaults to `useDeviceRadius`, which curves a
        // sheet to match the phone's housing — right for a sheet that
        // sits flush to the bottom edge on hardware whose corner is
        // 40-plus. On this app it made every sheet a different shape on
        // every handset, and none of them the shape the design draws.
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        useDeviceRadius: false,
      ),
    );
  }
}
