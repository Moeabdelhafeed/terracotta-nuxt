import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/booking/booking_piece.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/media_picker/index.dart';
import '../../../shared/module/text_field/global_text_field.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/vessel_indicator.dart';
import 'sheet_shell.dart';

/// One OBJECT the customer made, and the photographs of it.
///
/// This is the unit the sheet is built out of, and the change is the
/// whole point of `piece_keys[]`: a draft is a physical thing, not a
/// picture of one. Two cups both called «mug» are two drafts and stay
/// two pieces, which the old photo-first sheet could not express — it
/// grouped by matching label text, so the second cup vanished into the
/// first and could never be brought back to paint.
@immutable
class PieceDraft {
  const PieceDraft({
    this.label = '',
    this.files = const <File>[],
    this.existing,
  });

  /// What the customer calls it. Free text, and deliberately NOT what
  /// decides anything.
  final String label;

  final List<File> files;

  /// The piece this draft adds another angle to, when it is one the
  /// booking already holds. Null for a new object.
  ///
  /// Sent as `piece_ids[]`, which is the only way to reach a piece
  /// from an EARLIER call — a key is an identifier within one request
  /// and the server does not keep it.
  final BookingPiece? existing;

  bool get isExisting => existing != null;

  /// The name that goes on the wire: the customer's for a new piece,
  /// the one already recorded for an existing one.
  String get wireLabel =>
      isExisting ? (existing!.label ?? '').trim() : label.trim();

  PieceDraft copyWith({String? label, List<File>? files}) => PieceDraft(
    label: label ?? this.label,
    files: files ?? this.files,
    existing: existing,
  );
}

/// The three parallel arrays the upload takes, built from the drafts.
///
/// One entry per FILE, in the same order as [files], because that is
/// how the server pairs them. [keys] are positional (`p1`, `p2`) and
/// mean nothing outside the one request: the server reads them to
/// decide which photographs are one object and then forgets them.
/// [ids] carries the existing piece for a draft that has one, and null
/// everywhere else — where the server falls back to that photo's key.
@immutable
class PieceUpload {
  const PieceUpload({
    required this.files,
    required this.labels,
    required this.keys,
    required this.ids,
  });

  factory PieceUpload.of(List<PieceDraft> drafts) {
    final files = <File>[];
    final labels = <String>[];
    final keys = <String>[];
    final ids = <String?>[];

    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      for (final file in draft.files) {
        files.add(file);
        labels.add(draft.wireLabel);
        keys.add('p${i + 1}');
        ids.add(draft.existing?.id.toString());
      }
    }

    return PieceUpload(files: files, labels: labels, keys: keys, ids: ids);
  }

  final List<File> files;
  final List<String> labels;
  final List<String> keys;
  final List<String?> ids;
}

