import 'package:freezed_annotation/freezed_annotation.dart';

/// WHO A WORKSHOP IS FOR — `audience` on `GET /api/workshops` and
/// `GET /api/workshops/{id}`.
///
/// **The server does not enforce it, and it cannot.** The app never
/// asks anybody's gender, so nothing checks a booking against this.
/// It exists to be READ — a woman arriving at a men-only session has
/// been let down by the screen, not by a validator. Show it wherever a
/// workshop is offered.
///
/// [mixed] is the default and what every workshop carried before the
/// field existed, so an absent value is [mixed] rather than unknown.
///
/// An unrecognised value parses to [mixed] rather than throwing: this
/// is a CMS-driven set that can grow, and one new word must not take
/// the whole catalogue down the way a required `image` once did.
enum WorkshopAudience {
  mixed('mixed'),
  womenOnly('women_only'),
  menOnly('men_only'),
  couples('couples'),
  kids('kids'),
  families('families');

  const WorkshopAudience(this.wire);

  /// The exact string the server sends.
  final String wire;

  static WorkshopAudience fromWire(String? value) =>
      WorkshopAudience.values.firstWhere(
        (a) => a.wire == value,
        orElse: () => WorkshopAudience.mixed,
      );

  /// Whether this is worth saying out loud.
  ///
  /// «للجميع» on every card is noise — it is the default and it is what
  /// most workshops are. The badge appears only when the session is
  /// restricted to somebody.
  bool get isRestricted => this != WorkshopAudience.mixed;
}

/// Reads `audience` off the wire, defaulting an unknown or missing one
/// to [WorkshopAudience.mixed].
class WorkshopAudienceConverter
    implements JsonConverter<WorkshopAudience, String?> {
  const WorkshopAudienceConverter();

  @override
  WorkshopAudience fromJson(String? json) => WorkshopAudience.fromWire(json);

  @override
  String toJson(WorkshopAudience object) => object.wire;
}
