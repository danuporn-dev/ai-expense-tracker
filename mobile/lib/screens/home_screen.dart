import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/ui.dart';
import 'profile_screen.dart';
import 'dashboard_screen.dart';
import 'transaction_screen.dart';
import 'receipt_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  int serial = 0;
  void go(int index) => setState(() {
    selected = index;
    serial++;
  });
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        key: ValueKey('dashboard-$serial'),
        onOpenTransactions: () => go(3),
        onScan: () => go(2),
      ),
      TransactionScreen(key: ValueKey('income-$serial'), type: 'income'),
      ReceiptScreen(key: ValueKey('receipt-$serial'), onSaved: () => go(3)),
      TransactionScreen(key: ValueKey('expense-$serial'), type: 'expense'),
      SubscriptionScreen(key: ValueKey('sub-$serial')),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MY WALLET',
              style: TextStyle(
                color: primary,
                fontSize: 11,
                letterSpacing: 2.3,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              [
                'ภาพรวมการเงิน',
                'รายรับ',
                'สแกนบิลด้วย AI',
                'รายจ่าย',
                'Subscription',
              ][selected],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: softPink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: PopupMenuButton<String>(
                tooltip: 'บัญชีผู้ใช้',
                onSelected: (value) async {
                  if (value == 'logout') api.logout();
                  if (value == 'profile') {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                    if (mounted) setState(() => serial++);
                  }
                },
                itemBuilder:
                    (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(api.user?['name'] ?? 'My Wallet'),
                      ),
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 19,
                              color: primary,
                            ),
                            SizedBox(width: 10),
                            Text('แก้ไขข้อมูลส่วนตัว'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 19, color: muted),
                            SizedBox(width: 10),
                            Text('ออกจากระบบ'),
                          ],
                        ),
                      ),
                    ],
                icon:
                    api.avatarBytes == null
                        ? const Icon(Icons.account_circle_outlined)
                        : CircleAvatar(
                          radius: 15,
                          backgroundImage: MemoryImage(api.avatarBytes!),
                        ),
              ),
            ),
          ),
        ],
      ),
      body: pages[selected],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: navy.withValues(alpha: .04),
                blurRadius: 22,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _tab(0, Icons.home_outlined, Icons.home_rounded, 'หน้าหลัก'),
              _tab(
                1,
                Icons.south_west_rounded,
                Icons.south_west_rounded,
                'รายรับ',
              ),
              _tab(
                2,
                Icons.document_scanner_outlined,
                Icons.document_scanner_rounded,
                'สแกนบิล',
              ),
              _tab(
                3,
                Icons.north_east_rounded,
                Icons.north_east_rounded,
                'รายจ่าย',
              ),
              _tab(
                4,
                Icons.calendar_month_outlined,
                Icons.calendar_month_rounded,
                'subscription',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, IconData activeIcon, String label) {
    final active = selected == index;
    final scan = index == 2;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: InkWell(
          onTap: () => go(index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 43,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        scan
                            ? primary
                            : active
                            ? softPink
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    size: 22,
                    color:
                        scan
                            ? Colors.white
                            : active
                            ? primary
                            : muted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: index == 4 ? 10 : 11,
                    color: active ? primary : muted,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
