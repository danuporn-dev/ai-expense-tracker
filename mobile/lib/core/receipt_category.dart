String _normalizeCategory(dynamic value) => '$value'.trim().toLowerCase()
    .replaceAll(RegExp(r'[\s\u200B\uFEFF]'), '');

int? receiptCategoryId(List<dynamic> categories, dynamic suggestedName) {
  final suggested = _normalizeCategory(suggestedName);
  int? other;
  for (final category in categories) {
    if (category['type'] != null && category['type'] != 'expense') continue;
    final id = int.tryParse('${category['id']}');
    if (id == null || id <= 0) continue;
    final name = _normalizeCategory(category['name']);
    if (suggested.isNotEmpty && name == suggested) return id;
    if (name == 'อื่นๆ') other = id;
  }
  return other;
}
