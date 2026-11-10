import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../widgets/installment_card.dart';

class InstallmentDetailScreen extends StatefulWidget {
  final int planId;
  final ApiClient client;
  const InstallmentDetailScreen({
    super.key,
    required this.planId,
    required this.client,
  });
  @override
  State<InstallmentDetailScreen> createState() =>
      _InstallmentDetailScreenState();
}

class _InstallmentDetailScreenState extends State<InstallmentDetailScreen> {
  Map<String, dynamic>? plan;
  bool loading = true, busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await widget.client.request(
        'installments',
        query: {'id': '${widget.planId}'},
      );
      if (mounted) {
        setState(
          () =>
              plan = Map<String, dynamic>.from(
                (result['items'] as List).single,
              ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pay(Map<String, dynamic> row) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => _PaymentForm(
            client: widget.client,
            payment: row,
            productName: '${plan!['product_name']}',
          ),
    );
    if (saved == true && mounted) {
      snack(context, 'บันทึกชำระและเพิ่มรายจ่ายแล้ว');
      load();
    }
  }

  Future<void> undo(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('ยกเลิกการบันทึกงวด ${row['installment_number']}?'),
            content: const Text(
              'รายจ่ายและหลักฐานของงวดนี้จะถูกนำออก และงวดจะกลับเป็นรอชำระ',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('กลับ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ยืนยันยกเลิก'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.client.request(
        'installments/unpay',
        method: 'POST',
        data: {'payment_id': asInt(row['id'])},
      );
      if (mounted) {
        snack(context, 'ยกเลิกการบันทึกแล้ว');
        await load();
      }
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> proof(Map<String, dynamic> row) async {
    setState(() => busy = true);
    try {
      final bytes = await widget.client.installmentProof(asInt(row['id']));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder:
            (context) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InteractiveViewer(child: Image.memory(bytes)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ปิด'),
                  ),
                ],
              ),
            ),
      );
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> remove() async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ลบรายการผ่อนนี้?'),
            content: const Text(
              'รายการนี้ยังไม่มีประวัติการชำระ ตารางงวดจะถูกลบด้วย',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('กลับ'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ลบรายการ'),
              ),
            ],
          ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      await widget.client.request(
        'installments',
        method: 'DELETE',
        query: {'id': '${widget.planId}'},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการผ่อน'),
        actions: [
          if (plan != null &&
              asInt(plan!['paid_count']) == 0 &&
              plan!['down_transaction_id'] == null)
            IconButton(
              tooltip: 'ลบรายการผ่อน',
              onPressed: busy ? null : remove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? StatusBody(error!, retry: load)
              : RefreshIndicator(
                onRefresh: busy ? () async {} : load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(17, 6, 17, 28),
                  children: [
                    InstallmentCard(
                      plan: plan!,
                      detail: true,
                      onOpen:
                          busy
                              ? null
                              : () {
                                final next = plan!['next_payment'];
                                if (next != null) {
                                  pay(Map<String, dynamic>.from(next));
                                }
                              },
                    ),
                    const SizedBox(height: 14),
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ราคาสินค้า ${money(plan!['price'])}'),
                          Text('เงินดาวน์ ${money(plan!['down_payment'])}'),
                          if (asDouble(plan!['down_payment']) > 0)
                            Text(
                              plan!['down_transaction_id'] == null
                                  ? 'เงินดาวน์ยังไม่ได้เชื่อมรายจ่าย'
                                  : 'เชื่อมรายจ่ายเงินดาวน์แล้ว',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          Text('ยอดผ่อนรวม ${money(plan!['total_payable'])}'),
                          Text(
                            'ดอกเบี้ย / ค่าธรรมเนียมรวม ${money(asDouble(plan!['total_payable']) - asDouble(plan!['price']) + asDouble(plan!['down_payment']))}',
                          ),
                          Text(
                            'หมวดหมู่ ${plan!['category_name'] ?? 'ไม่ระบุ'}',
                          ),
                          if ('${plan!['note']}'.isNotEmpty)
                            Text('หมายเหตุ: ${plan!['note']}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'ตารางชำระรายเดือน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final raw in plan!['payments']) ...[
                      _paymentCard(Map<String, dynamic>.from(raw)),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
    ),
  );

  Widget _paymentCard(Map<String, dynamic> row) {
    final paid = row['status'] == 'paid', overdue = row['status'] == 'overdue';
    final color =
        paid
            ? mint
            : overdue
            ? coral
            : primary;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: .1),
                child:
                    paid
                        ? const Icon(Icons.check, color: mint)
                        : Text(
                          '${row['installment_number']}',
                          style: TextStyle(color: color),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'งวดที่ ${row['installment_number']} · ${money(row['amount'])}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'ครบกำหนด ${shortDate(DateTime.parse(row['due_date']))}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    Text(
                      paid
                          ? 'ชำระแล้ว ${shortDate(DateTime.parse(row['paid_date']))}'
                          : overdue
                          ? 'เลยกำหนด'
                          : 'รอชำระ',
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!paid)
            OutlinedButton(
              onPressed: busy ? null : () => pay(row),
              child: const Text('บันทึกชำระงวด'),
            ),
          if (paid)
            Wrap(
              spacing: 8,
              children: [
                if (row['has_proof'] == true)
                  TextButton.icon(
                    onPressed: busy ? null : () => proof(row),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('ดูหลักฐาน'),
                  ),
                TextButton(
                  onPressed: busy ? null : () => undo(row),
                  child: const Text(
                    'ยกเลิกการบันทึก',
                    style: TextStyle(color: muted),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PaymentForm extends StatefulWidget {
  final ApiClient client;
  final Map<String, dynamic> payment;
  final String productName;
  const _PaymentForm({
    required this.client,
    required this.payment,
    required this.productName,
  });
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  DateTime date = DateUtils.dateOnly(DateTime.now());
  XFile? image;
  bool saving = false;

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await widget.client.payInstallment(
        asInt(widget.payment['id']),
        isoDate(date),
        proof: image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ชำระงวดที่ ${widget.payment['installment_number']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(widget.productName, style: const TextStyle(color: muted)),
              const SizedBox(height: 14),
              Text(
                money(widget.payment['amount']),
                style: const TextStyle(
                  fontSize: 30,
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed:
                    saving
                        ? null
                        : () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(1900),
                            lastDate: DateUtils.dateOnly(DateTime.now()),
                          );
                          if (d != null && mounted) setState(() => date = d);
                        },
                icon: const Icon(Icons.event),
                label: Text('วันที่ชำระ ${shortDate(date)}'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed:
                    saving
                        ? null
                        : () async {
                          try {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1600,
                              imageQuality: 85,
                            );
                            if (picked == null) return;
                            if (await picked.length() > 2 * 1024 * 1024) {
                              throw ApiException('หลักฐานต้องไม่เกิน 2 MB');
                            }
                            if (mounted) setState(() => image = picked);
                          } catch (e) {
                            if (context.mounted) {
                              snack(context, '$e', error: true);
                            }
                          }
                        },
                icon: const Icon(Icons.attach_file),
                label: Text(
                  image == null ? 'แนบหลักฐาน (ถ้ามี)' : 'เปลี่ยนหลักฐาน',
                ),
              ),
              if (image != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(image!.name, overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      onPressed:
                          saving ? null : () => setState(() => image = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Text(
                'ยืนยันแล้วจะเพิ่มรายจ่ายตามยอดและวันที่ชำระนี้',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(
                  saving ? 'กำลังบันทึก...' : 'ยืนยันชำระและบันทึกรายจ่าย',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