/// «أضف صوراً» — photographs of the pieces made in this session.
///
/// ## One card per OBJECT, not per photograph
///
/// The sheet used to be a picker and a name field under each picture,
/// and the server grouped the photographs by matching that text. Two
/// friends who both wrote «mug» ended up with one piece between them
/// and the second object was gone for good — it could never be booked
/// into a paint workshop, because a piece is what `own_pieces` lists
/// and there was only one.
///
/// Since 2026-09-13 `piece_keys[]` decides instead, and this sheet is
/// shaped like the thing it is describing: the customer adds a piece,
/// names it, and photographs it from as many angles as they like.
/// Names stop deciding anything, so two cards called the same word are
/// two pieces.
///
/// ## Adding to a piece from an earlier visit
///
/// SOME NOW, MORE LATER is the normal case — a customer photographs a
/// cup, carries on throwing, and comes back. A key only lives for one
/// request, so a later angle on the same cup travels as
/// `piece_ids[]`: [existingPieces] are offered along the bottom and
/// picking one adds a card already bound to it.
///
/// ## Two caps, both counted against what is already uploaded
///
/// **Four photographs per person** ([photosLeft]), cumulative across
/// every upload on the booking.
///
/// **And, for the catalogue types, no more PIECES than were bought**
/// ([piecesLeft]) — they paid for a specific number of objects to
/// paint, so an extra card cannot manufacture one nobody paid for.
/// «صمم قطعتك» has no such cap: nothing is bought per object there and
/// one person at a wheel making three things is normal.
///
/// Both are checked here as well as on the server, because a customer
/// standing at a wheel with a full camera roll should be told before
/// the upload, not after it.
class PiecePhotosSheet extends StatefulWidget {
  const PiecePhotosSheet({
    required this.photosLeft,
    required this.onUpload,
    this.piecesLeft,
    this.expectedPieces,
    this.existingPieces = const <BookingPiece>[],
    this.openOnExisting = false,
    this.onRemoveExisting,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  /// The booking's remaining photograph allowance — `4 × people` less
  /// what it already holds.
  final int photosLeft;

  /// How many MORE pieces this booking may still hold, or null when
  /// the type has no such cap. Only a NEW card counts against it:
  /// another angle on a piece that already exists adds no piece.
  final int? piecesLeft;

  /// How many pieces this booking is EXPECTED to end up with, which
  /// is how many name fields step one opens with.
  ///
  /// «صمم قطعتك» is booked for a number of PEOPLE and each of them
  /// walks away with something, so a booking for two opens two fields
  /// rather than one and an "add another" nobody presses. It is a
  /// guide, not a ceiling — one person making three things is normal —
  /// so a field can still be added or removed.
  ///
  /// Null falls back to one.
  final int? expectedPieces;

  /// Pieces already on the booking, offered as "more photos of…".
  final List<BookingPiece> existingPieces;

  /// Open straight onto the FIRST of [existingPieces] rather than on
  /// the people who still have no piece.
  ///
  /// Set when the sheet was opened from one piece's own card: the
  /// reader asked about that cup, and landing them on a page asking
  /// for a new person's name answers a question nobody put.
  final bool openOnExisting;

  final WorkshopFamily family;
  final String? wireColor;

  /// Sends the drafts. Answers whether the server took them.
  ///
  /// `announce` is false for the uploads that go out in the
  /// BACKGROUND as the reader moves between people — they are meant
  /// to be invisible, and a success toast per person turned a quiet
  /// optimisation into four interruptions. Only the final press says
  /// anything.
  final Future<bool> Function(List<PieceDraft>, {bool announce}) onUpload;

  /// Takes one photograph the booking ALREADY holds off it.
  ///
  /// The row shows what is there beside what is being added, and a
  /// remove dot on a picture that cannot be removed is a dot that
  /// lies — so the same delete the card offers is wired through here.
  /// Answers whether it went, so a cancelled confirmation leaves the
  /// tile where it was.
  final Future<bool> Function(int imageId)? onRemoveExisting;

  @override
  State<PiecePhotosSheet> createState() => _PiecePhotosSheetState();
}

class _PiecePhotosSheetState extends State<PiecePhotosSheet> {
  late final List<PieceDraft> _drafts = [
    // OPENED FROM ONE PIECE'S CARD: that piece is the only page.
    if (widget.openOnExisting && widget.existingPieces.isNotEmpty)
      PieceDraft(existing: widget.existingPieces.first)
    else
      for (var i = 0; i < _seedCount; i++) const PieceDraft(),
  ];
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < _drafts.length; i++) TextEditingController(),
  ];

  /// One card per person the booking was for, so a party of two opens
  /// two fields and a party of one opens one.
  ///
  /// **It can legitimately be ZERO** — everyone on the booking has
  /// been named on an earlier visit, and all that is left is adding
  /// angles to the pieces that exist. Clamping it up to one would put
  /// an empty field on that screen asking for a person who is already
  /// there.
  int get _seedCount {
    final expected = widget.expectedPieces ?? 1;
    return expected < 0 ? 0 : expected;
  }

