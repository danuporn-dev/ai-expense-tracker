import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../core/receipt_category.dart';
import '../core/money.dart';
import 'installment_detail_screen.dart';

class TransactionScreen extends StatefulWidget {
  final String type;
  const TransactionScreen({super.key, required this.type});
  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  DateTime month = DateTime.now();
  List<dynamic> items = [], categories = [];
  double total = 0;
  int count = 0;
  bool loading = true;
  String? error;
  bool get income => widget.type == 'income';
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
        api.request(
          'transactions',
          query: {'type': widget.type, 'month': monthKey(month)},
        ),
        api.request('categories'),
      ]);
      if (mounted)
        setState(() {
          items = results[0]['items'];
          total = asDouble(results[0]['total']);
          count = asInt(results[0]['count']);
          categories =
              (results[1]['items'] as List)
                  .where((x) => x['type'] == widget.type)
                  .toList();
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openForm([Map<String, dynamic>? item]) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => TransactionForm(
            type: widget.type,
            categories: categories,
            initial: item,
          ),
    );
    if (changed == true) load();
  }

  Future<void> remove(int id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ยืนยันการลบ'),
            content: const Text('ลบรายการนี้หรือไม่?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ลบ'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    try {
      await api.request('transactions', method: 'DELETE', query: {'id': '$id'});
      if (mounted) snack(context, 'ลบรายการแล้ว');
      load();
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Column(
        children: [
          MonthSwitcher(
            date: month,
            onChanged: (d) {
              month = d;
              load();
            },
          ),
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                    ? StatusBody(error!, retry: load)
                    : RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(15, 3, 15, 95),
                        children: [
                          SummaryTile(
                            title:
                                income ? 'รายรับเดือนนี้' : 'รายจ่ายเดือนนี้',
                            amount: money(total),
                            color: income ? mint : coral,
                            icon:
                                income
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                          ),
                          const SizedBox(height: 15),
                          if (count > items.length)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'แสดง ${items.length} รายการล่าสุดจาก $count รายการ ยอดรวมรวมทุกรายการ',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (items.isEmpty)
                            EmptyState(
                              icon:
                                  income
                                      ? Icons.savings_outlined
                                      : Icons.receipt_long_outlined,
                              title:
                                  income
                                      ? 'เริ่มจดรายรับของคุณ'
                                      : 'เดือนนี้ยังไม่มีรายจ่าย',
                              subtitle:
                                  income
                                      ? 'กดเพิ่มรายรับ เพื่อดูเงินที่เข้ามาในเดือนนี้'
                                      : 'เพิ่มรายจ่ายหรือสแกนบิล แล้วให้เราช่วยจด',
                            )
                          else
                            Panel(
                              child: Column(
                                children: [
                                  for (final item in items)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            income
                                                ? const Color(0xFFE7F4ED)
                                                : softPink,
                                        child: Icon(
                                          catIcon(
                                            '${item['category_name'] ?? ''}',
                                          ),
                                          color: income ? mint : coral,
                                        ),
                                      ),
                                      title: Text(
                                        '${item['title']}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${item['transaction_date']} · ${item['category_name'] ?? 'อื่น ๆ'}${item['receipt_id'] != null ? ' · 📷' : ''}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            money(item['amount']),
                                            style: TextStyle(
                                              color: income ? mint : coral,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (v) async {
                                              if (v == 'installment') {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (
                                                          _,
                                                        ) => InstallmentDetailScreen(
                                                          planId: asInt(
                                                            item['installment_plan_id'],
                                                          ),
                                                          client: api,
                                                        ),
                                                  ),
                                                );
                                                if (mounted) load();
                                              }
                                              if (v == 'edit')
                                                openForm(
                                                  Map<String, dynamic>.from(
                                                    item,
                                                  ),
                                                );
                                              if (v == 'delete')
                                                remove(asInt(item['id']));
                                              if (v == 'image')
                                                previewReceipt(
                                                  asInt(item['receipt_id']),
                                                );
                                            },
                                            itemBuilder:
                                                (_) => [
                                                  if (item['installment_plan_id'] !=
                                                      null)
                                                    const PopupMenuItem(
                                                      value: 'installment',
                                                      child: Text(
                                                        'ดูรายการผ่อน',
                                                      ),
                                                    ),
                                                  if (item['source'] !=
                                                          'subscription' &&
                                                      item['source'] !=
                                                          'installment' &&
                                                      asInt(
                                                            item['installment_linked'],
                                                          ) ==
                                                          0)
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Text('แก้ไข'),
                                                    ),
                                                  if (item['source'] !=
                                                          'subscription' &&
                                                      item['source'] !=
                                                          'installment' &&
                                                      asInt(
                                                            item['installment_linked'],
                                                          ) ==
                                                          0)
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Text('ลบ'),
                                                    ),
                                                  if (item['receipt_id'] !=
                                                      null)
                                                    const PopupMenuItem(
                                                      value: 'image',
                                                      child: Text('ดูรูปบิล'),
                                                    ),
                                                ],
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      Positioned(
        right: 18,
        bottom: 20,
        child: FloatingActionButton.extended(
          onPressed: () => openForm(),
          icon: const Icon(Icons.add),
          label: Text(income ? 'เพิ่มรายรับ' : 'เพิ่มรายจ่าย'),
        ),
      ),
    ],
  );

  Future<void> previewReceipt(int id) async {
    try {
      final bytes = await api.receiptImage(id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (_) => Dialog(child: InteractiveViewer(child: Image.memory(bytes))),
      );
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }
}

class TransactionForm extends StatefulWidget {
  final String type;
  final List<dynamic> categories;
  final Map<String, dynamic>? initial;
  final int? receiptId;
  final Map<String, dynamic>? aiData;
  const TransactionForm({
    super.key,
    required this.type,
    required this.categories,
    this.initial,
    this.receiptId,
    this.aiData,
  });
  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      amount = TextEditingController(),
      note = TextEditingController();
  int? categoryId;
  DateTime date = DateTime.now();
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final b = widget.initial ?? widget.aiData ?? {};
    title.text = '${b['title'] ?? b['merchant'] ?? ''}';
    amount.text = '${b['amount'] ?? b['total'] ?? ''}';
    note.text = '${b['note'] ?? ''}';
    final dateString = b['transaction_date'] ?? b['date'];
    date = DateTime.tryParse('$dateString') ?? DateTime.now();
    if (b['category_id'] != null)
      categoryId = asInt(b['category_id']);
    else if (widget.aiData != null) {
      categoryId = receiptCategoryId(widget.categories, b['category']);
    }
    if (widget.aiData == null) {
      categoryId ??=
          widget.categories.isEmpty
              ? null
              : asInt(widget.categories.first['id']);
    }
  }

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await api.request(
        'transactions',
        method: widget.initial == null ? 'POST' : 'PUT',
        query:
            widget.initial == null ? null : {'id': '${widget.initial!['id']}'},
        data: {
          'type': widget.type,
          'title': title.text.trim(),
          'amount': amount.text.trim(),
          'transaction_date': isoDate(date),
          'category_id': categoryId,
          'note': note.text.trim(),
          if (widget.receiptId != null) 'receipt_id': widget.receiptId,
        },
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      12,
      20,
      MediaQuery.of(context).viewInsets.bottom + 25,
    ),
    child: SafeArea(
      child: Form(
        key: form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.initial == null
                    ? 'เพิ่ม${widget.type == 'income' ? 'รายรับ' : 'รายจ่าย'}'
                    : 'แก้ไขรายการ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
                validator:
                    (s) => (s ?? '').trim().isEmpty ? 'กรอกชื่อรายการ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'จำนวนเงิน (บาท)',
                  prefixText: '฿ ',
                ),
                validator: validateMoneyAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: categoryId,
                decoration: InputDecoration(
                  labelText: 'หมวดหมู่',
                  helperText:
                      widget.aiData != null
                          ? 'เลือกตามผล AI อัตโนมัติ เปลี่ยนได้ก่อนบันทึก'
                          : null,
                ),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(
                      value: asInt(c['id']),
                      child: Text('${c['name']}'),
                    ),
                ],
                onChanged: (v) => setState(() => categoryId = v),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await pickDay(context, date);
                  if (d != null) setState(() => date = d);
                },
                icon: const Icon(Icons.date_range),
                label: Text(shortDate(date)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: note,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุ (ไม่บังคับ)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(busy ? 'กำลังบันทึก...' : 'บันทึกรายการ'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
