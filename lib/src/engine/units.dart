// The units of Convert: offline tables, each unit a factor to the base unit of its category
// (temperature is affine). Currencies are not here: they need rates from the network, and the
// app has no network source.

enum UnitCategory {
  angle('Angle', 'Angolo'),
  area('Area', 'Area'),
  data('Data', 'Dati'),
  energy('Energy', 'Energia'),
  force('Force', 'Forza'),
  length('Length', 'Lunghezza'),
  mass('Mass', 'Massa'),
  power('Power', 'Potenza'),
  pressure('Pressure', 'Pressione'),
  speed('Speed', 'Velocità'),
  temperature('Temperature', 'Temperatura'),
  time('Time', 'Tempo'),
  volume('Volume', 'Volume');

  const UnitCategory(this.en, this.it);
  final String en;
  final String it;

  String name(String language) => language == 'it' ? it : en;

  List<ConvertUnit> get units => [
    for (final u in allUnits)
      if (u.category == this) u,
  ];
}

class ConvertUnit {
  const ConvertUnit(
    this.id,
    this.category,
    this.symbol,
    this.en,
    this.it,
    this.factor, {
    this.offset = 0,
  });

  final String id;
  final UnitCategory category;

  /// The code shown next to the value ("km", "°C").
  final String symbol;
  final String en;
  final String it;

  /// Base units per unit: `base = value * factor + offset`.
  final double factor;
  final double offset;

  String name(String language) => language == 'it' ? it : en;

  double toBase(double v) => v * factor + offset;
  double fromBase(double b) => (b - offset) / factor;
}

/// Converts [value] between two units of the same category.
double convertValue(double value, ConvertUnit from, ConvertUnit to) =>
    from == to ? value : to.fromBase(from.toBase(value));

/// The two units a category opens with.
(ConvertUnit, ConvertUnit) defaultPair(UnitCategory c) {
  final u = c.units;
  final first = switch (c) {
    UnitCategory.length => 'km',
    UnitCategory.mass => 'kg',
    UnitCategory.temperature => 'c',
    UnitCategory.time => 'h',
    UnitCategory.speed => 'kmh',
    UnitCategory.area => 'm2',
    UnitCategory.volume => 'l',
    _ => u.first.id,
  };
  final second = switch (c) {
    UnitCategory.length => 'mi',
    UnitCategory.mass => 'lb',
    UnitCategory.temperature => 'f',
    UnitCategory.time => 'min',
    UnitCategory.speed => 'mph',
    UnitCategory.area => 'ft2',
    UnitCategory.volume => 'gal',
    _ => u[1].id,
  };
  return (unitById(first), unitById(second));
}

ConvertUnit unitById(String id) =>
    allUnits.firstWhere((u) => u.id == id, orElse: () => allUnits.first);

const _a = UnitCategory.angle;
const _ar = UnitCategory.area;
const _d = UnitCategory.data;
const _e = UnitCategory.energy;
const _f = UnitCategory.force;
const _l = UnitCategory.length;
const _m = UnitCategory.mass;
const _p = UnitCategory.power;
const _pr = UnitCategory.pressure;
const _s = UnitCategory.speed;
const _t = UnitCategory.temperature;
const _ti = UnitCategory.time;
const _v = UnitCategory.volume;

