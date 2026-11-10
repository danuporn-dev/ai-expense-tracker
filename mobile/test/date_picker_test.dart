import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet_ai/core/ui.dart';

void main() {
  for (final date in [DateTime(2017, 3, 27), DateTime(1899, 12, 31), DateTime(2101, 1, 1)]) {
    testWidgets('date picker opens and preserves $date', (tester) async {
      DateTime? selected;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
        builder: (context) => TextButton(
          onPressed: () async { selected = await pickDay(context, date); },
          child: const Text('Choose date'),
        ),
      ))));
      await tester.tap(find.text('Choose date'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(selected, date);
    });
  }
}
