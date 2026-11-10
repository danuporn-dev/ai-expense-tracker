import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../core/money.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime month = DateTime.now();
  List<dynamic> budgets = [], categories = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        api.request('budgets', query: {'month': monthKey(month)}),
        api.request('categories'),
      ]);
      if (mounted)
        setState(() {
          budgets = results[0]['items'];
          categories =
              (results[1]['items'] as List)
                  .where((x) => x['type'] == 'expense')
                  .toList();
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> add() async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder:
          (_) => _BudgetForm(month: monthKey(month), categories: categories),
    );
    if (success == true) load();
  }

  Future<void> delete(int id) async {
    try {
      await api.request('budgets', method: 'DELETE', query: {'id': '$id'});
      load();
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('วางแผนงบประมาณ')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: add,
      icon: const Icon(Icons.add),
      label: const Text('ตั้งงบ'),
    ),
    body: Column(
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
              busy
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? StatusBody(error!, retry: load)
                  : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                    children: [
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'วางแผนวันนี้ สบายใจทั้งเดือน',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              'เลือกงบรวมทั้งเดือนหรือกำหนดงบแต่ละหมวด เมื่อเพิ่มรายจ่ายยอดจะอัปเดตโดยอัตโนมัติ',
                              style: TextStyle(color: muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (budgets.isEmpty)
                        const EmptyState(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'เริ่มจากงบเล็ก ๆ',
                          subtitle:
                              'ตั้งงบของเดือนนี้ เพื่อเห็นว่าใช้ไปและเหลืออีกเท่าไร',
                        )
                      else
                        for (final b in budgets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BudgetCard(
                              item: Map<String, dynamic>.from(b),
                              onDelete: () => delete(asInt(b['id'])),
                            ),
                          ),
                    ],
                  ),
        ),
      ],
    ),
  );
}

class _BudgetCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  const _BudgetCard({required this.item, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final used = asDouble(item['spent']), limit = asDouble(item['amount']);
    final pct = used / math.max(1, limit);
    final color =
        pct >= 1
            ? coral
            : pct >= .8
            ? const Color(0xFFD78A37)
            : primary;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item['category_id'] == null
                    ? Icons.account_balance_wallet
                    : catIcon('${item['category_name']}'),
                color: color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item['category_id'] == null
                      ? 'งบรวมทั้งเดือน'
                      : '${item['category_name']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'ลบงบ',
              ),
            ],
          ),
          Text('${money(used)} / ${money(limit)}'),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: math.min(1, pct),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
            color: color,
            backgroundColor: softPink,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ใช้ไป ${(pct * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                pct >= 1
                    ? 'เกินงบ ${money(used - limit)}'
                    : 'เหลือ ${money(limit - used)}',
                style: const TextStyle(color: muted),
              ),
            ],
          ),
          if (pct >= .8)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                pct >= 1
                    ? 'แจ้งเตือน: คุณใช้ครบหรือเกินงบนี้แล้ว'
                    : pct >= .9
                    ? 'แจ้งเตือน: ใช้งบไปแล้วกว่า 90%'
                    : 'แจ้งเตือน: ใช้งบไปแล้วกว่า 80%',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetForm extends StatefulWidget {
  final String month;
  final List<dynamic> categories;
  const _BudgetForm({required this.month, required this.categories});
  @override
  State<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<_BudgetForm> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController();
  int cat = 0;
  bool saving = false;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await api.request(
        'budgets',
        method: 'POST',
        data: {
          'month': widget.month,
          'category_id': cat == 0 ? null : cat,
          'amount': amount.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
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
                'ตั้งงบเดือน ${widget.month}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: cat,
                decoration: const InputDecoration(labelText: 'หมวดงบประมาณ'),
                items: [
                  const DropdownMenuItem<int>(
                    value: 0,
                    child: Text('งบรวมทั้งเดือน'),
                  ),
                  for (final c in widget.categories)
                    DropdownMenuItem<int>(
                      value: asInt(c['id']),
                      child: Text('${c['name']}'),
                    ),
                ],
                onChanged: (v) => setState(() => cat = v ?? 0),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'วงเงินที่ต้องการ (บาท)',
                ),
                validator: validateMoneyAmount,
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: saving ? null : save,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(saving ? 'กำลังบันทึก...' : 'บันทึกงบประมาณ'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