const List<ConvertUnit> allUnits = [
  ConvertUnit('deg', _a, '°', 'Degree', 'Grado', 1),
  ConvertUnit('rad', _a, 'rad', 'Radian', 'Radiante', 57.29577951308232),
  ConvertUnit('grad', _a, 'gon', 'Gradian', 'Gradiante', 0.9),
  ConvertUnit('turn', _a, 'rev', 'Revolution', 'Giro', 360),
  ConvertUnit('arcmin', _a, '′', 'Arcminute', 'Primo d’arco', 1 / 60),
  ConvertUnit('arcsec', _a, '″', 'Arcsecond', 'Secondo d’arco', 1 / 3600),
  ConvertUnit('m2', _ar, 'm²', 'Square Meter', 'Metro quadro', 1),
  ConvertUnit('km2', _ar, 'km²', 'Square Kilometer', 'Chilometro quadro', 1e6),
  ConvertUnit(
    'cm2',
    _ar,
    'cm²',
    'Square Centimeter',
    'Centimetro quadro',
    1e-4,
  ),
  ConvertUnit(
    'mm2',
    _ar,
    'mm²',
    'Square Millimeter',
    'Millimetro quadro',
    1e-6,
  ),
  ConvertUnit('ha', _ar, 'ha', 'Hectare', 'Ettaro', 1e4),
  ConvertUnit('acre', _ar, 'ac', 'Acre', 'Acro', 4046.8564224),
  ConvertUnit('ft2', _ar, 'ft²', 'Square Foot', 'Piede quadro', 0.09290304),
  ConvertUnit('in2', _ar, 'in²', 'Square Inch', 'Pollice quadro', 0.00064516),
  ConvertUnit('yd2', _ar, 'yd²', 'Square Yard', 'Iarda quadra', 0.83612736),
  ConvertUnit(
    'mi2',
    _ar,
    'mi²',
    'Square Mile',
    'Miglio quadro',
    2589988.110336,
  ),
  ConvertUnit('bit', _d, 'bit', 'Bit', 'Bit', 0.125),
  ConvertUnit('byte', _d, 'B', 'Byte', 'Byte', 1),
  ConvertUnit('kb', _d, 'kB', 'Kilobyte', 'Kilobyte', 1e3),
  ConvertUnit('mb', _d, 'MB', 'Megabyte', 'Megabyte', 1e6),
  ConvertUnit('gb', _d, 'GB', 'Gigabyte', 'Gigabyte', 1e9),
  ConvertUnit('tb', _d, 'TB', 'Terabyte', 'Terabyte', 1e12),
  ConvertUnit('kib', _d, 'KiB', 'Kibibyte', 'Kibibyte', 1024),
  ConvertUnit('mib', _d, 'MiB', 'Mebibyte', 'Mebibyte', 1048576),
  ConvertUnit('gib', _d, 'GiB', 'Gibibyte', 'Gibibyte', 1073741824),
  ConvertUnit('tib', _d, 'TiB', 'Tebibyte', 'Tebibyte', 1099511627776),
  ConvertUnit('j', _e, 'J', 'Joule', 'Joule', 1),
  ConvertUnit('kj', _e, 'kJ', 'Kilojoule', 'Kilojoule', 1000),
  ConvertUnit('cal', _e, 'cal', 'Calorie', 'Caloria', 4.184),
  ConvertUnit('kcal', _e, 'kcal', 'Kilocalorie', 'Chilocaloria', 4184),
  ConvertUnit('wh', _e, 'Wh', 'Watt-hour', 'Wattora', 3600),
  ConvertUnit('kwh', _e, 'kWh', 'Kilowatt-hour', 'Chilowattora', 3.6e6),
  ConvertUnit('btu', _e, 'BTU', 'BTU', 'BTU', 1055.05585262),
  ConvertUnit(
    'ftlbf',
    _e,
    'ft·lbf',
    'Foot-pound',
    'Piede-libbra',
    1.3558179483314,
  ),
  ConvertUnit('n', _f, 'N', 'Newton', 'Newton', 1),
  ConvertUnit('kn', _f, 'kN', 'Kilonewton', 'Kilonewton', 1000),
  ConvertUnit('lbf', _f, 'lbf', 'Pound-force', 'Libbra-forza', 4.4482216152605),
  ConvertUnit('kgf', _f, 'kgf', 'Kilogram-force', 'Chilogrammo-forza', 9.80665),
  ConvertUnit('dyn', _f, 'dyn', 'Dyne', 'Dina', 1e-5),
  ConvertUnit('mm', _l, 'mm', 'Millimeter', 'Millimetro', 1e-3),
  ConvertUnit('cm', _l, 'cm', 'Centimeter', 'Centimetro', 1e-2),
  ConvertUnit('m', _l, 'm', 'Meter', 'Metro', 1),
  ConvertUnit('km', _l, 'km', 'Kilometer', 'Chilometro', 1000),
  ConvertUnit('in', _l, 'in', 'Inch', 'Pollice', 0.0254),
  ConvertUnit('ft', _l, 'ft', 'Foot', 'Piede', 0.3048),
  ConvertUnit('yd', _l, 'yd', 'Yard', 'Iarda', 0.9144),
  ConvertUnit('mi', _l, 'mi', 'Mile', 'Miglio', 1609.344),
  ConvertUnit('nmi', _l, 'nmi', 'Nautical Mile', 'Miglio nautico', 1852),
  ConvertUnit('mg', _m, 'mg', 'Milligram', 'Milligrammo', 1e-6),
  ConvertUnit('g', _m, 'g', 'Gram', 'Grammo', 1e-3),
  ConvertUnit('kg', _m, 'kg', 'Kilogram', 'Chilogrammo', 1),
  ConvertUnit('t', _m, 't', 'Metric Ton', 'Tonnellata', 1000),
  ConvertUnit('oz', _m, 'oz', 'Ounce', 'Oncia', 0.028349523125),
  ConvertUnit('lb', _m, 'lb', 'Pound', 'Libbra', 0.45359237),
  ConvertUnit('st', _m, 'st', 'Stone', 'Stone', 6.35029318),
  ConvertUnit('w', _p, 'W', 'Watt', 'Watt', 1),
  ConvertUnit('kw', _p, 'kW', 'Kilowatt', 'Chilowatt', 1000),
  ConvertUnit('mw', _p, 'MW', 'Megawatt', 'Megawatt', 1e6),
  ConvertUnit(
    'hp',
    _p,
    'hp',
    'Horsepower',
    'Cavallo vapore (hp)',
    745.6998715822702,
  ),
  ConvertUnit('pa', _pr, 'Pa', 'Pascal', 'Pascal', 1),
  ConvertUnit('kpa', _pr, 'kPa', 'Kilopascal', 'Kilopascal', 1000),
  ConvertUnit('bar', _pr, 'bar', 'Bar', 'Bar', 1e5),
  ConvertUnit('mbar', _pr, 'mbar', 'Millibar', 'Millibar', 100),
  ConvertUnit('atm', _pr, 'atm', 'Atmosphere', 'Atmosfera', 101325),
  ConvertUnit(
    'psi',
    _pr,
    'psi',
    'Pound per Square Inch',
    'Libbra per pollice quadro',
    6894.757293168,
  ),
  ConvertUnit(
    'mmhg',
    _pr,
    'mmHg',
    'Millimeter of Mercury',
    'Millimetro di mercurio',
    133.322387415,
  ),
  ConvertUnit('ms', _s, 'm/s', 'Meter per Second', 'Metro al secondo', 1),
  ConvertUnit(
    'kmh',
    _s,
    'km/h',
    'Kilometer per Hour',
    'Chilometro orario',
    1 / 3.6,
  ),
  ConvertUnit('mph', _s, 'mph', 'Mile per Hour', 'Miglio orario', 0.44704),
  ConvertUnit('kt', _s, 'kn', 'Knot', 'Nodo', 1852 / 3600),
  ConvertUnit('fts', _s, 'ft/s', 'Foot per Second', 'Piede al secondo', 0.3048),
  ConvertUnit('c', _t, '°C', 'Celsius', 'Celsius', 1, offset: 273.15),
  ConvertUnit(
    'f',
    _t,
    '°F',
    'Fahrenheit',
    'Fahrenheit',
    5 / 9,
    offset: 255.3722222222222,
  ),
  ConvertUnit('k', _t, 'K', 'Kelvin', 'Kelvin', 1),
  ConvertUnit('msec', _ti, 'ms', 'Millisecond', 'Millisecondo', 1e-3),
  ConvertUnit('sec', _ti, 's', 'Second', 'Secondo', 1),
  ConvertUnit('min', _ti, 'min', 'Minute', 'Minuto', 60),
  ConvertUnit('h', _ti, 'h', 'Hour', 'Ora', 3600),
  ConvertUnit('day', _ti, 'd', 'Day', 'Giorno', 86400),
  ConvertUnit('week', _ti, 'wk', 'Week', 'Settimana', 604800),
  ConvertUnit('year', _ti, 'yr', 'Year', 'Anno', 31557600),
  ConvertUnit('ml', _v, 'mL', 'Milliliter', 'Millilitro', 1e-3),
  ConvertUnit('l', _v, 'L', 'Liter', 'Litro', 1),
  ConvertUnit('m3', _v, 'm³', 'Cubic Meter', 'Metro cubo', 1000),
  ConvertUnit('tsp', _v, 'tsp', 'Teaspoon', 'Cucchiaino', 0.00492892159375),
  ConvertUnit('tbsp', _v, 'tbsp', 'Tablespoon', 'Cucchiaio', 0.01478676478125),
  ConvertUnit(
    'floz',
    _v,
    'fl oz',
    'Fluid Ounce',
    'Oncia fluida',
    0.0295735295625,
  ),
  ConvertUnit('cup', _v, 'cup', 'Cup', 'Tazza', 0.2365882365),
  ConvertUnit('pt', _v, 'pt', 'Pint', 'Pinta', 0.473176473),
  ConvertUnit('qt', _v, 'qt', 'Quart', 'Quarto', 0.946352946),
  ConvertUnit('gal', _v, 'gal', 'Gallon', 'Gallone', 3.785411784),
];
