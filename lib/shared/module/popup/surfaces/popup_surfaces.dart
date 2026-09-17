/// Barrel for all popup surface widgets (base + menu + panel + tooltip).
library;

export 'menu.dart';
export 'panel.dart';
export 'surface_base.dart';

// `tooltip.dart` used to live here — a second tooltip with its own
// surface styling, beside `module/tooltip/`. GlobalTooltip renders
// through this engine now, so there is one.
