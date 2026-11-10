export 'money.dart';

// Work in satang so a rounded final installment preserves the exact total.

List<Map<String, dynamic>> installmentPreview({
  required int principalCents,
  required int count,
  required DateTime firstDue,
  int? contractCents,
}) {
  if (count < 1 || count > 360 || principalCents < count) return [];
  final regular = contractCents ?? principalCents ~/ count;
  final total = contractCents == null ? principalCents : regular * count;
  if (regular < 1 || total < principalCents || total > 999999999999) return [];
  return List.generate(count, (index) {
    final month = DateTime(firstDue.year, firstDue.month + index, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return {
      'due_date': DateTime(
        month.year,
        month.month,
        firstDue.day > lastDay ? lastDay : firstDue.day,
      ),
      'amount_cents':
          index == count - 1 ? total - regular * (count - 1) : regular,
    };
  });
}