  /// WHOSE NAME the fields are asking for.
  ///
  /// On «صمم قطعتك» `expected_piece_count` is `people_count`: a label
  /// is a PERSON, and the studio writes it on that person's piece. At
  /// the moment step one is filled in nobody has made anything yet,
  /// so asking for the name of a piece is asking about something that
  /// does not exist.
  ///
  /// The catalogue types are the other way round — the count is the
  /// number of objects BOUGHT, one person may have bought several, and
  /// the label names the object.
  bool get _asksForPeople => widget.family == WorkshopFamily.makeYourPiece;

  /// WHICH person this page is, counting from the booking rather than
  /// from the sheet.
  ///
  /// «الشخص ١» over the first field is right on an empty booking and
  /// wrong on every other one: a party of three who photographed two
  /// people this morning come back to a sheet asking for one more, and
  /// that one is the THIRD person, not the first. The pieces already
  /// on the booking are people already named.
  ///
  /// Only NEW pages are counted. A page bound to an existing piece
  /// carries that piece's own name and asks for nothing.
  int _personNumber(int index) {
    var n = widget.existingPieces.length;
    for (var j = 0; j <= index && j < _drafts.length; j++) {
      if (!_drafts[j].isExisting) n++;
    }
    return n;
  }

  /// The piece this sheet was opened ON, by name — null when it was
  /// opened on the booking as a whole.
  String? get _openedOn {
    if (!widget.openOnExisting || _drafts.isEmpty) return null;
    final label = _drafts.first.wireLabel.trim();
    return label.isEmpty ? null : label;
  }

  /// `MAX_IMAGES_PER_PERSON` on the server. One label's ceiling,
  /// whatever the booking's total allowance is.
  static const _maxPerPiece = 4;

  /// Which person the reader is on.
  ///
  /// **ONE PERSON PER PAGE, not two steps over everybody.** Naming
  /// everyone and then photographing everyone asked the reader to
  /// hold a list in their head and match it back up — and it needed a
  /// step counter, a title and a sentence to explain itself before the
  /// first field. A page per person needs none of that: the dots say
  /// how many there are and the field is the heading. For a booking of
  /// one — the common case — there is no chrome at all.
  ///
  /// It also matches what is happening in the room. The photographs
  /// are taken AT the wheel, one person at a time, usually passing the
  /// phone along.
  int _page = 0;

  /// The upload each finished page started, by page index.
  ///
  /// **EACH PAGE SENDS AS THE READER LEAVES IT.** Photographs are the
  /// slowest thing this app does and a party of four is four sets of
  /// them — held to the end, the customer names everybody, presses
  /// upload and then watches a spinner for as long as the whole
  /// booking takes. Sent per page, three of the four are already on
  /// the server by the time the last one is photographed, and the
  /// final press has one set left to wait for.
  ///
  /// It fits the wire exactly: `piece_keys` groups WITHIN one request,
  /// so one request per person is one piece per person — which is what
  /// a separate call per page produces anyway.
  final _sent = <int, Future<bool>>{};

  /// Pages whose upload came back false. They are re-sent on the final
  /// press rather than left behind.
  final _failed = <int>{};

  /// Photographs the booking held when the sheet opened and no longer
  /// does. The drafts carry the piece as it was READ, so this is what
  /// keeps the row honest without re-opening the sheet.
  final _removedExisting = <int>{};

  /// What this page's piece already has on the server, less anything
  /// deleted since the sheet opened.
  List<ApiImage> _existingImages(int index) {
    final piece = _drafts[index].existing;
    if (piece == null) return const <ApiImage>[];
    return [
      for (final image in piece.images)
        if (!_removedExisting.contains(image.id)) image,
    ];
  }

