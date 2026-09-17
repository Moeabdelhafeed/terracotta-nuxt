import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/workshop_apis.dart';
import '../../../data/models/terracotta/booking/booking_piece.dart';
import '../../../data/models/terracotta/workshop/workshop.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/dialog/global_dialog.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/parallax_tilt.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../delivery/widgets/delivery_details_sheet.dart';
import '../../delivery/widgets/piece_hold_warning_sheet.dart';
import '../../workshops/cubits/workshops_cubit.dart';
import '../../workshops/cubits/workshops_state.dart';
import '../../workshops/widgets/studio_location_sheet.dart';
import '../cubits/booking_detail_cubit.dart';
import '../data/booking_stage.dart';
import '../data/my_booking_sample.dart';
import '../widgets/booking_facts_grid.dart';
import '../widgets/cancel_booking_dialog.dart';
import '../widgets/handover_mark.dart';
import '../widgets/paintable_workshop_sheet.dart';
import '../widgets/piece_gallery.dart';
import '../widgets/piece_photos_sheet.dart';
import '../widgets/piece_rename_sheet.dart';
import '../widgets/piece_upload_well.dart';
import '../widgets/qr_check_in_sheet.dart';
import '../widgets/reschedule_sheet.dart';
import '../widgets/stage_stars.dart';
import 'booking_schedule_page.dart';

