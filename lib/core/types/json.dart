/// Common JSON type aliases. Use these instead of spelling
/// `Map<String, dynamic>` all over the codebase.
///
/// ```dart
/// Json parseUser(Json json) => User.fromJson(json);
/// ```
library;

/// A JSON object — the canonical `Map<String, dynamic>` shape that every
/// `fromJson` / `toJson` method works with.
typedef Json = Map<String, dynamic>;

/// A raw JSON array (untyped items) — `[1, "a", {...}, ...]`.
typedef JsonList = List<dynamic>;

/// A list of JSON objects — `[{...}, {...}, ...]`. Common return shape
/// for list endpoints before items are typed.
typedef JsonObjectList = List<Json>;