  bool _sending = false;
  bool _showErrors = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  int get _photoCount =>
      _drafts.fold(0, (sum, draft) => sum + draft.files.length);

  /// Cards that would CREATE a piece. An existing one adds none.
  int get _newPieces => _drafts.where((d) => !d.isExisting).length;

  bool get _overPieceCap {
    final left = widget.piecesLeft;
    return left != null && _newPieces > left;
  }

  /// Whether this page's name was already taken by an EARLIER one.
  ///
  /// **Earlier, not "anybody else".** The check used to be symmetric,
  /// which flagged both pages — so typing «test» for the last person
  /// put the error on the FIRST one, who had typed it first and done
  /// nothing wrong. Going back to them and pressing next then refused
  /// to move, with the complaint on the wrong page and the real
  /// collision three pages away.
  ///
  /// Whoever typed it first keeps it; the later page is the one that
  /// has to change.
  ///
  /// Matched case- and whitespace-insensitively, because «Test» and
  /// «test » are the same person to everybody except a string
  /// comparison.
  bool _isDuplicate(int i) {
    if (i < 0 || i >= _drafts.length) return false;
    final mine = _drafts[i].label.trim().toLowerCase();
    if (mine.isEmpty) return false;
    for (var j = 0; j < i; j++) {
      final other = _drafts[j].isExisting
          ? _drafts[j].wireLabel.trim().toLowerCase()
          : _drafts[j].label.trim().toLowerCase();
      if (other == mine) return true;
    }

    // AND WHAT THE BOOKING ALREADY HOLDS. A piece uploaded on an
    // earlier visit is a label the studio is already using, and a new
    // person taking the same one is the same ambiguity — it just does
    // not happen to be on screen.
    for (final piece in widget.existingPieces) {
      if ((piece.label ?? '').trim().toLowerCase() == mine) return true;
    }
    return false;
  }

  /// One page is finished when that person has a name nobody else has
  /// and at least one photograph. An existing piece already carries
  /// its name.
  bool _pageDone(int i) {
    if (i < 0 || i >= _drafts.length) return false;
    final draft = _drafts[i];
    final named = draft.isExisting || draft.label.trim().isNotEmpty;
    return named && !_isDuplicate(i) && draft.files.isNotEmpty;
  }

  bool get _allDone =>
      _drafts.isNotEmpty &&
      List.generate(_drafts.length, _pageDone).every((done) => done);

  bool get _onLast => _page >= _drafts.length - 1;

  bool get _canSend => _allDone && !_overPieceCap && !_sending;

  /// What one card's picker may still take.
  ///
  /// TWO ceilings, and the lower wins: the booking's whole remaining
  /// allowance less what every OTHER card has spent of it, and
  /// `MAX_IMAGES_PER_PERSON` — four — on this one label. A booking for
  /// three people carries twelve photographs between them and still
  /// only four each.
  int _roomFor(int index) {
    final shared =
        (widget.photosLeft - (_photoCount - _drafts[index].files.length)).clamp(
          0,
          widget.photosLeft,
        );
    // AND WHAT THIS PIECE ALREADY HAS. Four is the ceiling on the
    // LABEL, not on one visit — a cup photographed three times in the
    // morning has one slot left, and offering four was offering a 422.
    final own = (_maxPerPiece - _existingImages(index).length).clamp(
      0,
      _maxPerPiece,
    );
    return shared < own ? shared : own;
  }

  /// ADDING TO A PIECE HAPPENS ON THE PIECE.
  ///
  /// This sheet used to end in a row of «صور أخرى لـ سارة» chips, one
  /// per piece already on the booking, each opening another page bound
  /// to it. That was the only way in when the gallery had a single
  /// heading button; now every card carries its own camera, which
  /// names the piece by being ON it. Two routes to the same page, one
  /// of them a list of names at the foot of a sheet about somebody
  /// else, is one too many — and the chips were the only thing that
  /// could put an existing piece on a page the reader had to be able
  /// to remove again.
  ///
  /// `openOnExisting` is what remains: the card's own way in.

