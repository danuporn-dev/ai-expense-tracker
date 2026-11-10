import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet_ai/core/receipt_category.dart';

void main() {
  final categories = [
    {'id': 1, 'type': 'expense', 'name': 'เดินทาง'},
    {'id': '2', 'type': 'expense', 'name': 'อาหาร'},
    {'id': 3, 'type': 'expense', 'name': 'อื่น ๆ'},
    {'id': 4, 'type': 'income', 'name': 'อาหาร'},
  ];
  test('AI food category wins over the first available category', () {
    expect(receiptCategoryId(categories, 'อาหาร'), 2);
  });
  test('category matching ignores whitespace', () {
    expect(receiptCategoryId(categories, ' อาหาร\u200B '), 2);
    expect(receiptCategoryId(categories, 'อื่นๆ'), 3);
  });
  test('unknown or missing AI category falls back to other', () {
    expect(receiptCategoryId(categories, 'unknown'), 3);
    expect(receiptCategoryId(categories, null), 3);
  });
  test('never selects income categories or guesses the first category', () {
    expect(receiptCategoryId([categories[3]], 'อาหาร'), isNull);
    expect(receiptCategoryId([categories[0]], 'unknown'), isNull);
    expect(receiptCategoryId([], 'อาหาร'), isNull);
  });
}
