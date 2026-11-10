import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/ui.dart';
import 'transaction_screen.dart';

class ReceiptScreen extends StatefulWidget {
  final VoidCallback onSaved;
  final ApiClient? client;
  final ImagePicker? imagePicker;
  const ReceiptScreen({
    super.key,
    required this.onSaved,
    this.client,
    this.imagePicker,
  });
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  XFile? picture;
  Map<String, dynamic>? result;
  List<dynamic> categories = [];
  int? receiptId;
  bool busy = false;
  bool confirming = false;
  ApiClient get client => widget.client ?? api;
  Future<void> choose(ImageSource source) async {
    if (busy || confirming) return;
    try {
      final picked = await (widget.imagePicker ?? ImagePicker()).pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (picked != null && mounted)
        setState(() {
          picture = picked;
          result = null;
          receiptId = null;
        });
    } catch (e) {
      if (mounted)
        snack(context, 'เปิดกล้องหรือแกลเลอรีไม่ได้: $e', error: true);
    }
  }

  Future<void> scan() async {
    if (picture == null || busy || confirming) return;
    setState(() {
      busy = true;
      result = null;
      receiptId = null;
    });
    try {
      final responses = await Future.wait([
        client.scanReceipt(picture!),
        client.request('categories'),
      ]);
      if (mounted)
        setState(() {
          result = Map<String, dynamic>.from(responses[0]['data']);
          receiptId = asInt(responses[0]['receipt_id']);
          categories =
              (responses[1]['items'] as List)
                  .where((c) => c['type'] == 'expense')
                  .toList();
        });
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirm() async {
    if (result == null || busy || confirming) return;
    setState(() => confirming = true);
    try {
      final response = await client.request('categories');
      if (!mounted) return;
      categories =
          (response['items'] as List)
              .where((c) => c['type'] == 'expense')
              .toList();
      final success = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder:
            (_) => TransactionForm(
              type: 'expense',
              categories: categories,
              aiData: result,
              receiptId: receiptId,
            ),
      );
      if (success == true && mounted) {
        snack(context, 'บันทึกค่าใช้จ่ายจากบิลแล้ว');
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) snack(context, 'เปิดฟอร์มบันทึกไม่ได้: $e', error: true);
    } finally {
      if (mounted) setState(() => confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 26),
    children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [softPink, peach],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI RECEIPT SCANNER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                color: primary,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เปลี่ยนบิล\nเป็นรายจ่าย',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: navy,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'รูปเดียว จดครบทุกอย่าง',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: .12,
                  child: Container(
                    width: 80,
                    height: 98,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: .1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.document_scanner_rounded,
                          size: 31,
                          color: primary,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: softPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 5,
                          width: 30,
                          decoration: BoxDecoration(
                            color: line,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        busy || confirming
                            ? null
                            : () => choose(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูป'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        busy || confirming
                            ? null
                            : () => choose(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('เลือกรูป'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (picture != null)
        Panel(
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 18, color: primary),
                  SizedBox(width: 8),
                  Text(
                    'บิลของคุณ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder(
                  future: picture!.readAsBytes(),
                  builder:
                      (context, snapshot) =>
                          snapshot.hasData
                              ? Image.memory(
                                snapshot.data!,
                                height: 240,
                                fit: BoxFit.contain,
                              )
                              : const SizedBox(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy || confirming ? null : scan,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(busy ? 'กำลังอ่านบิล...' : 'ให้ AI วิเคราะห์บิล'),
                ),
              ),
            ],
          ),
        ),
      if (result != null) ...[
        const SizedBox(height: 16),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ข้อมูลที่ AI อ่านได้',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _row('ร้านค้า', '${result!['merchant']}'),
              _row('วันที่', '${result!['date']}'),
              _row('ยอดรวม', money(result!['total'])),
              _row('หมวดหมู่', '${result!['category']}'),
              if (result!['items'] is List &&
                  (result!['items'] as List).isNotEmpty) ...[
                const Divider(height: 25),
                const Text(
                  'รายการสินค้า',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                for (final x in (result!['items'] as List).take(12))
                  _row('${x['name']}', money(x['amount'])),
              ],
              const SizedBox(height: 13),
              const Text(
                'ตรวจสอบความถูกต้อง แล้วบันทึกได้เลย',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy || confirming ? null : confirm,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    confirming
                        ? 'กำลังเปิดฟอร์ม...'
                        : 'ตรวจสอบ / บันทึกรายจ่าย',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 15),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: muted),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'AI ช่วยอ่านข้อมูล คุณตรวจและแก้ไขได้ก่อนบันทึก',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        ],
      ),
    ],
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: muted))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