  void _syncFiles(int index, List<PickerItem>? items) {
    final list = items ?? const <PickerItem>[];
    setState(() {
      _drafts[index] = _drafts[index].copyWith(
        files: [
          for (final item in list)
            if (item is PickerItemFile) item.file,
        ],
      );
    });

    // A TILE THAT WENT is a photograph the server still has. The
    // picker is told what to draw from the draft, so nothing has
    // actually happened yet — this is what makes it happen, and a
    // declined confirmation simply leaves the tile where it was.
    final kept = {
      for (final item in list)
        if (item is PickerItemUrl) item.url,
    };
    for (final image in _existingImages(index)) {
      if (!kept.contains(image.display)) unawaited(_dropExisting(image.id));
    }
  }

  Future<void> _dropExisting(int imageId) async {
    final remove = widget.onRemoveExisting;
    if (remove == null) return;
    final gone = await remove(imageId);
    if (!mounted || !gone) return;
    setState(() => _removedExisting.add(imageId));
  }

  /// On to the next person, if this one is finished — and send this
  /// one on its way while the reader deals with the next.
  ///
  /// The gap is MARKED rather than the button greyed: a dead button
  /// with nothing on screen saying why is the same trap the send
  /// button used to have.
  void _next() {
    setState(() => _showErrors = true);
    if (!_pageDone(_page)) return;

    _sendPage(_page);
    setState(() {
      _page++;
      // A fresh slate for the next person. Carrying the red marks
      // over would flag a name nobody has been asked for yet.
      _showErrors = false;
    });
  }

  /// Start one page's upload, unless it is already on its way.
  ///
  /// NOT awaited: the whole point is that the reader carries on. The
  /// result is kept so the final press can wait for it and re-send
  /// anything that failed.
  void _sendPage(int index, {bool announce = false}) {
    if (_sent.containsKey(index)) return;
    final future = widget.onUpload([_drafts[index]], announce: announce);
    _sent[index] = future;
    unawaited(
      future.then((ok) {
        if (!mounted || ok) return;
        // Recorded rather than shouted about mid-flow: the reader is
        // on the next person, and there is nothing useful they can do
        // about it until the end.
        setState(() => _failed.add(index));
      }),
    );
  }

  void _back() => setState(() {
    if (_page > 0) _page--;
    _showErrors = false;
  });

  /// The last page, plus anything still in the air or already failed.
  ///
  /// By here most of the work is usually done — every page but this
  /// one was sent as the reader left it, so this waits on one upload
  /// rather than on all of them.
  Future<void> _send() async {
    setState(() => _showErrors = true);
    if (!_canSend) return;

    setState(() => _sending = true);

    // RE-SEND WHAT FAILED. A page that came back false was recorded
    // and left alone at the time, because the reader was three people
    // further on and could do nothing about it.
    for (final index in _failed) {
      _sent.remove(index);
    }
    _failed.clear();

    for (var i = 0; i < _drafts.length; i++) {
      // ONLY THE LAST ONE SPEAKS. The others either went out quietly
      // pages ago or are going out now as part of the same press —
      // either way the reader asked once and wants one answer.
      _sendPage(i, announce: i == _drafts.length - 1);
    }

    final results = await Future.wait(_sent.values);
    if (!mounted) return;
    setState(() => _sending = false);
    if (results.every((ok) => ok)) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: widget.family,
      isDark: context.isDarkMode,
      wireColor: widget.wireColor,
    );
    final full = _photoCount >= widget.photosLeft;
    final empty = _drafts.isEmpty;

