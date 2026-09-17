/// Strip a leading YAML-ish frontmatter block from a markdown body
/// and return the parsed key/value map.
///
/// Only supports flat `key: value` pairs (the 90% case). Anything
/// fancier — nested objects, arrays, multiline scalars — won't parse;
/// the entire frontmatter section is discarded as text instead. Pull
/// in `yaml` package if you need full YAML.
({String body, Map<String, dynamic> metadata}) parseFrontmatter(String input) {
  final pattern = RegExp(r'^---\s*\n([\s\S]*?)\n---\s*\n');
  final m = pattern.firstMatch(input);
  if (m == null) {
    return (body: input, metadata: const {});
  }
  final raw = m.group(1) ?? '';
  final body = input.substring(m.end);

  final map = <String, dynamic>{};
  for (final rawLine in raw.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final idx = line.indexOf(':');
    if (idx < 0) continue;
    final key = line.substring(0, idx).trim();
    var value = line.substring(idx + 1).trim();
    // Strip optional surrounding quotes.
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    map[key] = _coerce(value);
  }
  return (body: body, metadata: map);
}

dynamic _coerce(String raw) {
  if (raw == 'true') return true;
  if (raw == 'false') return false;
  if (raw == 'null' || raw.isEmpty) return null;
  final asInt = int.tryParse(raw);
  if (asInt != null) return asInt;
  final asDouble = double.tryParse(raw);
  if (asDouble != null) return asDouble;
  return raw;
}
