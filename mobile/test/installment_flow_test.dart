import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_wallet_ai/core/api.dart';
import 'package:my_wallet_ai/core/ui.dart';
import 'package:my_wallet_ai/screens/installment_screen.dart';
import 'package:my_wallet_ai/screens/installment_form.dart';

class InstallmentTestClient extends ApiClient {
  bool paid = false;
  bool failLoad = false;
  int pays = 0;
  Map<String, dynamic>? created;
  Completer<void>? pending;

  Map<String, dynamic> get payment => {
    'id': 1,
    'plan_id': 1,
    'installment_number': 1,
    'due_date': '2026-10-20',
    'amount': '2000.00',
    'status': paid ? 'paid' : 'pending',
    'transaction_id': paid ? 99 : null,
    'paid_date': paid ? '2026-10-13' : null,
    'has_proof': false,
  };
  Map<String, dynamic> get plan => {
    'id': 1,
    'product_name': 'โทรศัพท์มือถือ',
    'price': 2000,
    'down_payment': 0,
    'down_transaction_id': null,
    'installment_count': 1,
    'total_payable': 2000,
    'note': '',
    'category_name': 'ช้อปปิ้ง',
    'paid_count': paid ? 1 : 0,
    'paid_amount': paid ? 2000 : 0,
    'remaining_amount': paid ? 0 : 2000,
    'status': paid ? 'completed' : 'active',
    'next_payment': paid ? null : payment,
    'payments': [payment],
  };
  @override
  Future<Map<String, dynamic>> request(
    String route, {
    String method = 'GET',
    Map<String, String>? query,
    Map<String, dynamic>? data,
  }) async {
    if (route == 'categories')
      return {
        'items': [
          {'id': 1, 'type': 'expense', 'name': 'ช้อปปิ้ง'},
        ],
      };
    if (route == 'transactions') return {'items': []};
    if (route == 'installments/unpay') {
      paid = false;
      return {};
    }
    if (route == 'installments' && method == 'POST') {
      created = data;
      return {'id': 2};
    }
    if (failLoad) throw ApiException('ทดสอบเครือข่ายขัดข้อง');
    return {
      'items': [plan],
      'summary': {
        'remaining': paid ? 0 : 2000,
        'paid': paid ? 2000 : 0,
        'due_this_month': paid ? 0 : 2000,
        'overdue': 0,
        'active_count': paid ? 0 : 1,
      },
    };
  }

  @override
  Future<void> payInstallment(
    int paymentId,
    String paidDate, {
    XFile? proof,
  }) async {
    pays++;
    if (pending != null) await pending!.future;
    paid = true;
  }
}

Future<void> smallScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder field(String label) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.labelText == label,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['Nunito', 'NotoSansThai']) {
      final font = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'));
      await font.load();
    }
  });
  testWidgets(
    'narrow phone payment flow disables duplicate submission and shows completed history',
    (tester) async {
      await smallScreen(tester);
      final client = InstallmentTestClient();
      addTearDown(client.dispose);
      await tester.pumpWidget(
        MaterialApp(theme: appTheme(), home: InstallmentScreen(client: client)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.text('ดูตาราง / บันทึกชำระงวด'));
      await tapVisible(tester, find.text('บันทึกชำระงวด').first);
      client.pending = Completer<void>();
      await tester.tap(find.text('ยืนยันชำระและบันทึกรายจ่าย'));
      await tester.pump();
      final savingButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'กำลังบันทึก...'),
      );
      expect(savingButton.onPressed, isNull);
      expect(client.pays, 1);
      client.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('ผ่อนครบแล้ว'), findsOneWidget);
      expect(find.text('บันทึกชำระงวด'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('ผ่อนครบแล้ว'));
      await tapVisible(tester, find.text('ดูประวัติการชำระ'));
      await tapVisible(tester, find.text('ยกเลิกการบันทึก'));
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();
      expect(client.paid, isFalse);
      expect(find.text('กำลังผ่อน'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creation sends price down payment and monthly schedule from narrow form',
    (tester) async {
      await smallScreen(tester);
      final client = InstallmentTestClient();
      addTearDown(client.dispose);
      await tester.pumpWidget(
        MaterialApp(theme: appTheme(), home: InstallmentForm(client: client)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('ชื่อสินค้า'), 'โทรศัพท์มือถือ');
      await tester.enterText(field('ราคาสินค้า'), '24000');
      await tester.enterText(field('เงินดาวน์'), '4000');
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('สร้างรายการผ่อน'));
      expect(client.created?['price'], '24000');
      expect(client.created?['down_payment'], '4000');
      expect(client.created?['installment_count'], 10);
      expect(client.created?['category_id'], 1);
      expect(client.created?['down_payment_mode'], 'none');
      expect(client.created?.containsKey('monthly_amount'), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading errors retry without losing navigation', (tester) async {
    final client = InstallmentTestClient()..failLoad = true;
    addTearDown(client.dispose);
    await tester.pumpWidget(
      MaterialApp(theme: appTheme(), home: InstallmentScreen(client: client)),
    );
    await tester.pumpAndSettle();
    expect(find.text('ทดสอบเครือข่ายขัดข้อง'), findsOneWidget);
    client.failLoad = false;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();
    expect(find.text('ยอดผ่อนคงเหลือ'), findsOneWidget);
  });
}
