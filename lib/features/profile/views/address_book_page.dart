import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/address_strings.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/address_summary.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/addresses_cubit.dart';
import '../cubits/addresses_state.dart';
import 'address_form_page.dart';

/// «عناويني» — the saved addresses.
///
/// Checkout passes `address_id` rather than asking for a map pin each
/// time, so this screen is where one comes from.
///
/// The address is STRUCTURED, not a free-text line: building number,
/// street, district, postal code, additional number, an optional unit,
/// and the optional eight-character short national address. The CITY is
/// `delivery_zone_id`, not text — and it is the city that carries the
/// delivery fee.
class AddressBookPage extends StatefulWidget {
  const AddressBookPage({this.cubit, super.key});

  /// Injectable, so a test can render the page without a network. The
  /// page CLOSES only the one it made itself.
  final AddressesCubit? cubit;

  @override
  State<AddressBookPage> createState() => _AddressBookPageState();
}

class _AddressBookPageState extends State<AddressBookPage> {
  late final _addresses = widget.cubit ?? AddressesCubit();

  @override
  void initState() {
    super.initState();
    // Only the page's OWN cubit is loaded here — an injected one
    // arrives already holding whatever it should show.
    if (widget.cubit == null) unawaited(_addresses.load());
  }

  @override
  void dispose() {
    if (widget.cubit == null) unawaited(_addresses.close());
    super.dispose();
  }

  Future<void> _openForm({Address? existing}) async {
    final saved = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          zones: _addresses.state.zones,
          existing: existing,
          // THE FIRST ONE IS THE DEFAULT and there is nothing to ask.
          isFirst: _addresses.state.addresses.isEmpty,
        ),
      ),
    );
    // Put it straight into the list rather than re-asking the server:
    // the response IS the saved address.
    if (saved != null) _addresses.remember(saved);
  }

  Future<void> _confirmDelete(Address address) async {
    final sure = await GlobalDialog.confirm(
      context: context,
      title: AddressStrings.deleteTitle,
      message: AddressStrings.deleteBody,
      confirmText: AddressStrings.delete,
      isDestructive: true,
    );
    if (!sure) return;

    if (await _addresses.remove(address)) {
      GlobalToast.success(AddressStrings.deleted);
    } else {
      GlobalToast.error(AuthStrings.errorGeneric);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(title: ProfileStrings.addresses),
      // PINNED to the foot, not trailing the list. «اضف عنوان» is the
      // one thing this screen is for — a customer with six addresses
      // had to scroll past all of them to reach it, and the empty
      // state pushed it into the middle of a blank page.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: GlobalFilledButton(
            text: AddressStrings.add,
            icon: Icons.add_rounded,
            style: terracottaCtaStyle(showArrow: false),
            onPressed: () => unawaited(_openForm()),
          ),
        ),
      ),
      body: BlocBuilder<AddressesCubit, AddressesState>(
        bloc: _addresses,
        builder: (context, state) => LayoutBuilder(
          builder: (context, viewport) => GlobalRefreshable(
            onRefresh: () async {
              // AND WHO THEY ARE. A pull on a page about the customer
              // is a person asking whether the app is still right about
              // them — see [AccountRefresh].
              await Future.wait([
                AccountRefresh.user(context),
                _addresses.load(),
              ]);
            },
            child: GlobalScrollable(
              // The page that most needs pulling to refresh is the empty
              // one, and a page shorter than the viewport drops the drag
              // recogniser unless the CALLER asks for these physics.
              physics: const AlwaysScrollableScrollPhysics(),
              child: GlobalContainer.shell(
                padding: EdgeInsetsDirectional.fromSTEB(
                  spacing.md,
                  spacing.md,
                  spacing.md,
                  spacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // STAGGERED as the page settles — the rows arrive one after
                  // another rather than the whole block appearing at once.
                  children: ScreenEntrance.stage([
                    if (state.isEmpty)
                      // CENTRED in the viewport, not stacked at the top
                      // of an empty page. A lone "no addresses" line
                      // under the app bar with a screen of white beneath
                      // it reads as a page that failed to load.
                      SizedBox(
                        height: viewport.maxHeight - spacing.md * 2,
                        child: Center(
                          child: GlobalEmptyState(
                            title: ProfileStrings.noAddresses,
                            icon: Icons.location_off_rounded,
                            variant: EmptyStateVariant.compact,
                          ),
                        ),
                      )
                    else
                      for (final address in state.addresses) ...[
                        _AddressCard(
                          address: address,
                          busy: state.busyIds.contains(address.id),
                          onEdit: () => unawaited(_openForm(existing: address)),
                          onDelete: () => unawaited(_confirmDelete(address)),
                          onMakeDefault: () =>
                              unawaited(_addresses.makeDefault(address)),
                        ),
                        SizedBox(height: spacing.sm),
                      ],
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One saved address.
///
/// **Built from the PARTS, not from `address_line`.** The server
/// composes that line as «2342, test, Unit 233, test, Riyadh, 12423,
/// 2342» — four bare numbers in a row that nobody can tell apart, and
/// the district repeated as prose. The pieces are all on the model, so
/// the card leads with the street, then labels each number for what it
/// is.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
  });

  final Address address;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final label = address.label;

    return TerracottaCard(
      onTap: busy ? null : onEdit,
      child: Opacity(
        opacity: busy ? 0.5 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The place itself, in the ONE shape the app draws a
            // place in — the order detail's delivery section wears it
            // too. See [AddressSummary].
            AddressSummary(
              // «عنوان بدون اسم» rather than nothing: in a LIST every
              // card needs a name to be told apart by.
              title: label == null || label.isEmpty
                  ? AddressStrings.unnamed
                  : label,
              // The STREET leads: it is the part a person actually
              // reads to recognise where this is.
              line: '${address.street} · ${address.district}',
              isHome: address.isDefault,
              trailing: address.isDefault ? const _DefaultChip() : null,
              facts: [
                AddressFact(
                  AddressStrings.buildingShort(address.buildingNumber),
                ),
                if (address.unitNumber case final unit? when unit.isNotEmpty)
                  AddressFact(AddressStrings.unitShort(unit)),
                AddressFact(AddressStrings.postalShort(address.postalCode)),
                AddressFact(
                  address.deliveryZone,
                  icon: Icons.local_shipping_rounded,
                ),
              ],
              phone: address.phone,
              notes: address.notes,
            ),
            Divider(
              height: spacing.md * 2,
              color: context.textColors.primary.withValues(alpha: 0.08),
            ),
            Row(
              children: [
                if (!address.isDefault)
                  _Action(
                    icon: Icons.star_outline_rounded,
                    label: AddressStrings.makeDefault,
                    onTap: busy ? null : onMakeDefault,
                  ),
                const Spacer(),
                // No EDIT button: the whole card opens the form, and
                // three actions overflowed a 390-point row by 144.
                _Action(
                  icon: Icons.delete_outline_rounded,
                  label: AddressStrings.delete,
                  destructive: true,
                  onTap: busy ? null : onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultChip extends StatelessWidget {
  const _DefaultChip();

  @override
  Widget build(BuildContext context) {
    final ink = context.statusColors.success;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(context.radii.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          AddressStrings.isDefault,
          style: context.textTheme.labelSmall?.copyWith(
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ink = destructive
        ? context.statusColors.error
        : context.primaryColors.primary;

    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: context.iconSizes.sm, color: ink),
      label: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(color: ink),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
