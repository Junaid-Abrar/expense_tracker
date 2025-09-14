import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat.simpleCurrency(decimalDigits: 2);

  static String formatCurrency(double value) => _formatter.format(value);

  static double parseCurrency(String value) {
    try {
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }

  // New helper used in expense detail screen
  static String formatAmount(double value) => formatCurrency(value);
}