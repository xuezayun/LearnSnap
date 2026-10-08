import 'dart:math';

enum OralOp { add, sub, mul, div }

enum OralGrade {
  one,
  two,
  three,
  four,
  five;

  int get number => index + 1;

  String get label => const ['一年级', '二年级', '三年级', '四年级', '五年级'][index];

  Set<OralOp> get allowedOps => switch (this) {
        OralGrade.one || OralGrade.five => const {OralOp.add, OralOp.sub},
        _ => const {OralOp.add, OralOp.sub, OralOp.mul, OralOp.div},
      };

  static OralGrade fromNumber(int number) {
    final index = number.clamp(1, 5).toInt() - 1;
    return OralGrade.values[index];
  }
}

class OralProblem {
  const OralProblem({
    required this.a,
    required this.b,
    required this.op,
    this.decimal = false,
  });

  final int a;
  final int b;
  final OralOp op;

  /// When true, [a] and [b] are tenths (12 means 1.2).
  final bool decimal;

  String get expression {
    if (!decimal) {
      return switch (op) {
        OralOp.add => '$a + $b',
        OralOp.sub => '$a − $b',
        OralOp.mul => '$a × $b',
        OralOp.div => '$a ÷ $b',
      };
    }
    return switch (op) {
      OralOp.add => '${_formatTenths(a)} + ${_formatTenths(b)}',
      OralOp.sub => '${_formatTenths(a)} − ${_formatTenths(b)}',
      OralOp.mul => '${_formatTenths(a)} × ${_formatTenths(b)}',
      OralOp.div => '${_formatTenths(a)} ÷ ${_formatTenths(b)}',
    };
  }

  String get spoken {
    final left = decimal ? zhTenths(a) : zhNumber(a);
    final right = decimal ? zhTenths(b) : zhNumber(b);
    return switch (op) {
      OralOp.add => '$left加$right',
      OralOp.sub => '$left减$right',
      OralOp.mul => '$left乘$right',
      OralOp.div => '$left除以$right',
    };
  }
}

const _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

String zhNumber(int n) {
  if (n < 0 || n > 999) return '$n';
  if (n <= 100) return _zhUpTo100(n);
  final hundreds = n ~/ 100;
  final rest = n % 100;
  final head = '${_digits[hundreds]}百';
  if (rest == 0) return head;
  if (rest < 10) return '$head零${_digits[rest]}';
  if (rest < 20) return '$head一${_zhUpTo100(rest)}';
  return '$head${_zhUpTo100(rest)}';
}

String zhTenths(int tenths) {
  if (tenths < 0) return '$tenths';
  final whole = tenths ~/ 10;
  final frac = tenths % 10;
  if (frac == 0) return zhNumber(whole);
  final head = whole == 0 ? '零' : zhNumber(whole);
  return '$head点${_digits[frac]}';
}

String _zhUpTo100(int n) {
  if (n < 10) return _digits[n];
  if (n == 10) return '十';
  if (n < 20) return '十${_digits[n % 10]}';
  if (n == 100) return '一百';
  if (n % 10 == 0) return '${_digits[n ~/ 10]}十';
  return '${_digits[n ~/ 10]}十${_digits[n % 10]}';
}

String _formatTenths(int tenths) {
  final whole = tenths ~/ 10;
  final frac = tenths.abs() % 10;
  if (frac == 0) return '$whole';
  return '$whole.$frac';
}

List<OralProblem> buildOralProblems({
  required Set<OralOp> ops,
  required OralGrade grade,
  required int count,
  Random? random,
}) {
  final allowed = grade.allowedOps;
  final chosen = ops.where(allowed.contains).toSet();
  final usable = chosen.isEmpty ? {allowed.first} : chosen;
  final rng = random ?? Random();
  return [
    for (var i = 0; i < count; i++) _one(rng, _pickOp(rng, usable, grade), grade),
  ];
}

OralOp _pickOp(Random rng, Set<OralOp> usable, OralGrade grade) {
  final arithmetic = usable.where((op) => op == OralOp.add || op == OralOp.sub).toList();
  final tables = usable.where((op) => op == OralOp.mul || op == OralOp.div).toList();
  if (tables.isEmpty) return arithmetic[rng.nextInt(arithmetic.length)];
  if (arithmetic.isEmpty) return tables[rng.nextInt(tables.length)];
  final tableBias = grade == OralGrade.three ? 2 : 1;
  if (rng.nextInt(tableBias + 1) < tableBias) {
    return tables[rng.nextInt(tables.length)];
  }
  return arithmetic[rng.nextInt(arithmetic.length)];
}

OralProblem _one(Random rng, OralOp op, OralGrade grade) {
  switch (grade) {
    case OralGrade.one:
      return _arithmetic(rng, op, 20);
    case OralGrade.two:
    case OralGrade.three:
      if (op == OralOp.mul || op == OralOp.div) return _timesTable(rng, op);
      return _arithmetic(rng, op, 100);
    case OralGrade.four:
      if (op == OralOp.mul || op == OralOp.div) return _gradeFour(rng, op);
      return _arithmetic(rng, op, 100);
    case OralGrade.five:
      return _decimal(rng, op);
  }
}

OralProblem _arithmetic(Random rng, OralOp op, int within) {
  final max = within.clamp(1, 100);
  switch (op) {
    case OralOp.add:
      final sum = rng.nextInt(max + 1);
      final a = rng.nextInt(sum + 1);
      return OralProblem(a: a, b: sum - a, op: op);
    case OralOp.sub:
      final a = rng.nextInt(max + 1);
      final b = rng.nextInt(a + 1);
      return OralProblem(a: a, b: b, op: op);
    case OralOp.mul:
    case OralOp.div:
      return _timesTable(rng, op);
  }
}

OralProblem _timesTable(Random rng, OralOp op) {
  switch (op) {
    case OralOp.mul:
      return OralProblem(a: rng.nextInt(9) + 1, b: rng.nextInt(9) + 1, op: op);
    case OralOp.div:
      final divisor = rng.nextInt(9) + 1;
      final quotient = rng.nextInt(9) + 1;
      return OralProblem(a: divisor * quotient, b: divisor, op: op);
    case OralOp.add:
    case OralOp.sub:
      return _arithmetic(rng, op, 20);
  }
}

OralProblem _gradeFour(Random rng, OralOp op) {
  switch (op) {
    case OralOp.mul:
      return OralProblem(a: rng.nextInt(90) + 10, b: rng.nextInt(8) + 2, op: op);
    case OralOp.div:
      final divisor = rng.nextInt(8) + 2;
      final maxQuotient = min(99, 999 ~/ divisor);
      final minQuotient = max(10, (100 / divisor).ceil());
      final quotient = minQuotient + rng.nextInt(maxQuotient - minQuotient + 1);
      return OralProblem(a: divisor * quotient, b: divisor, op: op);
    case OralOp.add:
    case OralOp.sub:
      return _arithmetic(rng, op, 100);
  }
}

OralProblem _decimal(Random rng, OralOp op) {
  switch (op) {
    case OralOp.add:
      final sum = rng.nextInt(100) + 1;
      final a = rng.nextInt(sum + 1);
      return OralProblem(a: a, b: sum - a, op: op, decimal: true);
    case OralOp.sub:
      final a = rng.nextInt(100) + 1;
      final b = rng.nextInt(a + 1);
      return OralProblem(a: a, b: b, op: op, decimal: true);
    case OralOp.mul:
    case OralOp.div:
      return _decimal(rng, OralOp.add);
  }
}