    return SheetShell(
      // «إضافة صور لـ سارة» when the sheet was opened from ONE
      // piece's card. It was «أضف صوراً» with the name repeated on a
      // row under it — the title is where a sheet says what it is
      // about, and saying it twice left the name competing with the
      // photographs for the first thing the eye lands on.
      title: _openedOn == null
          ? BookingStrings.uploadPhotos
          : BookingStrings.addPhotosFor(_openedOn!),

      // NO TINT. `tint` paints the whole panel, and the design uses it
      // for the one sheet it colours — the celebration upsell. Every
      // other sheet in the app is the plain surface, so a coloured
      // panel here read as a different app's sheet. The workshop's hue
      // still shows where it belongs: the picker's frame, the button,
      // the notes.
      heightFactor: null,
      maxHeightFactor: 0.86,

      // BACK ONLY WHERE THERE IS A BACK. On the first page it would be
      // a control that exists to be greyed out.
      footer: Row(
        children: [
          if (_page > 0) ...[
            Expanded(
              child: GlobalOutlinedButton(
                text: BookingStrings.back,
                onPressed: _back,
              ),
            ),
            SizedBox(width: spacing.sm),
          ],
          Expanded(
            flex: _page > 0 ? 2 : 1,
            child: GlobalFilledButton(
              text: _onLast ? BookingStrings.uploadSend : BookingStrings.next,
              // LIVE, and it marks what is missing when it cannot go.
              // Greyed out, the errors beside the field could never
              // appear — pressing is what turns them on.
              enabled: !_sending && !empty,
              isLoading: _sending,
              style: terracottaCtaStyle(
                showArrow: false,
              ).copyWith(backgroundColor: fam.primary),
              onPressed: _onLast ? () => unawaited(_send()) : _next,
            ),
          ),
        ],
      ),
      children: [
        if (empty)
          _Note(
            text: BookingStrings.allNamed,
            tint: context.textColors.secondary,
          )
        else ...[
          // WHOSE PIECE IT IS — unless the sheet's own title already
          // says, which it does when it was opened from one piece's
          // card.
          if (!widget.openOnExisting)
            _PersonName(
              number: _personNumber(_page),
              draft: _drafts[_page],
              controller: _controllers[_page],
              accent: fam.primary,
              asksForPerson: _asksForPeople,
              showErrors: _showErrors,
              duplicate: _isDuplicate(_page),
              onLabel: (value) => setState(
                () => _drafts[_page] = _drafts[_page].copyWith(label: value),
              ),
            ),
          SizedBox(height: spacing.md),
          // EDGE TO EDGE. The strip carries the sheet's own inset
          // INSIDE itself, so the first tile lines up with the field
          // above and a fourth one can still scroll in from past the
          // panel's edge. Padded from outside instead, the inset
          // becomes part of the viewport — a dead margin no picture
          // ever reaches, with the row cut short at both ends.
          SheetBleed(
            child: _PersonPhotos(
              draft: _drafts[_page],
              accent: fam.primary,
              room: _roomFor(_page),
              // WHAT IS ALREADY THERE, beside what is being added. A
              // reader adding a fourth angle cannot tell they are at
              // the ceiling from an empty row of slots.
              existing: _existingImages(_page),
              inset: spacing.md,
              onFiles: (items) => _syncFiles(_page, items),
            ),
          ),
          if (_showErrors && _drafts[_page].files.isEmpty) ...[
            SizedBox(height: spacing.xs),
            _Note(
              text: BookingStrings.pieceNeedsPhoto,
              tint: context.statusColors.error,
            ),
          ],
        ],

        // HOW MANY THERE ARE, as shape rather than a sentence — and
        // UNDER the pictures, where it reads as a footer to the page
        // rather than a header competing with the name field for the
        // first thing the eye lands on.
        //
        // The design's own mark, not plain dots: the onboarding slider
        // draws these vessels, and a second page-indicator idiom in
        // the same app reads as a different app's screen. A booking
        // for ONE shows nothing — there is no progress to report.
        if (_drafts.length > 1) ...[
          // ROOM ABOVE, none below. It is a footnote to the page, so
          // it wants to sit clear of the photographs and close to the
          // button — the sheet's own bottom padding is all the space
          // it needs under it.
          SizedBox(height: spacing.lg),
          VesselIndicator(
            count: _drafts.length,
            activeIndex: _page,
            scale: VesselIndicator.compactScale,
          ),
        ],

        // THE BOOKING IS OUT OF PHOTOGRAPHS. Worth saying, because it
        // is the one cap a reader cannot see the shape of.
        if (full) ...[
          SizedBox(height: spacing.sm),
          _Note(text: BookingStrings.photosFull, tint: fam.primary),
        ],

        SizedBox(height: spacing.xs),
      ],
    );
  }
}

