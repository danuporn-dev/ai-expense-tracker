import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../core/installments.dart';

class InstallmentForm extends StatefulWidget {
  final ApiClient client;
  const InstallmentForm({super.key, required this.client});
  @override
  State<InstallmentForm> createState() => _InstallmentFormState();
}

class _InstallmentFormState extends State<InstallmentForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final price = TextEditingController();
  final down = TextEditingController(text: '0');
  final count = TextEditingController(text: '10');
  final monthly = TextEditingController();
  final note = TextEditingController();
  DateTime firstDue = DateTime.now(), downDate = DateTime.now();
  bool contract = false, saving = false, loading = true;
  String downMode = 'none';
  int? categoryId, existingId;
  String? error;
  List<Map<String, dynamic>> categories = [], expenses = [];

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
      final results = await Future.wait([
        widget.client.request('categories'),
        widget.client.request('transactions', query: {'type': 'expense'}),
      ]);
      if (mounted) {
        setState(() {
          categories =
              List<Map<String, dynamic>>.from(
                results[0]['items'],
              ).where((c) => c['type'] == 'expense').toList();
          expenses =
              List<Map<String, dynamic>>.from(results[1]['items'])
                  .where(
                    (e) =>
                        (e['source'] == 'manual' || e['source'] == 'ai') &&
                        asInt(e['installment_linked']) == 0,
                  )
                  .toList();
          for (final c in categories) {
            if (c['name'] == 'ช้อปปิ้ง') categoryId = asInt(c['id']);
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, price, down, count, monthly, note]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get schedule {
    final p = moneyCents(price.text),
        d = moneyCents(down.text, allowZero: true);
    final n = int.tryParse(count.text);
    final m = contract ? moneyCents(monthly.text) : null;
    if (p == null ||
        d == null ||
        n == null ||
        d >= p ||
        (contract && m == null)) {
      return [];
    }
    return installmentPreview(
      principalCents: p - d,
      count: n,
      firstDue: firstDue,
      contractCents: m,
    );
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (schedule.isEmpty ||
        (schedule.last['due_date'] as DateTime).year > 2100) {
      snack(
        context,
        'ตรวจยอดต่องวด จำนวนงวด และวันครบกำหนดอีกครั้ง',
        error: true,
      );
      return;
    }
    setState(() => saving = true);
    try {
      await widget.client.request(
        'installments',
        method: 'POST',
        data: {
          'product_name': name.text.trim(),
          'price': price.text.trim(),
          'down_payment': down.text.trim(),
          'installment_count': int.parse(count.text),
          'first_due_date': isoDate(firstDue),
          'category_id': categoryId,
          if (contract) 'monthly_amount': monthly.text.trim(),
          'down_payment_mode':
              moneyCents(down.text, allowZero: true) == 0 ? 'none' : downMode,
          'down_payment_date': isoDate(downDate),
          if (downMode == 'existing') 'down_transaction_id': existingId,
          'note': note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget amountField(
    TextEditingController controller,
    String label, {
    bool zero = false,
    String? Function(String?)? validate,
  }) => TextFormField(
    controller: controller,
    enabled: !saving,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: 'บาท'),
    onChanged: (_) => setState(() => existingId = null),
    validator:
        validate ??
        (v) =>
            moneyCents(v ?? '', allowZero: zero) == null
                ? 'กรอกยอดให้ถูกต้อง ไม่เกิน 2 ตำแหน่งทศนิยม'
                : null,
  );

  @override
  Widget build(BuildContext context) {
    final rows = schedule;
    final downCents = moneyCents(down.text, allowZero: true) ?? 0;
    final matching =
        expenses
            .where((e) => (asDouble(e['amount']) * 100).round() == downCents)
            .toList();
    final payable = rows.fold<int>(
      0,
      (s, row) => s + row['amount_cents'] as int,
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('เพิ่มรายการผ่อน')),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? StatusBody(error!, retry: load)
                : Form(
                  key: form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(17, 6, 17, 28),
                    children: [
                      const Text(
                        'ข้อมูลสินค้า',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: name,
                        enabled: !saving,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อสินค้า',
                          hintText: 'เช่น โทรศัพท์มือถือ',
                        ),
                        validator:
                            (v) =>
                                (v ?? '').trim().isEmpty
                                    ? 'กรอกชื่อสินค้า'
                                    : null,
                      ),
                      const SizedBox(height: 10),
                      amountField(price, 'ราคาสินค้า'),
                      const SizedBox(height: 12),
                      amountField(
                        down,
                        'เงินดาวน์',
                        zero: true,
                        validate: (v) {
                          final d = moneyCents(v ?? '', allowZero: true),
                              p = moneyCents(price.text);
                          if (d == null) return 'กรอกเงินดาวน์ให้ถูกต้อง';
                          if (p != null && d >= p) {
                            return 'เงินดาวน์ต้องน้อยกว่าราคาสินค้า';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'หมวดหมู่รายจ่าย',
                        ),
                        items: [
                          for (final c in categories)
                            DropdownMenuItem(
                              value: asInt(c['id']),
                              child: Text('${c['name']}'),
                            ),
                        ],
                        onChanged:
                            saving
                                ? null
                                : (v) => setState(() => categoryId = v),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'เงื่อนไขการผ่อน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: count,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนงวด (รายเดือน)',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          return n == null || n < 1 || n > 360
                              ? 'กรอกจำนวนงวด 1–360'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('ผ่อน 0%')),
                          ButtonSegment(
                            value: true,
                            label: Text('ยอดตามสัญญา'),
                          ),
                        ],
                        selected: {contract},
                        onSelectionChanged:
                            saving
                                ? null
                                : (s) => setState(() => contract = s.first),
                      ),
                      if (contract) ...[
                        const SizedBox(height: 12),
                        amountField(
                          monthly,
                          'ยอดชำระต่องวดตามสัญญา',
                          validate: (v) {
                            final m = moneyCents(v ?? '');
                            if (m == null) return 'กรอกยอดต่องวดให้ถูกต้อง';
                            final p = moneyCents(price.text),
                                d = moneyCents(down.text, allowZero: true),
                                n = int.tryParse(count.text);
                            if (p != null &&
                                d != null &&
                                n != null &&
                                m * n < p - d) {
                              return 'ยอดรวมทุกงวดต้องไม่น้อยกว่ายอดที่ผ่อน';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ใช้ยอดที่รวมดอกเบี้ยหรือค่าธรรมเนียมตามสัญญาแล้ว',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed:
                            saving
                                ? null
                                : () async {
                                  final d = await pickDay(context, firstDue);
                                  if (d != null && mounted) {
                                    setState(() => firstDue = d);
                                  }
                                },
                        icon: const Icon(Icons.event),
                        label: Text('ครบกำหนดงวดแรก ${shortDate(firstDue)}'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'เดือนที่ไม่มีวันที่ 29–31 จะใช้วันสุดท้ายของเดือน',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                      if (downCents > 0) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'บันทึกเงินดาวน์',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: downMode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'วิธีบันทึก',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text(
                                'ติดตามยอดผ่อนอย่างเดียว',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'record',
                              child: Text(
                                'เพิ่มเงินดาวน์เป็นรายจ่ายใหม่',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'existing',
                              child: Text('เชื่อมกับรายจ่ายเดิม'),
                            ),
                          ],
                          onChanged:
                              saving
                                  ? null
                                  : (v) => setState(() {
                                    downMode = v!;
                                    existingId = null;
                                  }),
                        ),
                        if (downMode == 'record') ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                saving
                                    ? null
                                    : () async {
                                      final d = await pickDay(
                                        context,
                                        downDate,
                                      );
                                      if (d != null && mounted) {
                                        setState(() => downDate = d);
                                      }
                                    },
                            icon: const Icon(Icons.event),
                            label: Text(
                              'วันที่จ่ายดาวน์ ${shortDate(downDate)}',
                            ),
                          ),
                        ],
                        if (downMode == 'existing') ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            key: ValueKey('$downCents:$existingId'),
                            initialValue: existingId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'รายจ่ายเดิมที่ยอดตรงกับเงินดาวน์',
                            ),
                            items: [
                              for (final e in matching)
                                DropdownMenuItem(
                                  value: asInt(e['id']),
                                  child: Text(
                                    '${e['title']} · ${e['transaction_date']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged:
                                saving
                                    ? null
                                    : (v) => setState(() => existingId = v),
                            validator:
                                (v) => v == null ? 'เลือกรายจ่ายเดิม' : null,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'เลือกจากรายจ่ายล่าสุด 300 รายการที่ยอดตรงกัน ระบบจะไม่สร้างรายจ่ายซ้ำ',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: note,
                        enabled: !saving,
                        maxLength: 1000,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุ (ถ้ามี)',
                        ),
                      ),
                      if (rows.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'ตรวจสอบก่อนบันทึก',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text('ยอดผ่อนรวม ${money(payable / 100)}'),
                              Text(
                                'งวดละ ${money(rows.first['amount_cents'] / 100)} · ${rows.length} งวด',
                              ),
                              if (rows.first['amount_cents'] !=
                                  rows.last['amount_cents'])
                                Text(
                                  'งวดสุดท้าย ${money(rows.last['amount_cents'] / 100)} (ปรับเศษสตางค์)',
                                ),
                              Text(
                                'งวดสุดท้าย ${shortDate(rows.last['due_date'])}',
                              ),
                              if (contract)
                                Text(
                                  'ดอกเบี้ย / ค่าธรรมเนียมรวม ${money((payable - moneyCents(price.text)! + downCents) / 100)}',
                                ),
                              const SizedBox(height: 8),
                              const Text(
                                'รายจ่ายแต่ละงวดจะบันทึกเมื่อกดยืนยันชำระ',
                                style: TextStyle(color: muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.check),
                        label: Text(
                          saving ? 'กำลังบันทึก...' : 'สร้างรายการผ่อน',
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
