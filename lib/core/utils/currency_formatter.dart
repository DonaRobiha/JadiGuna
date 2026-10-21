import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _idrFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactIdrFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(int? amount) {
    if (amount == null || amount == 0) {
      return 'GRATIS';
    }
    return _idrFormat.format(amount);
  }

  static String formatCompact(int? amount) {
    if (amount == null || amount == 0) {
      return 'GRATIS';
    }
    return _compactIdrFormat.format(amount);
  }

  static String formatCustom(double amount, String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'IDR':
        return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$ ', decimalDigits: 2).format(amount);
      case 'JPY':
        return NumberFormat.currency(locale: 'ja_JP', symbol: '¥ ', decimalDigits: 0).format(amount);
      case 'EUR':
        return NumberFormat.currency(locale: 'de_DE', symbol: '€ ', decimalDigits: 2).format(amount);
      case 'SGD':
        return NumberFormat.currency(locale: 'en_SG', symbol: 'S\$ ', decimalDigits: 2).format(amount);
      default:
        return '$currencyCode ${amount.toStringAsFixed(2)}';
    }
  }
}
