import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../core/money.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  DateTime focused = DateTime.now(), selected = DateTime.now();
  List<dynamic> services = [], events = [];
  bool loading = true;
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
      final res = await api.request(
        'subscriptions',
        query: {'month': monthKey(focused)},
      );
      if (mounted)
        setState(() {
          services = res['items'];
          events = res['events'];
        });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<dynamic> forDay(DateTime d) =>
      events.where((e) => e['due_date'] == isoDate(d)).toList();
  Future<void> edit([Map<String, dynamic>? sub]) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SubscriptionForm(initial: sub),
    );
    if (ok == true) load();
  }

  Future<void> stop(int id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ปิดการติดตามบริการนี้?'),
            content: const Text('ประวัติการชำระเดิมยังคงอยู่'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ปิดบริการ'),
              ),
            ],
          ),
    );
    if (yes != true) return;
    try {
      await api.request(
        'subscriptions',
        method: 'DELETE',
        query: {'id': '$id'},
      );
      load();
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  Future<void> markPaid(Map event) async {
    try {
      await api.request(
        'subscriptions/pay',
        method: 'POST',
        data: {
          'subscription_id': asInt(event['subscription_id']),
          'due_date': event['due_date'],
        },
      );
      if (mounted) snack(context, 'บันทึกการชำระและเพิ่มรายจ่ายแล้ว');
      load();
    } catch (e) {
      if (mounted) snack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => edit(),
      icon: const Icon(Icons.add),
      label: const Text('เพิ่มบริการ'),
    ),
    body:
        loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? StatusBody(error!, retry: load)
            : ListView(
              padding: const EdgeInsets.fromLTRB(15, 6, 15, 110),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 5, 4, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ทุกรอบจ่าย อยู่ในแผน',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ติดตามบริการที่คุณรักในที่เดียว',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Panel(
                  child: TableCalendar<dynamic>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: focused,
                    selectedDayPredicate: (day) => isSameDay(selected, day),
                    eventLoader: forDay,
                    onDaySelected:
                        (day, focus) => setState(() {
                          selected = day;
                          focused = focus;
                        }),
                    onPageChanged: (day) {
                      focused = day;
                      load();
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: softPink,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 0,
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left_rounded,
                        color: muted,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: muted,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<dynamic>(
                      markerBuilder:
                          (context, date, ev) =>
                              ev.isEmpty
                                  ? null
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (final e in ev.take(3))
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          child: BrandIcon(
                                            '${e['icon_key']}',
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'ครบกำหนด ${shortDate(selected)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                if (forDay(selected).isEmpty)
                  const Panel(child: Text('ไม่มีรอบตัดเงินในวันนี้'))
                else
                  for (final e in forDay(selected))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                        child: Row(
                          children: [
                            BrandIcon('${e['icon_key']}', size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e['service_name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    money(e['amount']),
                                    style: const TextStyle(color: muted),
                                  ),
                                  if (e['paid_date'] != null)
                                    Text(
                                      'ชำระแล้ว ${shortDate(DateTime.parse(e['paid_date']))}',
                                      style: const TextStyle(
                                        color: mint,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            e['paid'] == true
                                ? const Chip(
                                  label: Text('จ่ายแล้ว'),
                                  avatar: Icon(
                                    Icons.check,
                                    color: mint,
                                    size: 17,
                                  ),
                                )
                                : FilledButton(
                                  onPressed: () => markPaid(Map.from(e)),
                                  child: const Text('บันทึกจ่าย'),
                                ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 15),
                const Text(
                  'รายการ Subscription',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (services.isEmpty)
                  const EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'บริการที่คุณรัก',
                    subtitle: 'เพิ่มบริการแรก เพื่อติดตามรอบชำระของคุณ',
                  )
                else
                  Panel(
                    child: Column(
                      children: [
                        for (final s in services)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: BrandIcon('${s['icon_key']}', size: 43),
                            title: Text('${s['service_name']}'),
                            subtitle: Text(
                              '${s['cycle'] == 'yearly' ? 'รายปี' : 'รายเดือน'} · วันที่ ${s['billing_day']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  money(s['amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'edit')
                                      edit(Map<String, dynamic>.from(s));
                                    if (v == 'stop') stop(asInt(s['id']));
                                  },
                                  itemBuilder:
                                      (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('แก้ไข'),
                                        ),
                                        PopupMenuItem(
                                          value: 'stop',
                                          child: Text('ยกเลิกติดตาม'),
                                        ),
                                      ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'หลังชำระ ระบบจะเพิ่มค่าใช้จ่าย 1 ครั้งต่อรอบโดยอัตโนมัติ (ไม่ตัดเงินจากบัญชีจริง)',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
  );
}

class _SubscriptionForm extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _SubscriptionForm({this.initial});
  @override
  State<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<_SubscriptionForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), amount = TextEditingController();
  DateTime date = DateTime.now();
  String icon = 'youtube', cycle = 'monthly';
  int billingDay = 1;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    if (s != null) {
      name.text = '${s['service_name']}';
      amount.text = '${s['amount']}';
      date = DateTime.tryParse('${s['start_date']}') ?? DateTime.now();
      icon = '${s['icon_key']}';
      cycle = '${s['cycle']}';
      billingDay = asInt(s['billing_day']);
    } else {
      billingDay = date.day;
    }
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await api.request(
        'subscriptions',
        method: widget.initial == null ? 'POST' : 'PUT',
        query:
            widget.initial == null ? null : {'id': '${widget.initial!['id']}'},
        data: {
          'service_name': name.text.trim(),
          'amount': amount.text.trim(),
          'icon_key': icon,
          'cycle': cycle,
          'start_date': isoDate(date),
          'billing_day': billingDay,
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
      MediaQuery.of(context).viewInsets.bottom + 24,
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
                    ? 'เพิ่ม Subscription'
                    : 'แก้ไข Subscription',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'ชื่อบริการ เช่น YouTube Premium',
                ),
                validator:
                    (v) => (v ?? '').trim().isEmpty ? 'กรอกชื่อบริการ' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'ยอดชำระ (บาท)'),
                validator: validateMoneyAmount,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: icon,
                decoration: const InputDecoration(labelText: 'ไอคอนบริการ'),
                items: const [
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                  DropdownMenuItem(value: 'netflix', child: Text('Netflix')),
                  DropdownMenuItem(value: 'spotify', child: Text('Spotify')),
                  DropdownMenuItem(value: 'apple', child: Text('Apple')),
                  DropdownMenuItem(value: 'google', child: Text('Google')),
                  DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
                ],
                onChanged: (v) => setState(() => icon = v ?? 'other'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cycle,
                decoration: const InputDecoration(labelText: 'ความถี่'),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('ทุกเดือน')),
                  DropdownMenuItem(value: 'yearly', child: Text('ทุกปี')),
                ],
                onChanged: (v) => setState(() => cycle = v ?? 'monthly'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await pickDay(context, date);
                  if (d != null) setState(() => date = d);
                },
                icon: const Icon(Icons.event),
                label: Text('วันเริ่มต้น ${shortDate(date)}'),
              ),
              const SizedBox(height: 7),
              Text(
                'วันที่ตัดรอบ: $billingDay',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Slider(
                min: 1,
                max: 31,
                divisions: 30,
                label: '$billingDay',
                value: billingDay.toDouble(),
                onChanged: (v) => setState(() => billingDay = v.round()),
              ),
              const Text(
                'สำหรับวันที่ 29–31 ถ้าเดือนสั้นกว่า ระบบใช้วันสุดท้ายของเดือน',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: saving ? null : save,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(saving ? 'กำลังบันทึก...' : 'บันทึกบริการ'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
