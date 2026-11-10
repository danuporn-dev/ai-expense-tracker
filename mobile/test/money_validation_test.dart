import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet_ai/core/money.dart';
import 'package:my_wallet_ai/core/ui.dart';
import 'package:my_wallet_ai/screens/transaction_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Nunito', 'NotoSansThai']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await loader.load();
    }
  });
  test('all money forms accept exact cents and reject excess precision', () {
    for (final amount in ['0.01', '1.20', '9999999999.99']) {
      expect(validateMoneyAmount(amount), isNull);
    }
    expect(moneyCents('0.01'), 1);
    expect(moneyCents('9999999999.99'), 999999999999);
    for (final amount in [
      '0.004',
      '1.234',
      '0',
      '-1',
      'NaN',
      'Infinity',
      '1e3',
      '10000000000',
    ]) {
      expect(validateMoneyAmount(amount), isNotNull);
    }
  });
  for (final type in ['income', 'expense']) {
    testWidgets('$type form rejects sub-satang amounts before submitting', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: Scaffold(
            body: TransactionForm(type: type, categories: const []),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField).at(0), 'ทดสอบจำนวนเงิน');
      await tester.enterText(find.byType(TextField).at(1), '0.004');
      await tester.ensureVisible(find.text('บันทึกรายการ'));
      await tester.tap(find.text('บันทึกรายการ'));
      await tester.pumpAndSettle();
      expect(find.text(validateMoneyAmount('0.004')!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
