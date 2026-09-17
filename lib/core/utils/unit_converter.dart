import 'dart:math' as math;

/// Physical-quantity category a unit belongs to.
enum UnitCategory {
  weight,
  length,
  volume,
  area,
  speed,
  duration,
  temperature,
  pressure,
  energy,
  power,
  frequency,
  angle,
  fuelEconomy,
  dataRate,
  digital,
}

/// Converts between units of the same [UnitCategory]. Pure math, no I/O.
///
/// Most categories are LINEAR (a factor to a base unit); two aren't and
/// get special handling:
/// * **temperature** is AFFINE (°C↔°F carries a +32 offset, not a
///   factor) — base is Celsius.
/// * **fuelEconomy** is RECIPROCAL (`L/100km = 100 / (km/L)`) — base is
///   km/L.
///
/// Every unit symbol across the categories is globally unique, so a
/// single lookup resolves both the category and the factor.
abstract final class UnitConverter {
  // symbol → factor to the category's base unit (linear categories only).
  static const Map<String, double> _factors = {
    // weight — base gram
    'kg': 1000, 'g': 1, 'mg': 0.001, 't': 1000000, 'lb': 453.59237,
    'oz': 28.349523125,
    // length — base metre
    'km': 1000, 'm': 1, 'cm': 0.01, 'mm': 0.001, 'mi': 1609.344,
    'ft': 0.3048, 'in': 0.0254, 'yd': 0.9144,
    // volume — base millilitre
    'L': 1000,
    'mL': 1,
    'm³': 1000000,
    'gal': 3785.411784,
    'fl oz': 29.5735295625,
    // area — base square metre
    'm²': 1, 'km²': 1000000, 'dunum': 1000, 'ha': 10000, 'acre': 4046.8564224,
    'ft²': 0.09290304,
    // speed — base metre/second
    'km/h': 0.277777778, 'm/s': 1, 'mph': 0.44704, 'knot': 0.514444444,
    // duration — base second
    'sec': 1, 'min': 60, 'hr': 3600, 'day': 86400,
    // pressure — base pascal
    'bar': 100000, 'psi': 6894.757293, 'kPa': 1000, 'atm': 101325,
    // energy — base joule
    'J': 1, 'kJ': 1000, 'cal': 4.184, 'kcal': 4184, 'kWh': 3600000,
    // power — base watt
    'W': 1, 'kW': 1000, 'hp': 745.699872,
    // frequency — base hertz
    'Hz': 1, 'kHz': 1000, 'MHz': 1000000, 'GHz': 1000000000,
    // angle — base radian
    '°': math.pi / 180, 'rad': 1,
    // data rate — base bit/second (SI, ×1000)
    'Kbps': 1000, 'Mbps': 1000000, 'Gbps': 1000000000,
    // digital storage — base byte (SI, ×1000)
    'KB': 1000, 'MB': 1000000, 'GB': 1000000000, 'TB': 1000000000000,
    // cooking — base millilitre
    'cup': 236.5882365, 'tbsp': 14.78676478, 'tsp': 4.928921594,
  };

  static const Map<String, UnitCategory> _extraCategory = {
    '°C': UnitCategory.temperature,
    '°F': UnitCategory.temperature,
    'K': UnitCategory.temperature,
    'km/L': UnitCategory.fuelEconomy,
    'L/100km': UnitCategory.fuelEconomy,
    'mpg': UnitCategory.fuelEconomy,
  };

