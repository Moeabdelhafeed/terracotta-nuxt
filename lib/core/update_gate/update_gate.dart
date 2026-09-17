import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../shared/module/update_gate/update_screen.dart';
import '../../shared/module/update_gate/update_soft_prompt.dart';
import 'update_cubit.dart';
import 'update_options.dart';
import 'update_state.dart';

/// Wraps the app and decides whether to render the hard fullscreen
/// update screen, a soft banner, a soft sheet, or pass through to
/// [child].
///
/// Decision matrix:
/// | Requirement       | softMode | UI                         |
/// |-------------------|----------|----------------------------|
/// | required          | any      | Hard fullscreen            |
/// | available, soft   | none     | Pass-through               |
/// | available, soft   | banner   | Banner over [child]        |
/// | available, soft   | sheet    | Pass-through; sheet shown  |
/// |                   |          | once per session           |
/// | upToDate / unknown| any      | Pass-through               |
class UpdateGate extends StatefulWidget {
  const UpdateGate({
    required this.child,
    this.options,
    super.key,
  });

  final Widget child;

  /// Optional override for [UpdateCubit.options]. When passed, the
  /// cubit's internal options are updated to match. Lets callers
  /// configure once at mount-time.
  final UpdateOptions? options;

  @override
  State<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<UpdateGate> {
  bool _sheetShownThisSession = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UpdateCubit, UpdateState>(
      listener: (context, state) {
        final cubit = context.read<UpdateCubit>();
        final opts = cubit.options;
        if (widget.options != null) cubit.updateOptions(widget.options!);

        if (!opts.enabled) return;
        if (cubit.withinBootGrace) return;
        if (state.requirement != UpdateRequirement.available) return;
        if (opts.softMode != SoftUpdateMode.sheet) return;
        if (state.isSoftSuppressed) return;
        if (_sheetShownThisSession) return;

        _sheetShownThisSession = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          UpdateSoftSheet.show(context, state);
        });
      },
      builder: (context, state) {
        final cubit = context.read<UpdateCubit>();
        if (widget.options != null) cubit.updateOptions(widget.options!);
        final opts = cubit.options;

        // Hard required → fullscreen, no pass-through.
        if (opts.enabled && !cubit.withinBootGrace && state.isHardRequired) {
          return UpdateScreen(state: state);
        }

        // Soft available + banner mode → strip over child.
        final showBanner =
            opts.enabled &&
            !cubit.withinBootGrace &&
            opts.softMode == SoftUpdateMode.banner &&
            state.isSoftAvailable &&
            !state.isSoftSuppressed;

        if (!showBanner) return widget.child;

        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: UpdateSoftBanner(state: state),
            ),
          ],
        );
      },
    );
  }
}
