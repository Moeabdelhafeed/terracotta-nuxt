import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/responsive_value.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/device/info/screen_radius.dart';
import '../buttons/global_text_button.dart';
import '../icon/global_icon.dart';
import '../text/global_text.dart';
import 'sheet_geometry.dart';
import 'sheet_models.dart';

export 'sheet_models.dart';
export 'theme/sheet_theme.dart';

part 'sheet_bottom.dart';
part 'sheet_combined.dart';
part 'sheet_top.dart';
part 'sheet_widgets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kPad = 20.0;
const _kDismissThreshold = 80.0;
const _kDismissVelocity = 500.0;
const _kBorderHideExtra = 4.0; // extra pixels to push border below screen edge

/// Resolves border radius: explicit > device radius > fallback.
BorderRadius _resolveRadius(ResolvedSheetStyle rs, bool floating, bool isTop) =>
    SheetGeometry.outerRadius(rs, floating: floating, isTop: isTop);

/// Converts a [SheetCrossAlign] to a `-1..1` factor for use in
/// [AlignmentDirectional]. `start → -1`, `center → 0`, `end → 1`.
double _crossAlignFactor(SheetCrossAlign? align) {
  switch (align ?? SheetCrossAlign.center) {
    case SheetCrossAlign.start:
      return -1;
    case SheetCrossAlign.center:
      return 0;
    case SheetCrossAlign.end:
      return 1;
  }
}

/// Maps [SheetCrossAlign] onto [MainAxisAlignment]. Used when the
/// alignment is applied via a [Row] / [Column] wrapper instead of
/// an [Align] widget.
MainAxisAlignment _crossAlignMainAxis(SheetCrossAlign? align) {
  switch (align ?? SheetCrossAlign.center) {
    case SheetCrossAlign.start:
      return MainAxisAlignment.start;
    case SheetCrossAlign.center:
      return MainAxisAlignment.center;
    case SheetCrossAlign.end:
      return MainAxisAlignment.end;
  }
}

/// True iff [sizing] specifies any horizontal-axis constraint or
/// alignment. Bottom / top sheets use this to decide whether to wrap
/// the rendered sheet in a sizing helper.
bool _hasHorizontalSizing(SheetSizing? sizing) {
  if (sizing == null) return false;
  return sizing.width != null ||
      sizing.maxWidth != null ||
      sizing.adaptiveWidth ||
      sizing.horizontalAlignment != null;
}

/// Wraps [sheet] in width-axis sizing + horizontal alignment for
/// bottom-edge or top-edge sheets. `crossAxis` controls vertical
/// pinning inside the wrapping [Row]: `end` for bottom sheets,
/// `start` for top sheets so the sheet hugs its anchored edge.
Widget _wrapHorizontalSizing(
  Widget sheet, {
  required SheetSizing? sizing,
  required CrossAxisAlignment crossAxis,
}) {
  if (!_hasHorizontalSizing(sizing)) return sheet;
  var sized = sheet;
  if (sizing!.width != null) {
    sized = SizedBox(width: sizing.width, child: sized);
  } else if (sizing.adaptiveWidth) {
    sized = IntrinsicWidth(child: sized);
    if (sizing.maxWidth != null) {
      sized = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: sizing.maxWidth!),
        child: sized,
      );
    }
  } else if (sizing.maxWidth != null) {
    sized = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: sizing.maxWidth!),
      child: sized,
    );
  }
  return Row(
    mainAxisAlignment: _crossAlignMainAxis(sizing.horizontalAlignment),
    crossAxisAlignment: crossAxis,
    children: [Flexible(child: sized)],
  );
}