/// WHOSE piece this page is about.
///
/// A piece the booking ALREADY holds keeps the name it was recorded
/// under — renaming it here would send a label the server ignores
/// anyway, since `piece_ids` names the row. It is changed from the
/// card instead; see [PieceRenameSheet].
///
/// There is no heading above the field. The field's own label carries
/// the number, and a card heading saying «الشخص ١» over a field
/// labelled «الشخص ١» printed it twice on every page.
class _PersonName extends StatelessWidget {
  const _PersonName({
    required this.number,
    required this.draft,
    required this.controller,
    required this.accent,
    required this.asksForPerson,
    required this.showErrors,
    required this.duplicate,
    required this.onLabel,
  });

  /// What this person is CALLED on the booking — see
  /// `_PiecePhotosSheetState._personNumber`. Not the page index: a
  /// booking that already holds two pieces opens its next page as
  /// «الشخص ٣».
  final int number;

  final PieceDraft draft;
  final TextEditingController controller;
  final Color accent;

  /// Whether this page is asking for a PERSON — see
  /// `_PiecePhotosSheetState._asksForPeople`.
  final bool asksForPerson;

  final bool showErrors;

  /// Somebody else on this booking already answers to this name.
  final bool duplicate;

  final ValueChanged<String> onLabel;

  @override
  Widget build(BuildContext context) => GlobalTextFormField(
    // LOCALISED DIGITS. Passed raw, the Arabic build read
    // «الشخص 1» — an Arabic label with a Western numeral in it.
    identifier: asksForPerson
        ? BookingStrings.personHint(AppNumbers.localizeDigits('$number'))
        : BookingStrings.pieceHint(AppNumbers.localizeDigits('$number')),
    // «كوبي» prompts for an OBJECT, and on the wheel the thing being
    // named is a person.
    hint: asksForPerson
        ? BookingStrings.personNameHint
        : BookingStrings.pieceLabelHint,
    controller: controller,
    // 60 is the server's own ceiling on a label.
    behavior: const TextFieldBehavior(maxLength: 60),
    validation: TextFieldValidation(
      // TWO different faults, said apart. "Give every person a name"
      // over a field that HAS one sends the reader looking for an
      // empty box that is not there.
      //
      // THE COLLISION SHOWS AS IT HAPPENS, without waiting for the
      // button — a name already taken is a fact the moment it is
      // typed. The MISSING one still waits: flagging an empty field
      // the instant the page opens tells somebody off for not
      // having started yet.
      errorText: duplicate
          ? BookingStrings.nameTakenFor(person: asksForPerson)
          : showErrors && draft.label.trim().isEmpty
          ? BookingStrings.pieceLabelRequired
          : null,
    ),
    callbacks: TextFieldCallbacks(onChanged: onLabel),
  );
}

/// The photographs of what they made — what is already on the server,
/// then what is about to go up.
///
/// FOUR SLOTS SAY "UP TO FOUR". That is what the sentence «حتى ٤ صور
/// لكل قطعة» was for, and the shape says it without a line of text:
/// [room] is already the lower of this page's ceiling and what the
/// booking has left.
class _PersonPhotos extends StatelessWidget {
  const _PersonPhotos({
    required this.draft,
    required this.accent,
    required this.room,
    required this.existing,
    required this.inset,
    required this.onFiles,
  });

