import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../services/currency_service.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final CurrencyService _currencyService = CurrencyService();
  final TextEditingController _amountController = TextEditingController(text: '100000');

  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _result = 0.0;
  bool _isLoading = false;
  CurrencyRate? _rateData;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    final data = await _currencyService.fetchExchangeRates();
    setState(() {
      _rateData = data;
      _isLoading = false;
    });
    _calculateConversion();
  }

  void _calculateConversion() {
    if (_rateData == null) return;
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(text) ?? 0.0;

    final converted = _currencyService.convert(
      amount: amount,
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      rates: _rateData!.rates,
    );

    setState(() => _result = converted);
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _calculateConversion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konversi Mata Uang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Perbarui Kurs',
            onPressed: _isLoading ? null : _loadRates,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (_rateData?.isOnline ?? false) ? AppColors.primarySurface : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_rateData?.isOnline ?? false) ? AppColors.primaryLight : Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_rateData?.isOnline ?? false) ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: (_rateData?.isOnline ?? false) ? AppColors.primary : Colors.amber.shade800,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _rateData != null
                          ? '${(_rateData!.isOnline) ? "Kurs Realtime Online" : "Mode Offline (Kurs Tersimpan)"} • Pembaruan: ${DateFormatter.formatRelative(_rateData!.lastUpdated)}'
                          : 'Memuat kurs mata uang...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: (_rateData?.isOnline ?? false) ? AppColors.primaryDark : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conversion Box Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Amount Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nominal Jumlah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              _fromCurrency,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        ),
                        onChanged: (_) => _calculateConversion(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Currency Selectors with Swap button
                  Row(
                    children: [
                      Expanded(
                        child: _buildCurrencyDropdown('Dari', _fromCurrency, (val) {
                          setState(() => _fromCurrency = val!);
                          _calculateConversion();
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Material(
                          color: AppColors.primarySurface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _swapCurrencies,
                            child: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 24),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildCurrencyDropdown('Ke', _toCurrency, (val) {
                          setState(() => _toCurrency = val!);
                          _calculateConversion();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Conversion Result
                  const Text('Hasil Konversi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatCustom(_result, _toCurrency),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_rateData != null)
                    Text(
                      '1 $_fromCurrency = ${CurrencyFormatter.formatCustom(_currencyService.convert(amount: 1, fromCurrency: _fromCurrency, toCurrency: _toCurrency, rates: _rateData!.rates), _toCurrency)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Supported Currencies List
            const Text('Daftar Nilai Tukar Referensi (per 1 USD)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_rateData != null)
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Column(
                  children: CurrencyService.supportedCurrencies.map((code) {
                    final rate = _rateData!.rates[code] ?? 1.0;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(code.substring(0, 2), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        title: Text(code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        trailing: Text(
                          code == 'IDR' || code == 'JPY' ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown(String label, String value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: CurrencyService.supportedCurrencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold))))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
