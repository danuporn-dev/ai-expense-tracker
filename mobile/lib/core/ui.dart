import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const primary = Color(0xFFD13C65);
const rose = Color(0xFFF4799A);
const softPink = Color(0xFFFFE8EE);
const peach = Color(0xFFFFEEDB);
const mint = Color(0xFF25836D);
const coral = Color(0xFFD34F5E);
const canvas = Color(0xFFFFFAF6);
const navy = Color(0xFF392B31);
const muted = Color(0xFF8C757D);
const line = Color(0xFFF1E4E4);

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: softPink,
    onPrimaryContainer: primary,
    secondaryContainer: peach,
    surface: Colors.white,
    onSurface: navy,
    outline: line,
    outlineVariant: line,
  );
  const rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );
  final text = ThemeData.light().textTheme.apply(
    fontFamily: 'Nunito',
    fontFamilyFallback: ['NotoSansThai'],
    bodyColor: navy,
    displayColor: navy,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Nunito',
    fontFamilyFallback: const ['NotoSansThai'],
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium!.copyWith(fontSize: 14, height: 1.5),
      bodySmall: text.bodySmall!.copyWith(
        fontSize: 12,
        height: 1.5,
        color: muted,
      ),
      titleLarge: text.titleLarge!.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: text.titleMedium!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: text.labelLarge!.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
    scaffoldBackgroundColor: canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: navy,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 72,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontFamilyFallback: ['NotoSansThai'],
        color: navy,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: canvas,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: canvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: muted, fontSize: 13),
      prefixIconColor: muted,
      suffixIconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: rounded,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: rounded,
        foregroundColor: navy,
        side: const BorderSide(color: line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: rounded),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: line,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: canvas,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: line),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: softPink,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: const WidgetStatePropertyAll(BorderSide(color: line)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? softPink : Colors.white,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
        shape: const WidgetStatePropertyAll(rounded),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'NotoSansThai',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

String money(dynamic v) =>
    '฿${NumberFormat('#,##0.00').format(double.tryParse('$v') ?? 0)}';
String amountOnly(dynamic v) =>
    NumberFormat('#,##0.##').format(double.tryParse('$v') ?? 0);
String shortDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
DateTime monthMove(DateTime date, int diff) =>
    DateTime(date.year, date.month + diff, 1);

dynamic numValue(dynamic v) => double.tryParse('$v') ?? 0.0;
double asDouble(dynamic v) => double.tryParse('$v') ?? 0;
int asInt(dynamic v) => int.tryParse('$v') ?? 0;

void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: error ? coral : navy),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(17),
  });
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: padding, child: child),
  );
}

class StatusBody extends StatelessWidget {
  final String text;
  final VoidCallback? retry;
  const StatusBody(this.text, {super.key, this.retry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: Colors.grey),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (retry != null)
            TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(26),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: softPink,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(icon, color: primary, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    ),
  );
}

class MonthSwitcher extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  const MonthSwitcher({super.key, required this.date, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => onChanged(monthMove(date, -1)),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: () => onChanged(monthMove(date, 1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
}

class SummaryTile extends StatelessWidget {
  final String title, amount;
  final Color color;
  final IconData icon;
  const SummaryTile({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<DateTime?> pickDay(BuildContext context, DateTime initial) {
  final day = DateUtils.dateOnly(initial);
  final start = DateTime(1900);
  final end = DateTime(2100, 12, 31);
  return showDatePicker(
    context: context,
    initialDate: day,
    firstDate: day.isBefore(start) ? day : start,
    lastDate: day.isAfter(end) ? day : end,
  );
}

IconData catIcon(String name) {
  if (name.contains('อาหาร')) return Icons.restaurant;
  if (name.contains('เดินทาง')) return Icons.directions_car;
  if (name.contains('ช้อป')) return Icons.shopping_bag;
  if (name.contains('สมัคร')) return Icons.subscriptions;
  if (name.contains('เงินเดือน')) return Icons.work;
  return Icons.receipt_long;
}

class BrandIcon extends StatelessWidget {
  final String keyName;
  final double size;
  const BrandIcon(this.keyName, {super.key, this.size = 30});
  @override
  Widget build(BuildContext context) {
    final domain = switch (keyName) {
      'youtube' => 'youtube.com',
      'netflix' => 'netflix.com',
      'spotify' => 'spotify.com',
      'apple' => 'apple.com',
      'google' => 'google.com',
      _ => '',
    };
    final color = switch (keyName) {
      'youtube' => const Color(0xFFFF0033),
      'netflix' => const Color(0xFFE50914),
      'spotify' => const Color(0xFF168B51),
      'apple' => Colors.black,
      'google' => primary,
      _ => const Color(0xFFAAAAAA),
    };
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(size * .3),
        border: Border.all(color: line),
      ),
      child:
          domain.isEmpty
              ? Icon(Icons.apps, size: size * .65, color: color)
              : Image.network(
                'https://www.google.com/s2/favicons?domain=$domain&sz=64',
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) =>
                        Icon(Icons.apps, color: color, size: size * .65),
              ),
    );
  }
}