  final PieceDraft draft;
  final Color accent;

  /// How many more photographs this page may take.
  final int room;

  /// The photographs this piece ALREADY has. Drawn in the same row,
  /// badged «سابقة» against the «جديد» on the ones about to go up.
  final List<ApiImage> existing;

  /// The sheet's own horizontal inset, carried INSIDE the strip — see
  /// `GlobalImagePicker.stripPadding`.
  final double inset;

  final ValueChanged<List<PickerItem>?> onFiles;

  @override
  Widget build(BuildContext context) => GlobalImagePicker(
    // A ROW, not a grid. Four square tiles wrapped to two lines on a
    // phone, which made the page taller than the sheet and pushed the
    // button off it. In a row they scroll, and the shape still says
    // how many there are.
    layout: MediaPickerLayout.horizontalList,
    // SEVERAL angles on one object, so the picker is in multi mode and
    // `images` is a LIST. Passing a list without saying so trips its
    // own assert.
    multiple: true,
    // OLD FIRST, THEN NEW. The module's own idiom: a url is a
    // photograph the server has, a file is one about to go up, and it
    // badges them apart on its own once `showExistingBadge` is on.
    images: [
      for (final image in existing) PickerItem.url(image.display),
      for (final file in draft.files)
        PickerItem.file(file, isNew: existing.isNotEmpty),
    ],
    onChanged: (value) => onFiles(value as List<PickerItem>?),
    maxImages: existing.length + room,
    stripPadding: EdgeInsetsDirectional.only(start: inset, end: inset),
    hint: BookingStrings.uploadPiece,
    icon: Icons.add_a_photo_outlined,
    style: MediaPickerStyle(
      accent: accent,
      surfaceColor: accent.withValues(alpha: 0.06),
      hintColor: context.textColors.primary,
      tileRadius: context.radii.md,
      dashed: true,
      // Only where there is an "already" to point at.
      showExistingBadge: existing.isNotEmpty,
      // NOT REORDERABLE, and that is what keeps this strip looking
      // like the one on the naming page.
      //
      // The picker draws a horizontal row two different ways: a
      // `ListView` — which carries the inset inside itself, clips
      // sideways only and fades where there is more — and, once there
      // is more than one tile AND reordering is on, a `ReorderableRow`
      // with none of that. So a page with one photograph on it and the
      // same page with three were two different rows.
      //
      // Reordering earns none of that here anyway: the order of four
      // angles on one cup means nothing to anybody, and long-press-to
      // -drag inside a sheet is competing with the sheet's own drag.
      reorderable: false,
    ),
  );
}

/// A line of guidance under the heading, tinted by what it is saying.
class _Note extends StatelessWidget {
  const _Note({required this.text, required this.tint});

  final String text;
  final Color tint;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.labelMedium?.copyWith(color: tint),
  );
}

/// Opens [PiecePhotosSheet] over the booking.
Future<void> showPiecePhotosSheet(
  BuildContext context, {
  required int photosLeft,
  required Future<bool> Function(List<PieceDraft>, {bool announce}) onUpload,
  int? piecesLeft,
  int? expectedPieces,
  List<BookingPiece> existingPieces = const <BookingPiece>[],
  bool openOnExisting = false,
  Future<bool> Function(int imageId)? onRemoveExisting,
  WorkshopFamily family = WorkshopFamily.makeYourPiece,
  String? wireColor,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => PiecePhotosSheet(
    photosLeft: photosLeft,
    piecesLeft: piecesLeft,
    expectedPieces: expectedPieces,
    existingPieces: existingPieces,
    openOnExisting: openOnExisting,
    onRemoveExisting: onRemoveExisting,
    onUpload: onUpload,
    family: family,
    wireColor: wireColor,
  ),
);
