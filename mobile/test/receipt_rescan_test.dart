import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_wallet_ai/core/api.dart';
import 'package:my_wallet_ai/screens/receipt_screen.dart';

class TestPicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({required ImageSource source, double? maxWidth,
    double? maxHeight, int? imageQuality, CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true}) async => XFile.fromData(
      base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1sAAAAASUVORK5CYII='),
      name: 'receipt.png', mimeType: 'image/png');
}

class TestReceiptClient extends ApiClient {
  int scans = 0;
  final pending = Completer<Map<String,dynamic>>();
  @override
  Future<Map<String,dynamic>> scanReceipt(XFile picture) async {
    scans++;
    if (scans > 1) return pending.future;
    return result(1, 'Original merchant');
  }
  static Map<String,dynamic> result(int id, String merchant) => {
    'receipt_id': id, 'data': {'merchant': merchant, 'date': '2026-10-12',
      'total': 100, 'category': 'อาหาร', 'items': []},
  };
  @override
  Future<Map<String,dynamic>> request(String route, {String method='GET',
    Map<String,String>? query, Map<String,dynamic>? data}) async => {
      'items': [{'id': 1, 'type': 'expense', 'name': 'อาหาร'}],
  };
}

void main() {
  for (final fails in [false, true]) {
    testWidgets('rescan hides previous result, failure=$fails', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = TestReceiptClient();
      addTearDown(client.dispose);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: ReceiptScreen(
        onSaved: () {}, client: client, imagePicker: TestPicker(),
      ))));
      await tester.tap(find.text('เลือกรูป'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('ให้ AI วิเคราะห์บิล'));
      await tester.tap(find.text('ให้ AI วิเคราะห์บิล'));
      await tester.pumpAndSettle();
      expect(find.text('Original merchant'), findsOneWidget);
      expect(find.text('ตรวจสอบ / บันทึกรายจ่าย'), findsOneWidget);
      await tester.ensureVisible(find.text('ให้ AI วิเคราะห์บิล'));
      await tester.tap(find.text('ให้ AI วิเคราะห์บิล'));
      await tester.pump();
      expect(find.text('Original merchant'), findsNothing);
      expect(find.text('ตรวจสอบ / บันทึกรายจ่าย'), findsNothing);
      expect(find.text('กำลังอ่านบิล...'), findsOneWidget);
      if (fails) {
        client.pending.completeError(ApiException('Test scan failure'));
      } else {
        client.pending.complete(TestReceiptClient.result(2, 'New merchant'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Original merchant'), findsNothing);
      expect(find.text('ตรวจสอบ / บันทึกรายจ่าย'), fails ? findsNothing : findsOneWidget);
      expect(find.text('New merchant'), fails ? findsNothing : findsOneWidget);
    });
  }
}
