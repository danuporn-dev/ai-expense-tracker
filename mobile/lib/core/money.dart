// Parse in satang; shared by all money forms.
int? moneyCents(String raw, {bool allowZero = false}) {
  final text = raw.trim();
  if (!RegExp(r'^\d{1,10}(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final cents =
      int.parse(parts.first) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  if (cents < (allowZero ? 0 : 1) || cents > 999999999999) return null;
  return cents;
}

String? validateMoneyAmount(String? raw) =>
    moneyCents(raw ?? '') == null
        ? 'กรอกยอด 0.01–9,999,999,999.99 บาท ทศนิยมไม่เกิน 2 ตำแหน่ง'
        : null;