/// «الحجز مؤكد» / «حاضرة» / «لم تحضر» — one booking, whichever frame of
/// its life it is in.
///
/// ONE page, not nine. The design draws a frame per stage and they
/// differ only in the drawing, the two lines of copy and which buttons
/// survive — nine pages would be nine places to fix the next change.
///
/// **The stage is not the status.** Two bookings can share a wire
/// status and still be different screens; see [BookingStage].
///
/// NOT BOUND: `GET /api/bookings/{id}` is the source and nothing calls
/// it yet. [MyBookingSample] stands in, shaped like the wire — decimal
/// strings, Asia/Riyadh times printed as received — so binding this is
/// a change of source and not a rewrite.
class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({
    this.bookingId,
    this.cubit,
    this.booking,
    super.key,
  });

  /// Which booking. Null falls back to the first sample, so the route
  /// still renders when it is opened without one.
  final int? bookingId;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final BookingDetailCubit? cubit;

  /// A booking to DRAW, instead of asking for one.
  ///
  /// For the design's own frames. Several of them — «القطعة جاهزة»,
  /// «قيد التغليف», «خرجت للتوصيل», «مسلمة» — are not reachable from a
  /// booking's `status` at all: they all report `completed`, and
  /// `delivery_status` is what separates them. So the stage tests hand
  /// the frame in directly rather than inventing a row that cannot
  /// produce it. Null in the app, which asks the server.
  final MyBooking? booking;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  /// THE SERVER'S ROW. This screen read `MyBookingSample` — every
  /// frame the design draws could be looked at, and nothing on it was
  /// real: the code under the QR belonged to a fixture and «الغاء»
  /// confirmed nothing.
  late final _detail =
      widget.cubit ?? BookingDetailCubit(bookingId: '${widget.bookingId ?? 0}');

  /// The catalogue, for the workshop's HUE — a booking payload carries
  /// no `type` and no `color`, so the family cannot come from it.
  late final _catalogue = getIt<WorkshopsCubit>();

  /// Whether this page asks the server at all — a handed-in booking
  /// needs none, and asking for one it was given is a request for
  /// nothing. See [BookingDetailPage.booking].
  bool get _asks => widget.booking == null;

  /// The choice this page has just made, before the server has been
  /// re-read. `pickup`, `delivery`, or null when nothing was tapped.
  ///
  /// **An OVERRIDE, not the source.** It used to be the only thing the
  /// handover row read, starting null on every arrival — so a booking
  /// that already had delivery arranged opened showing the un-chosen
  /// state, offering a customer whose piece was on a van the choice
  /// they had already made. `delivery_method` on the booking is the
  /// truth; this only covers the moment between the tap and the
  /// reload. See [_chosenMethod].
  ///
  /// Re-choosable right up until `delivery_status` reaches
  /// `completed`, which the spec states outright — so neither choice
  /// is ever final and the other one stays on screen as a switch.
  String? _method;

  /// What the handover row should draw: this page's own tap if there
  /// has been one, otherwise what the server says.
  String? _chosenMethod(MyBooking booking) => _method ?? booking.deliveryMethod;

  /// The status this page last showed. A change to it means «ورشاتي»
  /// and the home strips are out of date — see [_refresh].
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    if (_asks && widget.cubit == null) unawaited(_refresh());
    // A PUSH ABOUT THIS BOOKING lands while it is on screen.
    //
    // This page owns its cubit, so `AccountScope` cannot reach it the
    // way it reaches the singletons — it bumps a notifier instead, and
    // this is what listens. Without it, a notification saying the
    // piece is out for delivery updated «ورشاتي» behind and left the
    // booking in front saying it was ready to collect.
    AccountScope.revision.addListener(_onOwnedChanged);
  }

  void _onOwnedChanged() {
    if (!mounted || !_asks) return;
    unawaited(_detail.load());
  }

  /// Re-read the booking, and tell the rest of the app when the answer
  /// is different.
  ///
  /// The status moves at the STUDIO — a session finished, a piece
  /// fired — so the app only ever learns about it by asking. And when
  /// it does, «ورشاتي» and the home strips are already wrong: they
  /// read one shared `getIt` list that re-asks on a language change
  /// and nothing else, so a customer who refreshed here and went back
  /// found the old status on the card, and kept finding it until the
  /// app was killed.
  ///
  /// Only on a CHANGE, so an idle pull does not re-fetch two lists.
  Future<void> _refresh() async {
    await _detail.load();
    if (!mounted) return;

    final status = _detail.state.booking?.status;
    if (status == null || status == _lastStatus) return;
    final first = _lastStatus == null;
    _lastStatus = status;
    if (!first) AccountScope.ownedChanged();
  }

  /// Whether the collection warning has already been put in front of
  /// the reader on this visit. Once per opening, not once per build.
  bool _warned = false;

  /// «القطعة جاهزة» — say how long the studio will hold it, unasked.
  ///
  /// The warning used to be a red mark in the corner of the drawing
  /// that opened a sheet when TAPPED. The deadline it is counting is
  /// the one thing on this frame the customer can lose a piece by not
  /// reading, and a mark they have to be curious about is not how you
  /// tell somebody that. So on the frame where it applies, it opens
  /// itself — and the mark stays, to open it again.
  ///
  /// Once per visit: after the first frame, so it lands on a page that
  /// is already drawn rather than over a blank one.
  void _warnOnReady(BookingStage stage, int? hoursLeft) {
    if (_warned || !stage.showsPickupDeadline || hoursLeft == null) return;
    _warned = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(showPieceHoldWarning(context, hoursLeft: hoursLeft));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;

    // The workshop's hue is the catalogue's, and its rows are
    // server-localized — so this follows a language change the same
    // way every other bound screen does.
    unawaited(_catalogue.ensureLoaded(locale));

    // AND SO IS THE BOOKING ITSELF.
    //
    // `workshop_title` is written by the server and arrives in
    // whatever `Accept-Language` asked for — it is the app bar's
    // title, and the page kept the words it was first loaded with
    // through a language change. Every ARB string on the screen
    // switched around it, which made the one server-written line look
    // like the language had half-changed.
    //
    // Only on a CHANGE: `didChangeDependencies` fires on mount too,
    // and the first load is already on its way from `initState`.
    if (_asks && _loadedLocale != null && _loadedLocale != locale) {
      unawaited(_detail.load());
    }
    _loadedLocale = locale;
  }

  /// The language the row on screen arrived in. Null until the first
  /// `didChangeDependencies`.
  String? _loadedLocale;

  @override
  void dispose() {
    AccountScope.revision.removeListener(_onOwnedChanged);
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_detail.close());
    super.dispose();
  }

  /// The pieces the server has, or none while the row is a fixture.
  List<BookingPiece> get _pieces => _detail.state.booking?.pieces ?? const [];

  /// What is left of the four-photographs-per-person allowance.
  ///
  /// CUMULATIVE, as the server counts it: uploading two now and two
  /// later is the same as four at once, and the count includes
  /// everything already on the booking. Floored at zero so a booking
  /// that somehow holds more never offers a negative.
  int get _photosLeft {
    final row = _detail.state.booking;
    if (row == null) return 0;
    const perPerson = 4;
    final left = (perPerson * row.peopleCount) - row.images.length;
    return left < 0 ? 0 : left;
  }

  /// HOW MANY PIECES THE BOOKING IS STILL SHORT.
  ///
  /// «صمم قطعتك» is booked for a number of PEOPLE and each of them
  /// walks away with something, so `expected_piece_count` is the party
  /// size; on the catalogue types it is the number of objects bought.
  /// Either way, fewer pieces than that means somebody has nothing
  /// under their name — which is what the well at the foot of the list
  /// is for.
  ///
  /// The catalogue types cannot exceed it: the server refuses a piece
  /// past what was paid for. «صمم قطعتك» reports the count as ADVICE —
  /// one potter making three pots is normal — so a booking with no
  /// count at all still gets the well, and only the catalogue types
  /// lose it once they are full.
  int get _piecesMissing {
    final row = _detail.state.booking;
    // NOTHING READ YET — the sample row on screen has no pieces on it
    // by definition, so the well is the whole of what to offer.
    if (row == null) return _pieces.isEmpty ? 1 : 0;
    if (_photosLeft <= 0) return 0;

    final expected = row.expectedPieceCount;
    if (expected == null) return row.products.isEmpty ? 1 : 0;

    final short = expected - row.pieces.length;
    return short < 0 ? 0 : short;
  }

  /// Takes one photograph off. Asks first, because there is no undo
  /// and no replace — see [PieceGallery].
  /// Answers whether the photograph actually went — the photo sheet
  /// draws its row from what it was handed, so a declined
  /// confirmation has to leave the tile where it was.
  Future<bool> _removePhoto(int imageId) async {
    final row = _detail.state.booking;
    if (row == null) return false;

    final sure = await GlobalDialog.confirm(
      context: context,
      title: BookingStrings.removePhotoTitle,
      message: BookingStrings.removePhotoBody,
      confirmText: CommonStrings.remove,
    );
    if (!sure || !mounted) return false;

    switch (await WorkshopApis.deleteBookingImage('${row.id}', '$imageId')) {
      case Success():
        if (!mounted) return false;
        GlobalToast.success(BookingStrings.photoRemoved);
        unawaited(_detail.load());
        return true;
      case Failure(:final error):
        if (!mounted) return false;
        GlobalToast.error(error.spokenMessage);
        return false;
    }
  }

  /// And a whole piece, with every photograph of it.
  Future<void> _removePiece(int pieceId) async {
    final row = _detail.state.booking;
    if (row == null) return;

    final piece = row.pieces.where((p) => p.id == pieceId).firstOrNull;
    final label = (piece?.label ?? '').trim();

    final sure = await GlobalDialog.confirm(
      context: context,
      title: BookingStrings.removePieceTitle(
        label.isEmpty ? BookingStrings.pieceUntitled : label,
      ),
      message: BookingStrings.removePieceBody,
      confirmText: CommonStrings.remove,
    );
    if (!sure || !mounted) return;

    switch (await WorkshopApis.deleteBookingPiece('${row.id}', '$pieceId')) {
      case Success():
        if (!mounted) return;
        GlobalToast.success(BookingStrings.pieceRemoved);
        unawaited(_detail.load());
      case Failure(:final error):
        if (!mounted) return;
        GlobalToast.error(error.spokenMessage);
    }
  }

  /// «أضف صوراً» — photographs of the pieces made in this session.
  ///
  /// The caps are computed HERE, from the row, because the sheet has
  /// to state them before anything is chosen: four photographs per
  /// person less what the booking already holds, and — for the
  /// catalogue types only — no more distinct names than pieces bought.
  ///
  /// SOME NOW, MORE LATER is the normal case, not an edge one: a
  /// customer photographs a cup, carries on throwing, and comes back.
  /// Both caps count what is already on the booking, so the second
  /// visit is offered exactly what the first one left.
  /// [to] opens the sheet on ONE existing piece — the `piece_ids[]`
  /// path, reached from that piece's own card. Without it the sheet
  /// asks about the people who still have no piece.
  Future<void> _addPhotos(MyBooking booking, {BookingPiece? to}) async {
    final row = _detail.state.booking;
    if (row == null) return;

    // Only the CATALOGUE types cap how many PIECES a booking may hold.
    // «صمم قطعتك» reports a count too, but as advice — the server does
    // not enforce it, and refusing a fifth piece to a potter who threw
    // five pots would be this app inventing a rule.
    final expected = row.expectedPieceCount;
    final capped = row.products.isNotEmpty && expected != null;

    await showPiecePhotosSheet(
      context,
      // SHARED with the gallery, so the "add more" button and the
      // sheet it opens can never disagree about what is left.
      photosLeft: _photosLeft,
      // COUNTED IN PIECES, not names. Two objects the customer called
      // the same thing are two pieces now, so counting distinct names
      // would let a third one through.
      piecesLeft: capped
          ? (expected - row.pieces.length).clamp(0, expected)
          : null,
      // HOW MANY NAME FIELDS STEP ONE OPENS WITH. On «صمم قطعتك»
      // this counts the people who actually CHECKED IN — a party of
      // four that arrived as two expects two — so a booking for two
      // opens two fields rather than one and an "add another" nobody
      // presses. Less what has already been photographed, since those
      // pieces are not being named again.
      // MAY BE ZERO, and that is a real answer: everyone on the
      // booking was named on an earlier visit and all that is left is
      // adding angles to the pieces that exist.
      // OPENED ON ONE PIECE: no new people to ask about, just this
      // one. Otherwise, whoever is still without a piece.
      expectedPieces: to != null
          ? 0
          : expected == null
          ? null
          : (expected - row.pieces.length).clamp(0, expected),
      existingPieces: to != null ? [to] : row.pieces,
      openOnExisting: to != null,
      // THE ROW SHOWS WHAT IS ALREADY THERE, so its remove dots have
      // to do what they say.
      onRemoveExisting: _removePhoto,
      family: booking.family,
      wireColor: booking.wireColor,
      onUpload: (drafts, {announce = false}) =>
          _uploadPhotos(row.id, drafts, announce: announce),
    );
  }

  /// «تعديل» — this piece's NAME, and nothing else.
  ///
  /// The photographs are edited on the card itself: add is a glyph on
  /// the piece, remove is a dot on the picture. What had nowhere to
  /// live was the name — a customer who typed «كوب» for both cups can
  /// now tell them apart without deleting one and photographing it
  /// again.
  ///
  /// THE SAME UNIQUENESS RULE AS NAMING IT. Matched case- and
  /// whitespace-insensitively against every OTHER piece on the
  /// booking, the piece being renamed excluded — keeping your own name
  /// is not a collision.
  Future<void> _renamePiece(MyBooking booking, BookingPiece piece) async {
    final row = _detail.state.booking;
    if (row == null) return;

    await showPieceRenameSheet(
      context,
      piece: piece,
      taken: {
        for (final other in row.pieces)
          if (other.id != piece.id)
            if ((other.label ?? '').trim().isNotEmpty)
              other.label!.trim().toLowerCase(),
      },
      family: booking.family,
      wireColor: booking.wireColor,
      onRename: (label) => _rename(row.id, piece.id, label),
    );
  }

  /// Answers null when the server took the new name, or the reason it
  /// did not — which the sheet shows under the field rather than
  /// closing on.
  Future<String?> _rename(int bookingId, int pieceId, String label) async {
    final result = await WorkshopApis.renamePiece(
      '$bookingId',
      '$pieceId',
      label: label,
    );
    if (!mounted) return null;

    switch (result) {
      case Success():
        GlobalToast.success(BookingStrings.pieceRenamed);
        // AWAITED so the card behind the sheet is already showing the
        // new name when the sheet goes.
        await _detail.load();
        return null;
      case Failure(:final error):
        return error.spokenMessage;
    }
  }

  /// Sends the photographs and the three arrays that say which object
  /// each one is of, all in step.
  Future<bool> _uploadPhotos(
    int bookingId,
    List<PieceDraft> drafts, {
    bool announce = true,
  }) async {
    // WHAT MAKES TWO PHOTOS ONE PIECE, since 2026-09-13. The server
    // used to group by matching label TEXT, so two friends who both
    // wrote «mug» ended up with one piece between them and the second
    // cup could never be brought back to paint. The sheet's own
    // grouping is sent instead — see [PieceUpload].
    final upload = PieceUpload.of(drafts);

    final result = await WorkshopApis.uploadBookingImages(
      '$bookingId',
      images: [
        for (final file in upload.files)
          await MultipartFile.fromFile(file.path),
      ],
      // ALL POSITIONAL: entry `i` belongs to file `i`.
      labels: upload.labels,
      keys: upload.keys,
      ids: upload.ids,
    );
    if (!mounted) return false;

    switch (result) {
      case Success():
        // SILENT for the background sends. The sheet uploads each
        // person as the reader leaves their page, and a toast per
        // person turned a quiet optimisation into four interruptions
        // over the screen they were still working on.
        if (announce) GlobalToast.success(BookingStrings.photosUploaded);
        // AWAITED, not fired and forgotten. The sheet closes when this
        // answers true, and closing onto a page that has not re-read
        // the booking shows the well again for as long as the request
        // takes — the photographs the reader just uploaded appear a
        // second later, which reads as the upload having failed.
        await _detail.load();
        return true;
      case Failure(:final error):
        GlobalToast.error(error.spokenMessage);
        return false;
    }
  }

  /// «تغيير الموعد» — a different day, or a different session on it.
  Future<void> _openReschedule(Color tint) async {
    final row = _detail.state.booking;
    if (row == null) return;

    await showRescheduleSheet(
      context,
      workshopId: '${row.workshopId}',
      // The party already booked: a session with fewer seats left than
      // this cannot take them, and is greyed rather than refused.
      people: row.peopleCount,
      selectedDate: row.bookingDate,
      selectedSlotId: row.workshopSlotId,
      tint: tint,
      onConfirm: (slotId, date) => unawaited(_reschedule(slotId, date)),
    );
  }

  Future<void> _reschedule(int slotId, String date) async {
    // ASKS FIRST, exactly like «الغاء» does.
    //
    // Moving a booking RELEASES the seats it was holding and takes new
    // ones — the same irreversible shape as cancelling, reached by
    // tapping a row in a list of times. «الغاء» has asked since it was
    // built; this was one tap on a slot and done.
    final sure = await GlobalDialog.confirm(
      context: context,
      title: BookingStrings.rescheduleConfirmTitle,
      message: BookingStrings.rescheduleConfirmBody,
      confirmText: BookingStrings.rescheduleConfirmYes,
      cancelText: BookingStrings.no,
      icon: Icons.event_repeat_rounded,
    );
    if (!sure || !mounted) return;

    final moved = await _detail.reschedule(
      workshopSlotId: slotId,
      bookingDate: date,
    );
    if (!mounted) return;
    if (!moved) {
      GlobalToast.error(
        _detail.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    // The strips and «ورشاتي» read the same list from a singleton that
    // only re-asks on a language change.
    AccountScope.ownedChanged();
  }

  /// «الغاء» — and the seats go back to the wallet.
  Future<void> _cancel(MyBooking booking) async {
    final sure = await showCancelBookingDialog(context);
    if (sure != true || !mounted) return;

    final done = await _detail.cancel();
    if (!mounted) return;
    if (!done) {
      GlobalToast.error(
        _detail.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    // «ورشاتي» and the live strip read the same bookings list from a
    // singleton that only re-asks on a language change — without this
    // the strip went on calling a cancelled booking confirmed.
    AccountScope.ownedChanged();
  }

  /// «لوّن الكوب» — book a paint workshop for the piece made here.
  ///
  /// The upsell, and the reason a bare cup is not the end of the
  /// story: the studio's second family exists to paint it.
  ///
  /// ## The server names the workshop
  ///
  /// `paintable_at` on the booking is the studio's own answer to
  /// "where can a piece made HERE be painted", and it is a list —
  /// there may be several. This used to take the first
  /// `paint_your_piece` out of the catalogue and hope: wrong whenever
  /// the studio runs more than one, and wrong again whenever the one
  /// it found does not accept this booking's pieces.
  ///
  /// One goes straight through; several ask. The catalogue is still
  /// consulted, but only for the details the schedule screen needs —
  /// `max_people_per_booking` and the family hue — which
  /// `paintable_at` does not carry. Missing from it, the schedule
  /// screen's own defaults stand.
  Future<void> _openPaintWorkshop(MyBooking booking) async {
    // ONLY THE ONES THAT CAN BE OPENED. See
    // `PaintableWorkshop.isReachable` — an option with no id has no
    // schedule to send anybody to, and the button is not drawn when
    // none is left.
    final options = booking.paintableOptions;
    if (options.isEmpty) return;

    final chosen = options.length == 1
        ? options.first
        : await showPaintableWorkshopSheet(context, options: options);
    final workshopId = chosen?.id;
    if (workshopId == null || !mounted) return;

    final listed = _listed(workshopId);

    context.pushNamed(
      'booking-schedule',
      pathParameters: {'workshopId': '$workshopId'},
      // The same args the workshops tab sends — the family tints every
      // screen from here to the confirmation.
      extra: BookingScheduleArgs(
        workshopId: workshopId,
        title: chosen?.title ?? listed?.title ?? '',
        // THE PARTY THAT ALREADY EXISTS IS THE FLOOR.
        //
        // `?? 1` capped the strip at one whenever the paint workshop
        // was not in the catalogue the tab had loaded — on a booking
        // made for four. The people who made the pieces are the people
        // coming back to paint them, so their number is the least this
        // can be; the calendar's own `max_available_seats` still
        // narrows it from there.
        maxPeople: listed?.maxPeoplePerBooking ?? booking.people,
        // AND THE DEFAULT, not just the ceiling. A party of two
        // photographed two pieces and is booking to paint two pieces —
        // opening on «١ شخص» asks them to re-answer a question the
        // booking already answered.
        people: booking.people,
        family: WorkshopFamily.paintYourPiece,
        // THE PAINT WORKSHOP'S OWN COLOUR, not the piece's. The flow
        // from here belongs to the workshop being booked.
        wireColor: listed?.color,
      ),
    );
  }

  /// «ستستلمها بنفسك؟» — pickup costs nothing and books no courier, so
  /// it commits quietly. The dialog is there because it also STOPS the
  /// delivery flow, and a customer who tapped the wrong one should
  /// find that out here rather than at the studio door.
  ///
  /// ## What actually comes back
  ///
  /// **`delivery_fee_wallet_applied`, never `delivery_fee`.** Choosing
  /// delivery only ever debits the WALLET slice; the remainder stays
  /// outstanding and nothing collects it. So a 50 fee against an empty
  /// wallet refunds nothing, a 50 fee against a 20 balance refunds 20,
  /// and quoting the fee would promise money that was never taken.
  /// When there is nothing to credit the sentence simply does not
  /// mention money.
  ///
  /// The number is read BEFORE the call, because the server clears
  /// `delivery_fee` and its wallet slice as part of the switch — after
  /// it answers there is nothing left to quote.
  Future<void> _choosePickup() async {
    final row = _detail.state.booking;
    final credit = row?.deliveryFeeWalletApplied;
    final refunds = credit != null && credit.isNotEmpty && credit != '0.00';

    final sure = await GlobalDialog.confirm(
      context: context,
      title: DeliveryStrings.pickupConfirmTitle,
      message: refunds
          ? DeliveryStrings.pickupConfirmBodyRefund(
              '${PriceText.format(credit)} ${HomeStrings.currency}',
            )
          : DeliveryStrings.pickupConfirmBody,
      confirmText: DeliveryStrings.pickupConfirmYes,
    );
    if (!sure || !mounted) return;

    // IT GOES TO THE SERVER. This used to set the local field and stop
    // — so a customer who chose to collect their piece had told nobody
    // but their own screen, and the studio went on preparing a
    // delivery. Through the CUBIT, which owns the booking and is the
    // seam a test drives; the answer replaces the row, because the
    // switch also clears the fee and its VAT.
    //
    // A page handed a booking rather than an id has no cubit to write
    // through — that is the design-preview path, and it keeps the old
    // local-only behaviour.
    if (row == null) {
      setState(() => _method = 'pickup');
      return;
    }

    final ok = await _detail.choosePickup();
    if (!mounted) return;

    if (!ok) {
      GlobalToast.error(
        _detail.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }

    setState(() => _method = 'pickup');
    GlobalToast.success(
      refunds
          ? DeliveryStrings.pickupCredited(
              '${PriceText.format(credit)} ${HomeStrings.currency}',
            )
          : DeliveryStrings.pickupDone,
    );
    // THE FEE CAME BACK. Switching to pickup credits whatever delivery
    // took from the wallet and drops its VAT off the booking — so the
    // balance on screen anywhere else is now wrong. The wallet is a
    // `getIt` singleton that otherwise only re-asks on a language
    // change.
    AccountScope.ownedChanged();
  }

  /// Delivery asks WHERE first: the fee comes from the address's
  /// `delivery_zone_id`, so there is nothing to quote until they say.
  Future<void> _chooseDelivery() async {
    await showDeliveryDetailsSheet(
      context,
      onConfirm: (address) {
        if (!mounted) return;
        setState(() => _method = 'delivery');
        context.pushNamed(
          'delivery-checkout',
          pathParameters: {'bookingId': '${widget.bookingId ?? 0}'},
          // The fee comes from the address's zone, so the page needs
          // the address rather than just the booking.
          extra: address,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // HANDED ONE, draw it — see [BookingDetailPage.booking].
    final given = widget.booking;
    if (given != null) return _body(context, given);
    return BlocBuilder<BookingDetailCubit, BookingDetailState>(
      bloc: _detail,
      builder: (context, state) {
        final row = state.booking;
        // The first load has nothing to draw, and a failed one has
        // nothing either — both say so rather than showing a
        // fixture, which is what this screen used to do always.
        if (row == null) {
          return Scaffold(
            backgroundColor: context.backgroundColors.scaffoldBackground,
            appBar: TerracottaPageBar(title: WorkshopStrings.tabMine),
            body: Center(
              child: state.loading
                  ? const CircularProgressIndicator.adaptive()
                  : GlobalEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: AuthStrings.errorGeneric,
                      subtitle: state.error?.message,
                      primaryAction: GlobalFilledButton(
                        text: CommonStrings.retry,
                        onPressed: () => unawaited(_detail.load()),
                        style: terracottaCtaStyle(showArrow: false),
                      ),
                    ),
            ),
          );
        }
        // THE WORKSHOP'S OWN FAMILY AND COLOUR.
        //
        // A booking payload carries neither a `type` nor a `color`, so
        // the catalogue — matched on `workshop_id` — is the only thing
        // that can answer them. Nothing was passing them at all, so
        // every booking of every workshop opened in the pottery hue:
        // the buttons, the chips, the stage drawing, the photo sheet
        // and the reschedule sheet all resolve their tint from this
        // one pair.
        final listed = _listed(row.workshopId);
        return _body(
          context,
          row.toMyBooking(
            locale: _locale,
            family: listed == null
                ? WorkshopFamily.makeYourPiece
                : WorkshopFamily.fromWire(listed.type.wire),
            wireColor: listed?.color,
          ),
        );
      },
    );
  }

  String get _locale => Localizations.localeOf(context).toString();

  /// The catalogue row for a workshop, or null when the catalogue has
  /// not landed or no longer lists it — a workshop the studio retired
  /// is still somebody's booking.
  Workshop? _listed(int workshopId) {
    final state = _catalogue.state;
    if (state is! WorkshopsLoaded) return null;
    return state.workshops.where((w) => w.id == workshopId).firstOrNull;
  }

  Widget _body(BuildContext context, MyBooking booking) {
    // A cancel or a reschedule is in flight. Read from the cubit
    // rather than passed in: this runs inside the `BlocBuilder`, so it
    // is current and the tree rebuilds when it flips.
    final working = _detail.state.working;
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: booking.family,
      isDark: context.isDarkMode,
      wireColor: booking.wireColor,
    );
    final stage = booking.stage;
    // The HANDOVER buttons ride with the facts block, above the chips
    // — see below. Only the confirmed frame's controls sit at the foot,
    // so `ready` has no bottom block at all and the facts block is what
    // ends its page.
    // THE SERVER'S VERDICT, and the stage's. A booking can be in the
    // confirmed frame and still be past its cancellation window — the
    // window is the workshop's `cancellation_window_hours` and only
    // the server knows where the clock is. See [MyBooking.canCancel].
    final canCancel = stage.canModify && booking.canCancel;
    final canEdit = stage.canModify && booking.canEdit;
    // The MAP LINK. On the view model, so it is there on the first
    // frame rather than appearing when the detail call lands — the
    // sheet used to be handed a hardcoded null.
    final locationUrl = booking.locationUrl;

    // THE COLLECTION DEADLINE, said without being asked. See
    // [_warnOnReady].
    _warnOnReady(stage, booking.pickupHoursLeft);
    final hasActions = canCancel || canEdit || stage.showsLocation;

    /// The home indicator, taken by whichever block ends the page.
    ///
    /// NOT a `SafeArea` around the body: that would inset the
    /// illustration too, and the illustration is drawn edge to edge on
    /// purpose.
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      // The bar we agreed: the workshop's own name as a marquee title,
      // with the language, bell and cart actions every secondary page
      // carries.
      appBar: TerracottaPageBar(
        title: booking.title,
        // PINNED. This page is read rather than browsed — the code to
        // show at the desk, the time, the two controls — and a bar
        // that retreats takes the workshop's name away exactly when
        // the reader has scrolled far enough to have lost track of
        // which booking they are looking at.
        pinned: true,
      ),
      body: LayoutBuilder(
        builder: (context, viewport) => GlobalRefreshable(
          // BOUND. It was `() async {}` — the gesture was wired for a
          // binding that then landed everywhere else, so the one
          // screen whose status the STUDIO changes under you was the
          // one where pulling did nothing. A piece moving from «قيد
          // التحضير» to «جاهزة» happens at the studio, not in this
          // app, so re-asking is the only way to see it.
          onRefresh: () async {
            // AND WHO THEY ARE. A booking page carries the wallet
            // amount that was applied and the number the studio will
            // call — see [AccountRefresh].
            await Future.wait([_refresh(), AccountRefresh.user(context)]);
          },
          // NO `edgeOffset`. The gallery needs one because its bar
          // floats over the body; this Scaffold has a REAL app bar,
          // so the body already begins below it — adding the toolbar
          // height again dropped the spinner 56 points down the page.
          child: GlobalScrollable(
            // ALWAYS draggable, even when the content fits.
            //
            // Flutter drops the drag recogniser outright when
            // `minScrollExtent == maxScrollExtent`, so a page that fits
            // does not scroll AND never overscrolls — which is exactly
            // what a `RefreshIndicator` listens for. This page is built
            // to fit: it stretches its own sections to the viewport.
            physics: const AlwaysScrollableScrollPhysics(),
            // Fills the screen and SPREADS, rather than stacking against
            // the top with a field of empty under it. Still a scrollable,
            // so a long frame — or a large type scale — is reachable.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The drawing carries the news before the words do —
                    // a broken pot reads as "you missed it" across the
                    // room. EDGE TO EDGE: its line is a horizon, and a
                    // horizon with a margin either side is a picture of
                    // one.
                    Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: spacing.xl),
                          // «مسلمة» heads its page with a MARK rather
                          // than a drawing — the end of the story is a
                          // fact, not a thing, and the same frame has
                          // to serve the customer who collected as well
                          // as the one who was delivered to.
                          // IT LEANS WITH THE PHONE.
                          //
                          // A line drawing on a flat panel is the one
                          // thing on this page with nothing behind it,
                          // and eight points of travel put it in a
                          // shallow space instead of on the glass. Off
                          // under reduced motion and on any device
                          // with no accelerometer — see [ParallaxTilt].
                          //
                          // NOT on «مسلمة»: that frame is a MARK, and
                          // a tick that drifts reads as a tick that is
                          // not quite landing.
                          child: stage.showsSuccessMark
                              ? HandoverMark(
                                  startArt: stage.illustration,
                                  endArt: stage.endIllustration!,
                                  size: stage.illustrationHeight,
                                )
                              : SizedBox(
                                  // PER STAGE, not one box for all of
                                  // them. The calendar is a wide flat
                                  // loop and the potter at her wheel is
                                  // a figure — given the calendar's
                                  // height the figure came out half the
                                  // size and the page looked like it
                                  // had lost its picture.
                                  height: stage.illustrationHeight,
                                  width: double.infinity,
                                  child: ParallaxTilt(
                                    depth: ParallaxDepth.hero,
                                    child: GlobalImage.a(
                                      // The drawing is the family's:
                                      // «حاضرة» shows the customer
                                      // doing the thing they came for,
                                      // which is a different picture
                                      // in each of the three
                                      // workshops.
                                      stage.illustrationFor(booking.family),
                                      placeholder: const SizedBox.shrink(),
                                      style: const ImageStyle(
                                        // COVER, not `fitHeight`.
                                        //
                                        // `fitHeight` fills the box's
                                        // HEIGHT and lets the width
                                        // fall where the drawing's
                                        // aspect puts it — so whether
                                        // the horizon reached the
                                        // screen edges depended on the
                                        // phone. It did on a narrow
                                        // one and stopped short on a
                                        // wide one, which is not a
                                        // choice anybody made.
                                        //
                                        // `cover` fills BOTH, cropping
                                        // whichever axis has spare.
                                        // The line is a horizon and a
                                        // horizon with a margin either
                                        // side is a picture of one.
                                        fit: BoxFit.cover,
                                        // No radius on a line drawing
                                        // — the house 8pt would eat
                                        // its own edges.
                                        borderRadius: BorderRadius.zero,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // The deadline, in the drawing's TOP-END corner.
                        //
                        // Not in the app bar — that already carries
                        // three actions, and a red mark beside the bell
                        // reads as an unread notification rather than
                        // as a piece about to be given up. And not in
                        // the heading block either: there it pushed the
                        // title off centre. Up here it is the first
                        // thing the eye meets after the drawing, and it
                        // owns its corner.
                        // GATED ON THE FRAME, not on the field alone.
                        // The server keeps sending `pickup_deadline`
                        // after the piece has left — see
                        // [BookingStage.showsPickupDeadline].
                        if (stage.showsPickupDeadline)
                          if (booking.pickupHoursLeft case final hours?)
                            PositionedDirectional(
                              top: spacing.sm,
                              end: spacing.md,
                              child: _HoldWarningButton(hoursLeft: hours),
                            ),
                      ],
                    ),
                    StageStars(
                      leadHigh: stage.starsLeadHigh,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: spacing.md),
                        child: Column(
                          children: [
                            Text(
                              stage.heading,
                              textAlign: TextAlign.center,
                              style: context.textTheme.titleLarge?.copyWith(
                                color: context.textColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              stage.bodyFor(
                                booking.family,
                                booking.hoursAway,
                                readyIn: booking.readyHoursLeft,
                              ),
                              textAlign: TextAlign.center,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.textColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ONE block with the facts. The photograph well and
                    // the chips are the same thing — what this booking IS
                    // — so the page's spacing must spread AROUND the pair
                    // and never between them.
                    Padding(
                      // The home indicator, but only when nothing
                      // follows this block.
                      padding: EdgeInsets.only(
                        bottom: hasActions ? 0 : safeBottom,
                      ),
                      child: _Gutter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (stage.showsHandover) ...[
                              // ABOVE the chips, as drawn. On a piece
                              // that is READY the question is how it
                              // leaves; the facts underneath are
                              // reference. That is the reverse of every
                              // other frame, where the facts come first
                              // and the buttons answer them.
                              _HandoverChoice(
                                method: _chosenMethod(booking),
                                tint: fam.primary,
                                // The upsell is «صناعة كوبك»'s alone —
                                // a piece that has just been painted
                                // has nowhere further to go — AND the
                                // server has to name somewhere for it
                                // to go. `paintable_at` is empty until
                                // the booking is marked completed,
                                // which means fired, so the button
                                // cannot appear the moment a session
                                // ends.
                                showPaint:
                                    stage.showsPaintUpsellFor(
                                      booking.family,
                                    ) &&
                                    booking.paintableOptions.isNotEmpty,
                                onPickup: () => unawaited(_choosePickup()),
                                onDelivery: () => unawaited(_chooseDelivery()),
                                onPaint: () =>
                                    unawaited(_openPaintWorkshop(booking)),
                              ),
                              SizedBox(height: spacing.md),
                            ],
                            // WHAT HAS BEEN PHOTOGRAPHED, once there
                            // is anything. After that the reader wants
                            // to SEE the pictures: whether the one they
                            // just took came out, whether every piece
                            // is covered.
                            //
                            // The pieces stay on screen after the
                            // session ends; only the controls go, and
                            // `stage.showsUpload` is what says which.
                            if (_pieces.isNotEmpty) ...[
                              PieceGallery(
                                pieces: _pieces,
                                canEdit: stage.showsUpload,
                                photosLeft: _photosLeft,
                                family: booking.family,
                                wireColor: booking.wireColor,
                                // ANOTHER ANGLE ON ONE PIECE, opened
                                // straight onto that piece rather than
                                // on a page asking for a new person.
                                onAddTo: (piece) =>
                                    unawaited(_addPhotos(booking, to: piece)),
                                // ITS NAME, on its own.
                                onRename: (piece) =>
                                    unawaited(_renamePiece(booking, piece)),
                                onRemovePhoto: (pieceId, imageId) =>
                                    unawaited(_removePhoto(imageId)),
                                onRemovePiece: (pieceId) =>
                                    unawaited(_removePiece(pieceId)),
                              ),
                              SizedBox(height: spacing.sm),
                            ],
                            // A LABEL WITH NOBODY UNDER IT.
                            //
                            // There is no «قطعك» heading and no "add
                            // more" button beside it any more — one
                            // button above four cards could not say
                            // WHICH piece it was about, and adding to
                            // a piece belongs on the piece. What it
                            // was also doing, badly, was the only way
                            // to start a piece that does not exist:
                            // a party of two where one person has been
                            // photographed, or a piece deleted whole
                            // and now missing.
                            //
                            // So the same well that greets an empty
                            // booking comes back at the END of the
                            // list whenever the booking is short of
                            // pieces. It is the shape a reader already
                            // knows means "nothing here yet", said
                            // about one missing label rather than
                            // about the whole booking.
                            if (stage.showsUpload && _piecesMissing > 0) ...[
                              PieceUploadWell(
                                family: booking.family,
                                wireColor: booking.wireColor,
                                // A FIRST STEP, or a GAP. «ارفع صورة
                                // قطعتك» reads as the former, which is
                                // the wrong thing to say to somebody
                                // who has already photographed three
                                // people and is one short.
                                text: _pieces.isEmpty
                                    ? null
                                    : BookingStrings.uploadRemaining,
                                // A NAME PER PHOTOGRAPH, and both
                                // caps — the well took one unnamed
                                // picture and uploaded nothing. See
                                // [PiecePhotosSheet].
                                onAdd: () => unawaited(_addPhotos(booking)),
                              ),
                              SizedBox(height: spacing.sm),
                            ],
                            BookingFactsGrid(
                              price: booking.price,
                              people: BookingStrings.forPeople(
                                BookingStrings.party(booking.people),
                              ),
                              date: booking.date,
                              time: booking.time,
                              hasCelebration: booking.hasCelebration,
                              family: booking.family,
                              wireColor: booking.wireColor,
                              onScan: stage.showsQr
                                  ? () => showQrCheckInSheet(
                                      context,
                                      // Without this the sheet drew an
                                      // empty line where the code goes.
                                      code: booking.checkinCode,
                                      panelColor: fam.panel,
                                      tint: fam.primary,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ONE block, so the spacing above spreads between the
                    // page's sections and not between two halves of the
                    // same set of buttons.
                    if (hasActions)
                      Padding(
                        padding: EdgeInsets.only(bottom: safeBottom),
                        child: _Gutter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (canCancel || canEdit) ...[
                                // CANCEL first, so in Arabic it lands on the
                                // right where the design puts it. The two
                                // mirror together in English.
                                Row(
                                  children: [
                                    if (canCancel)
                                      Expanded(
                                        child: GlobalFilledButton(
                                          text: BookingStrings.cancel,
                                          // ONE PRESS, and it says so.
                                          // Both of these call the
                                          // server; without a sign the
                                          // tap landed the reader
                                          // pressed again.
                                          isLoading: working,
                                          enabled: !working,
                                          style:
                                              terracottaCtaStyle(
                                                showArrow: false,
                                              ).copyWith(
                                                backgroundColor:
                                                    context.statusColors.error,
                                              ),
                                          // ASKS, then does it. The
                                          // dialog used to confirm
                                          // nothing at all.
                                          onPressed: () =>
                                              unawaited(_cancel(booking)),
                                        ),
                                      ),
                                    if (canCancel && canEdit)
                                      SizedBox(width: spacing.sm),
                                    if (canEdit)
                                      Expanded(
                                        child: GlobalFilledButton(
                                          text: BookingStrings.reschedule,
                                          isLoading: working,
                                          enabled: !working,
                                          // SOLID, not a 25% wash.
                                          //
                                          // Amber at a quarter alpha
                                          // with amber text on it is
                                          // what every disabled button
                                          // in the app looks like —
                                          // pale fill, pale label — so
                                          // «تعديل» read as something
                                          // the page had switched off,
                                          // beside a cancel button in
                                          // full red. It is amber
                                          // because it is the
                                          // secondary of the pair, not
                                          // because it is unavailable.
                                          style:
                                              terracottaCtaStyle(
                                                showArrow: false,
                                              ).copyWith(
                                                backgroundColor: context
                                                    .statusColors
                                                    .warning,
                                                // WHITE, like every
                                                // other filled button
                                                // in the app. It
                                                // measured the fill
                                                // and picked the
                                                // readable ink, which
                                                // put near-black on
                                                // this one button and
                                                // white on the red
                                                // beside it — a pair
                                                // that reads as a
                                                // rendering fault.
                                                //
                                                // White on the amber
                                                // is 3.1:1, under AA,
                                                // and it is the
                                                // design's own pair —
                                                // see
                                                // `docs/contrast-report.md`.
                                                foregroundColor: Colors.white,
                                              ),
                                          // REAL availability, and the
                                          // choice is SENT. The sheet
                                          // picked from a fixture and
                                          // threw the answer away.
                                          onPressed: () => unawaited(
                                            _openReschedule(fam.primary),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: spacing.sm),
                              ],
                              // ONLY WHEN THERE IS ONE. The sheet's
                              // empty state is an honest answer to
                              // "where is it?" but a button that only
                              // ever opens an apology is not a button.
                              // `location_url` is null on a workshop
                              // the CMS has not given a map link.
                              if (stage.showsLocation && locationUrl != null)
                                GlobalFilledButton(
                                  text: WorkshopStrings.location,
                                  icon: Icons.location_on_rounded,
                                  style: terracottaCtaStyle(showArrow: false),
                                  // It was an empty callback — the one
                                  // button on this page a customer
                                  // presses on the morning of a
                                  // workshop, and it did nothing.
                                  onPressed: () => unawaited(
                                    showStudioLocationSheet(
                                      context,
                                      // THE BOOKING'S OWN. It used to
                                      // be hardcoded null — the row
                                      // carries `location_url` and
                                      // this screen is bound to it
                                      // now, so the one button a
                                      // customer presses on the
                                      // morning of a workshop opens
                                      // the right place.
                                      locationUrl: locationUrl,
                                      tint: fam.panel,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's side margin.
///
/// Applied per BLOCK rather than to the whole column, because the
/// illustration at the head runs edge to edge — its line is a horizon,
/// and a horizon with a margin either side is a picture of one.
class _Gutter extends StatelessWidget {
  const _Gutter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
    child: child,
  );
}

/// «تحذير» — the studio will not hold the piece forever.
///
/// A mark beside the heading rather than an action in the bar: the bar
/// already carries three, and a red dot next to a bell reads as an
/// unread notification. Here it sits with the news it belongs to, one
/// block above the choice whose window it is counting down.
class _HoldWarningButton extends StatelessWidget {
  const _HoldWarningButton({required this.hoursLeft});

  final int hoursLeft;

  @override
  Widget build(BuildContext context) {
    // The ERROR ramp, not the amber pair. An overdue pickup means
    // losing the piece, which is error-severity — the amber belongs to
    // the reschedule button, a neutral secondary action.
    final error = context.statusColors.error;

    return Semantics(
      button: true,
      label: DeliveryStrings.warningTitle,
      child: InkResponse(
        onTap: () => showPieceHoldWarning(context, hoursLeft: hoursLeft),
        radius: 34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: error.withValues(alpha: 0.14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.error_rounded,
              // Beside TWO lines rather than one, so it can
              // carry the weight — at the small ramp it read
              // as a footnote on a block it is the headline of.
              size: context.iconSizes.xl,
              color: error,
            ),
          ),
        ),
      ),
    );
  }
}

/// How the finished piece leaves — and the fact that the customer can
/// change their mind.
///
/// **Both choices stay reachable.** The spec is explicit: the method is
/// re-choosable right up until `delivery_status` reaches `completed`.
/// So once one is picked the OTHER takes the third button's place,
/// worded as a switch rather than as a fresh choice, and «لوني الكوب»
/// steps aside — a piece already on its way somewhere is not also
/// going back to be painted.
class _HandoverChoice extends StatelessWidget {
  const _HandoverChoice({
    required this.method,
    required this.tint,
    required this.showPaint,
    required this.onPickup,
    required this.onDelivery,
    required this.onPaint,
  });

  /// `pickup`, `delivery`, or null before they have said.
  final String? method;

  final Color tint;

  /// Whether the third button is drawn at all. See
  /// `BookingStage.showsPaintUpsellFor`.
  final bool showPaint;

  final VoidCallback onPickup;
  final VoidCallback onDelivery;
  final VoidCallback onPaint;

  /// `delivery_method` on the wire is `pickup` / `delivery` — NOT the
  /// `delivery_status` vocabulary. This compared against
  /// `awaiting_pickup`, which is a value `delivery_method` never
  /// holds, so a booking read back from the server could never match
  /// the pickup branch.
  bool get _pickingUp => method == 'pickup';
  bool get _beingDelivered => method == 'delivery';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // NOTHING CHOSEN yet: the two ways out, side by side, and the
    // upsell under them.
    if (!_pickingUp && !_beingDelivered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GlobalFilledButton(
                  text: DeliveryStrings.pickup,
                  style: terracottaCtaStyle(
                    showArrow: false,
                  ).copyWith(backgroundColor: tint),
                  onPressed: onPickup,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: GlobalFilledButton(
                  text: DeliveryStrings.deliver,
                  style: terracottaCtaStyle(showArrow: false).copyWith(
                    backgroundColor: context.primaryColors.primary,
                  ),
                  onPressed: onDelivery,
                ),
              ),
            ],
          ),
          // The upsell, and the reason a bare cup is not the end of
          // the story: the studio's second family exists to paint it.
          if (showPaint) ...[
            SizedBox(height: spacing.sm),
            GlobalFilledButton(
              text: DeliveryStrings.paintIt,
              style: terracottaCtaStyle(
                showArrow: false,
              ).copyWith(backgroundColor: context.primaryColors.accent),
              onPressed: onPaint,
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChosenBanner(
          text: _pickingUp
              ? DeliveryStrings.chosePickup
              : DeliveryStrings.choseDelivery,
          icon: _pickingUp
              ? Icons.storefront_rounded
              : Icons.local_shipping_rounded,
          tint: tint,
        ),
        SizedBox(height: spacing.sm),
        // The OTHER way, in the third button's place.
        GlobalOutlinedButton(
          text: _pickingUp
              ? DeliveryStrings.switchToDelivery
              : DeliveryStrings.switchToPickup,
          icon: Icons.swap_horiz_rounded,
          onPressed: _pickingUp ? onDelivery : onPickup,
        ),
      ],
    );
  }
}

/// «ستستلم قطعتك من المشغل» — what was chosen, stated.
class _ChosenBanner extends StatelessWidget {
  const _ChosenBanner({
    required this.text,
    required this.icon,
    required this.tint,
  });

  final String text;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: tint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(context.radii.md),
    ),
    child: Padding(
      padding: EdgeInsets.all(context.spacing.sm),
      child: Row(
        children: [
          Icon(icon, size: context.iconSizes.sm, color: tint),
          SizedBox(width: context.spacing.xs),
          Expanded(
            child: Text(
              text,
              style: context.textTheme.bodySmall?.copyWith(
                color: tint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
