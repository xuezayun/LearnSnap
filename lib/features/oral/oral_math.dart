import 'dart:math';

enum OralOp { add, sub, mul, div }

class OralProblem {
  const OralProblem({required this.a, required this.b, required this.op});

  final int a;
  final int b;
  final OralOp op;

  String get expression => switch (op) {
        OralOp.add => '$a + $b',
        OralOp.sub => '$a − $b',
        OralOp.mul => '$a × $b',
        OralOp.div => '$a ÷ $b',
      };

  String get spoken => switch (op) {
        OralOp.add => '${zhNumber(a)}加${zhNumber(b)}',
        OralOp.sub => '${zhNumber(a)}减${zhNumber(b)}',
        OralOp.mul => '${zhNumber(a)}乘${zhNumber(b)}',
        OralOp.div => '${zhNumber(a)}除以${zhNumber(b)}',
      };
}

const _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

String zhNumber(int n) {
  if (n < 0 || n > 100) return '$n';
  if (n < 10) return _digits[n];
  if (n == 10) return '十';
  if (n < 20) return '十${_digits[n % 10]}';
  if (n == 100) return '一百';
  if (n % 10 == 0) return '${_digits[n ~/ 10]}十';
  return '${_digits[n ~/ 10]}十${_digits[n % 10]}';
}

List<OralProblem> buildOralProblems({
  required Set<OralOp> ops,
  required int within,
  required int count,
  Random? random,
}) {
  final chosen = ops.isEmpty ? {OralOp.add} : ops;
  final rng = random ?? Random();
  final arithmetic = chosen.where((op) => op == OralOp.add || op == OralOp.sub).toList();
  final tables = chosen.where((op) => op == OralOp.mul || op == OralOp.div).toList();
  return [
    for (var i = 0; i < count; i++)
      _one(
        rng,
        arithmetic.isNotEmpty && (tables.isEmpty || rng.nextBool())
            ? arithmetic[rng.nextInt(arithmetic.length)]
            : tables[rng.nextInt(tables.length)],
        within,
      ),
  ];
}

OralProblem _one(Random rng, OralOp op, int within) {
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
      return OralProblem(a: rng.nextInt(9) + 1, b: rng.nextInt(9) + 1, op: op);
    case OralOp.div:
      final divisor = rng.nextInt(9) + 1;
      final quotient = rng.nextInt(9) + 1;
      return OralProblem(a: divisor * quotient, b: divisor, op: op);
  }
}