  static const Map<String, UnitCategory> _factorCategory = {
    'kg': UnitCategory.weight, 'g': UnitCategory.weight,
    'mg': UnitCategory.weight, 't': UnitCategory.weight,
    'lb': UnitCategory.weight, 'oz': UnitCategory.weight,
    'km': UnitCategory.length, 'm': UnitCategory.length,
    'cm': UnitCategory.length, 'mm': UnitCategory.length,
    'mi': UnitCategory.length, 'ft': UnitCategory.length,
    'in': UnitCategory.length, 'yd': UnitCategory.length,
    'L': UnitCategory.volume, 'mL': UnitCategory.volume,
    'm³': UnitCategory.volume, 'gal': UnitCategory.volume,
    'fl oz': UnitCategory.volume,
    'm²': UnitCategory.area, 'km²': UnitCategory.area,
    'dunum': UnitCategory.area, 'ha': UnitCategory.area,
    'acre': UnitCategory.area, 'ft²': UnitCategory.area,
    'km/h': UnitCategory.speed, 'm/s': UnitCategory.speed,
    'mph': UnitCategory.speed, 'knot': UnitCategory.speed,
    'sec': UnitCategory.duration, 'min': UnitCategory.duration,
    'hr': UnitCategory.duration, 'day': UnitCategory.duration,
    'bar': UnitCategory.pressure, 'psi': UnitCategory.pressure,
    'kPa': UnitCategory.pressure, 'atm': UnitCategory.pressure,
    'J': UnitCategory.energy, 'kJ': UnitCategory.energy,
    'cal': UnitCategory.energy, 'kcal': UnitCategory.energy,
    'kWh': UnitCategory.energy,
    'W': UnitCategory.power, 'kW': UnitCategory.power, 'hp': UnitCategory.power,
    'Hz': UnitCategory.frequency, 'kHz': UnitCategory.frequency,
    'MHz': UnitCategory.frequency, 'GHz': UnitCategory.frequency,
    '°': UnitCategory.angle, 'rad': UnitCategory.angle,
    'Kbps': UnitCategory.dataRate, 'Mbps': UnitCategory.dataRate,
    'Gbps': UnitCategory.dataRate,
    'KB': UnitCategory.digital, 'MB': UnitCategory.digital,
    'GB': UnitCategory.digital, 'TB': UnitCategory.digital,
    // cooking measures are volumes — same category, so cup ↔ mL ↔ L all
    // convert.
    'cup': UnitCategory.volume, 'tbsp': UnitCategory.volume,
    'tsp': UnitCategory.volume,
  };

  /// The category a unit belongs to, or null when unknown.
  static UnitCategory? categoryOf(String unit) =>
      _factorCategory[unit] ?? _extraCategory[unit];

  /// A canonical unit for [cat] — the target for `Measurement.toBase()`
  /// normalization. Each is a real, convertible symbol.
  static String baseUnitOf(UnitCategory cat) => switch (cat) {
    UnitCategory.weight => 'g',
    UnitCategory.length => 'm',
    UnitCategory.volume => 'mL',
    UnitCategory.area => 'm²',
    UnitCategory.speed => 'm/s',
    UnitCategory.duration => 'sec',
    UnitCategory.temperature => '°C',
    UnitCategory.pressure => 'kPa',
    UnitCategory.energy => 'J',
    UnitCategory.power => 'W',
    UnitCategory.frequency => 'Hz',
    UnitCategory.angle => 'rad',
    UnitCategory.fuelEconomy => 'km/L',
    UnitCategory.dataRate => 'Kbps',
    UnitCategory.digital => 'KB',
  };

  /// True when [from] and [to] share a category (so a value can convert).
  static bool canConvert(String from, String to) {
    final c = categoryOf(from);
    return c != null && c == categoryOf(to);
  }

  /// Convert [value] from unit [from] to unit [to]. Returns null when the
  /// units are unknown or belong to different categories.
  static double? convert(double value, String from, String to) {
    if (from == to) return value;
    final cat = categoryOf(from);
    if (cat == null || cat != categoryOf(to)) return null;
    return switch (cat) {
      UnitCategory.temperature => _tempFromC(_tempToC(value, from), to),
      UnitCategory.fuelEconomy => _fuelFromKmL(_fuelToKmL(value, from), to),
      _ => value * _factors[from]! / _factors[to]!,
    };
  }

  // ── Temperature (base Celsius) ──────────────────────────────
  static double _tempToC(double v, String unit) => switch (unit) {
    '°F' => (v - 32) * 5 / 9,
    'K' => v - 273.15,
    _ => v, // °C
  };
  static double _tempFromC(double c, String unit) => switch (unit) {
    '°F' => c * 9 / 5 + 32,
    'K' => c + 273.15,
    _ => c, // °C
  };

  // ── Fuel economy (base km/L) ────────────────────────────────
  static double _fuelToKmL(double v, String unit) => switch (unit) {
    'L/100km' => v == 0 ? 0 : 100 / v,
    'mpg' => v * 0.425143707,
    _ => v, // km/L
  };
  static double _fuelFromKmL(double kmL, String unit) => switch (unit) {
    'L/100km' => kmL == 0 ? 0 : 100 / kmL,
    'mpg' => kmL / 0.425143707,
    _ => kmL, // km/L
  };
}
