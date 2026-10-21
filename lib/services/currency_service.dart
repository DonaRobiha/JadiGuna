import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyRate {
  final Map<String, double> rates; // relative to USD as base
  final DateTime lastUpdated;
  final bool isOnline;

  CurrencyRate({
    required this.rates,
    required this.lastUpdated,
    required this.isOnline,
  });
}

class CurrencyService {
  // Baseline rates if offline (1 USD = ...)
  static final Map<String, double> defaultRatesFromUsd = {
    'USD': 1.0,
    'IDR': 15850.0,
    'JPY': 152.4,
    'EUR': 0.92,
    'SGD': 1.34,
  };

  static const List<String> supportedCurrencies = ['IDR', 'USD', 'JPY', 'EUR', 'SGD'];

  Future<CurrencyRate> fetchExchangeRates() async {
    try {
      final response = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success' && data['rates'] != null) {
          final rawRates = data['rates'] as Map<String, dynamic>;
          Map<String, double> parsedRates = {};

          for (var code in supportedCurrencies) {
            if (rawRates.containsKey(code)) {
              parsedRates[code] = (rawRates[code] as num).toDouble();
            } else if (defaultRatesFromUsd.containsKey(code)) {
              parsedRates[code] = defaultRatesFromUsd[code]!;
            }
          }

          final now = DateTime.now();
          // Save to prefs
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_currency_rates', json.encode(parsedRates));
          await prefs.setString('cached_currency_time', now.toIso8601String());

          return CurrencyRate(
            rates: parsedRates,
            lastUpdated: now,
            isOnline: true,
          );
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Load from cache or default
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_currency_rates');
      final timeStr = prefs.getString('cached_currency_time');

      if (cachedStr != null && timeStr != null) {
        final Map<String, dynamic> decoded = json.decode(cachedStr);
        final rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
        return CurrencyRate(
          rates: rates,
          lastUpdated: DateTime.parse(timeStr),
          isOnline: false,
        );
      }
    } catch (_) {}

    return CurrencyRate(
      rates: defaultRatesFromUsd,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 12)),
      isOnline: false,
    );
  }

  /// Convert amount from source currency to target currency
  double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required Map<String, double> rates,
  }) {
    if (fromCurrency == toCurrency) return amount;

    final fromRate = rates[fromCurrency] ?? 1.0;
    final toRate = rates[toCurrency] ?? 1.0;

    // Convert from -> USD -> to
    final amountInUsd = amount / fromRate;
    return amountInUsd * toRate;
  }
}
