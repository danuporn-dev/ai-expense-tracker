import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet_ai/core/installments.dart';

void main() {
  test('money parsing rejects invalid precision and preserves satang', () {
    expect(moneyCents('2000.01'), 200001);
    expect(moneyCents('0', allowZero: true), 0);
    for (final value in [
      'NaN',
      'Infinity',
      '-1',
      '0',
      '1.001',
      '1e3',
      '10000000000',
    ]) {
      expect(moneyCents(value), isNull);
    }
  });
  test(
    'monthly schedule restores anchor day after February and preserves principal',
    () {
      final rows = installmentPreview(
        principalCents: 10000,
        count: 3,
        firstDue: DateTime(2028, 1, 31),
      );
      expect(rows.map((r) => r['due_date']).toList(), [
        DateTime(2028, 1, 31),
        DateTime(2028, 2, 29),
        DateTime(2028, 3, 31),
      ]);
      expect(rows.map((r) => r['amount_cents']).toList(), [3333, 3333, 3334]);
    },
  );
  test(
    'contract charges are included and insufficient contract is rejected',
    () {
      final rows = installmentPreview(
        principalCents: 10000,
        count: 3,
        firstDue: DateTime(2027, 1, 31),
        contractCents: 3500,
      );
      expect(rows.map((r) => r['amount_cents']).toList(), [3500, 3500, 3500]);
      expect(
        installmentPreview(
          principalCents: 10000,
          count: 3,
          firstDue: DateTime(2027),
          contractCents: 3000,
        ),
        isEmpty,
      );
    },
  );
}
