import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../data/blocs/auth/auth_bloc.dart';
import '../../../data/blocs/auth/auth_state.dart';
import '../../../shared/module/marquee/global_marquee.dart';

/// «مساء الخير, نور» — the signed-in customer's own name.
///
/// Read from the session `POST /api/login` returned rather than fetched
/// again: `AuthBloc` already holds the account, and a second call to
/// learn a name the app was just handed would be a request for nothing.
///
/// A GUEST has no name, and the greeting is written to work without
/// one — browsing is public here, so an empty greeting is a normal
/// state and not a missing value. Rebuilt through a selector so the
/// greeting is the only thing that repaints when the session changes.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AuthBloc, AuthState, String>(
        selector: (state) => switch (state) {
          // The FIRST name only. The server keeps one `name` field and a
          // greeting that reads back someone's full name sounds like a
          // form, not a welcome.
          AuthAuthenticated(:final user) => user.firstName ?? '',
          _ => '',
        },
        builder: (context, name) {
          final greeting = HomeStrings.greeting(name);
          // MARQUEE, because this one is not a fixed string: it is
          // «مساء الخير» plus whatever the customer is called, in a bar
          // that also holds three actions. `GlobalMarquee` only moves
          // when the content actually overflows, so a short name costs
          // nothing and a long one is still readable rather than
          // clipped.
          return GlobalMarquee(
            semanticLabel: greeting,
            child: Text(
              greeting,
              maxLines: 1,
              softWrap: false,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.textColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      );
}
