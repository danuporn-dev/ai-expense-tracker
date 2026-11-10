import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../widgets/installment_card.dart';
import 'installment_form.dart';
import 'installment_detail_screen.dart';

class InstallmentScreen extends StatefulWidget {
  final ApiClient? client;
  const InstallmentScreen({super.key, this.client});
  @override
  State<InstallmentScreen> createState() => _InstallmentScreenState();
}

class _InstallmentScreenState extends State<InstallmentScreen> {
  ApiClient get client => widget.client ?? api;
  List<Map<String, dynamic>> plans = [];
  Map<String, dynamic> summary = {};
  bool loading = true, completed = false;
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
      final result = await client.request('installments');
      if (mounted) {
        setState(() {
          plans = List<Map<String, dynamic>>.from(result['items']);
          summary = Map<String, dynamic>.from(result['summary']);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> add() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => InstallmentForm(client: client)),
    );
    if (mounted && saved == true) {
      snack(context, 'เพิ่มรายการผ่อนแล้ว');
      load();
    }
  }

  Future<void> open(Map<String, dynamic> plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => InstallmentDetailScreen(
              planId: asInt(plan['id']),
              client: client,
            ),
      ),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) {
    final visible =
        plans.where((p) => (p['status'] == 'completed') == completed).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ผ่อนสินค้า'),
        actions: [
          IconButton(
            tooltip: 'เพิ่มรายการผ่อน',
            onPressed: add,
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? StatusBody(error!, retry: load)
              : RefreshIndicator(
                onRefresh: load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(17, 6, 17, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDCE7), Color(0xFFFFEDDE)],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ยอดผ่อนคงเหลือ',
                                  style: TextStyle(color: muted),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    money(summary['remaining']),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'กำลังผ่อน ${asInt(summary['active_count'])} รายการ',
                                  style: const TextStyle(color: muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.shopping_bag_rounded,
                            color: rose,
                            size: 72,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SummaryTile(
                            title: 'จ่ายแล้ว (เฉพาะงวด)',
                            amount: money(summary['paid']),
                            color: mint,
                            icon: Icons.check_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SummaryTile(
                            title: 'เดือนนี้ต้องจ่าย',
                            amount: money(summary['due_this_month']),
                            color: primary,
                            icon: Icons.calendar_month_outlined,
                          ),
                        ),
                      ],
                    ),
                    if (asDouble(summary['overdue']) > 0) ...[
                      const SizedBox(height: 12),
                      Panel(
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: coral),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'เลยกำหนดชำระ ${money(summary['overdue'])}',
                                style: const TextStyle(color: coral),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('กำลังผ่อน')),
                        ButtonSegment(value: true, label: Text('ผ่อนครบแล้ว')),
                      ],
                      selected: {completed},
                      onSelectionChanged:
                          (s) => setState(() => completed = s.first),
                    ),
                    const SizedBox(height: 16),
                    if (visible.isEmpty)
                      EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title:
                            completed
                                ? 'ยังไม่มีรายการที่ผ่อนครบ'
                                : 'เริ่มติดตามรายการผ่อน',
                        subtitle:
                            completed
                                ? 'รายการที่ชำระครบทุกงวดจะแสดงที่นี่'
                                : 'เพิ่มสินค้า เพื่อดูยอดคงเหลือและกำหนดชำระแต่ละงวด',
                      ),
                    for (final plan in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InstallmentCard(
                          plan: plan,
                          onOpen: () => open(plan),
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: add,
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มรายการผ่อน'),
                    ),
                  ],
                ),
              ),
    );
  }
}
