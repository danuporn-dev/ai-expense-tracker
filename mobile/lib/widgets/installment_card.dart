import 'package:flutter/material.dart';
import '../core/ui.dart';

class InstallmentCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback? onOpen;
  final bool detail;
  const InstallmentCard({
    super.key,
    required this.plan,
    required this.onOpen,
    this.detail = false,
  });

  @override
  Widget build(BuildContext context) {
    final done = plan['status'] == 'completed';
    final next = plan['next_payment'];
    final overdue = next != null && next['status'] == 'overdue';
    final color =
        done
            ? mint
            : overdue
            ? coral
            : primary;
    final count = asInt(plan['installment_count']);
    final paid = asInt(plan['paid_count']);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: softPink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan['product_name']}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      done
                          ? 'ผ่อนครบแล้ว'
                          : overdue
                          ? 'มีงวดเลยกำหนด'
                          : 'กำลังผ่อน',
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ชำระแล้ว $paid / $count งวด'),
              Text(
                '${count == 0 ? 0 : (paid * 100 / count).round()}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: count == 0 ? 0 : paid / count,
            minHeight: 9,
            color: color,
            backgroundColor: softPink,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _amount('จ่ายแล้ว', money(plan['paid_amount']), mint),
              ),
              Expanded(
                child: _amount(
                  'คงเหลือ',
                  money(plan['remaining_amount']),
                  primary,
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canvas,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_outlined, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overdue
                              ? 'งวดที่ ${next['installment_number']} เลยกำหนด'
                              : 'งวดถัดไป',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '${shortDate(DateTime.parse(next['due_date']))} · ${money(next['amount'])}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!detail || !done) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpen,
              child: Text(
                detail
                    ? 'บันทึกชำระงวด'
                    : done
                    ? 'ดูประวัติการชำระ'
                    : 'ดูตาราง / บันทึกชำระงวด',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amount(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ],
  );
}
