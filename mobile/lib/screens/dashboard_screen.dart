import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import 'budget_screen.dart';
import 'installment_screen.dart';
import '../widgets/wallet_art.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenTransactions;
  final VoidCallback onScan;
  const DashboardScreen({
    super.key,
    required this.onOpenTransactions,
    required this.onScan,
  });
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String period = 'month';
  DateTime date = DateTime.now();
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;
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
      final res = await api.request(
        'dashboard',
        query: {'period': period, 'date': isoDate(date)},
      );
      if (mounted) setState(() => data = res);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void changePeriod(String p) {
    setState(() => period = p);
    load();
  }

  @override
  Widget build(BuildContext context) =>
      loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? StatusBody(error!, retry: load)
          : RefreshIndicator(
            onRefresh: load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(17, 8, 17, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFDCE7), Color(0xFFFFEDDE)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .65),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'MY BALANCE',
                              style: TextStyle(
                                color: primary,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 20,
                            color: primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'สวัสดี ${api.user?['name'] ?? ''}',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                const Text(
                                  'ยอดคงเหลือตามช่วงเวลา',
                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    money(data!['balance']),
                                    style: const TextStyle(
                                      color: navy,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const WalletArt(size: 98),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'จัดการทีละนิด เพื่อชีวิตที่ลงตัว',
                        style: TextStyle(color: muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'day', label: Text('วัน')),
                    ButtonSegment(value: 'month', label: Text('เดือน')),
                    ButtonSegment(value: 'year', label: Text('ปี')),
                  ],
                  selected: {period},
                  onSelectionChanged:
                      (selected) => changePeriod(selected.first),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SummaryTile(
                        title: 'รายรับ',
                        amount: money(data!['income']),
                        color: mint,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryTile(
                        title: 'รายจ่าย',
                        amount: money(data!['expense']),
                        color: coral,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        title: 'สแกนบิล',
                        subtitle: 'ให้ AI ช่วยจดรายจ่าย',
                        icon: Icons.document_scanner_outlined,
                        color: primary,
                        onTap: widget.onScan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        title: 'ตั้งงบประมาณ',
                        subtitle: 'วางแผนให้พอดี',
                        icon: Icons.pie_chart_outline_rounded,
                        color: const Color(0xFFAC7846),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BudgetScreen(),
                            ),
                          );
                          if (mounted) load();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _QuickAction(
                  title: 'ผ่อนสินค้า',
                  subtitle: 'ดูยอดคงเหลือ ตารางงวด และบันทึกชำระ',
                  icon: Icons.shopping_bag_outlined,
                  color: primary,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InstallmentScreen(),
                      ),
                    );
                    if (mounted) load();
                  },
                ),
                const SizedBox(height: 22),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'แนวโน้มรายรับ–รายจ่าย',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        period == 'day'
                            ? 'ย้อนหลัง 7 วัน'
                            : period == 'month'
                            ? 'รายวันในเดือนปัจจุบัน'
                            : 'รายเดือนในปีปัจจุบัน',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const CircleAvatar(radius: 5, backgroundColor: mint),
                          const SizedBox(width: 5),
                          const Text('รายรับ', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 15),
                          const CircleAvatar(radius: 5, backgroundColor: coral),
                          const SizedBox(width: 5),
                          const Text('รายจ่าย', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TinyBarChart(
                        items: List<Map<String, dynamic>>.from(
                          data!['chart'] ?? [],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'งบประมาณรายเดือน',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BudgetScreen(),
                                ),
                              );
                              if (mounted) load();
                            },
                            child: const Text('จัดการงบ >'),
                          ),
                        ],
                      ),
                      if (data!['budget'] == null)
                        const Text(
                          'ยังไม่ตั้งงบรวม กดจัดการงบเพื่อเริ่มต้น',
                          style: TextStyle(color: muted),
                        )
                      else ...[
                        Text(
                          '${money(data!['budget']['spent'])} / ${money(data!['budget']['amount'])}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                          value: math.min(
                            1,
                            asDouble(data!['budget']['spent']) /
                                math.max(
                                  1,
                                  asDouble(data!['budget']['amount']),
                                ),
                          ),
                          color:
                              asDouble(data!['budget']['spent']) >=
                                      asDouble(data!['budget']['amount'])
                                  ? coral
                                  : primary,
                          backgroundColor: softPink,
                          minHeight: 9,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          asDouble(data!['budget']['spent']) >=
                                  asDouble(data!['budget']['amount'])
                              ? 'ใช้ครบหรือเกินงบแล้ว'
                              : 'เหลือ ${money(asDouble(data!['budget']['amount']) - asDouble(data!['budget']['spent']))}',
                          style: TextStyle(
                            color:
                                asDouble(data!['budget']['spent']) >=
                                        asDouble(data!['budget']['amount'])
                                    ? coral
                                    : mint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'หมวดที่ใช้จ่ายสูงสุด',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if ((data!['categories'] as List).isEmpty)
                  const Text('ยังไม่มีรายการในช่วงเวลานี้')
                else
                  Panel(
                    child: Column(
                      children: [
                        for (final c in (data!['categories'] as List))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(catIcon('${c['name']}'), color: primary),
                                const SizedBox(width: 10),
                                Expanded(child: Text('${c['name']}')),
                                Text(
                                  money(c['amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'รายการล่าสุด',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onOpenTransactions,
                      child: const Text('ดูรายจ่าย >'),
                    ),
                  ],
                ),
                if ((data!['recent'] as List).isEmpty)
                  const Text('ยังไม่มีรายการ ลองเพิ่มรายรับหรือรายจ่าย')
                else
                  Panel(
                    child: Column(
                      children: [
                        for (final t in (data!['recent'] as List))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  t['type'] == 'income'
                                      ? const Color(0xFFE7F4ED)
                                      : softPink,
                              child: Icon(
                                t['type'] == 'income'
                                    ? Icons.south_west
                                    : Icons.north_east,
                                color: t['type'] == 'income' ? mint : coral,
                              ),
                            ),
                            title: Text(
                              '${t['title']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${t['transaction_date']} · ${t['category_name'] ?? 'ไม่ระบุ'}',
                            ),
                            trailing: Text(
                              '${t['type'] == 'income' ? '+' : '-'}${money(t['amount'])}',
                              style: TextStyle(
                                color: t['type'] == 'income' ? mint : coral,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
}

class TinyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const TinyBarChart({super.key, required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('ไม่มีข้อมูล');
    var maxV = 1.0;
    for (final i in items) {
      maxV = math.max(
        maxV,
        math.max(asDouble(i['income']), asDouble(i['expense'])),
      );
    }
    return SizedBox(
      height: 185,
      child: LayoutBuilder(
        builder: (context, box) {
          final colWidth = math.max(23.0, box.maxWidth / items.length);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < items.length; i++)
                  SizedBox(
                    width: colWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 146,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: math.max(
                                  5,
                                  math.min(13, colWidth * .28),
                                ),
                                height: math.max(
                                  2,
                                  (asDouble(items[i]['income']) / maxV) * 138,
                                ),
                                decoration: BoxDecoration(
                                  color: mint,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Container(
                                width: math.max(
                                  5,
                                  math.min(13, colWidth * .28),
                                ),
                                height: math.max(
                                  2,
                                  (asDouble(items[i]['expense']) / maxV) * 138,
                                ),
                                decoration: BoxDecoration(
                                  color: coral,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${items[i]['label']}',
                          style: TextStyle(
                            fontSize: items.length > 15 ? 8 : 10,
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 10)),
          ],
        ),
      ),
    ),
  );
}
