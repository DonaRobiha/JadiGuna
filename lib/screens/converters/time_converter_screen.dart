import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class TimeZoneInfo {
  final String code;
  final String name;
  final String location;
  final int offsetHours;
  final String flag;

  const TimeZoneInfo({
    required this.code,
    required this.name,
    required this.location,
    required this.offsetHours,
    required this.flag,
  });
}

class TimeConverterScreen extends StatefulWidget {
  const TimeConverterScreen({super.key});

  @override
  State<TimeConverterScreen> createState() => _TimeConverterScreenState();
}

class _TimeConverterScreenState extends State<TimeConverterScreen> {
  DateTime _selectedDateTime = DateTime.now();
  String _sourceTimeZone = 'WIB';

  // London DST check: BST (British Summer Time, UTC+1) runs from last Sunday of March to last Sunday of October.
  // In October 2026, BST is active (+1)
  bool _isLondonDst(DateTime date) {
    if (date.month > 3 && date.month < 10) return true;
    if (date.month == 3 && date.day >= 25) return true;
    if (date.month == 10 && date.day <= 25) return true;
    return false;
  }

  int _getLondonOffset() {
    return _isLondonDst(_selectedDateTime) ? 1 : 0;
  }

  final List<TimeZoneInfo> _timeZones = const [
    TimeZoneInfo(
      code: 'WIB',
      name: 'Waktu Indonesia Barat',
      location: 'Jakarta, Sumatera, Jawa (UTC+7)',
      offsetHours: 7,
      flag: '🇮🇩',
    ),
    TimeZoneInfo(
      code: 'WITA',
      name: 'Waktu Indonesia Tengah',
      location: 'Bali, Nusa Tenggara, Kalimantan (UTC+8)',
      offsetHours: 8,
      flag: '🇮🇩',
    ),
    TimeZoneInfo(
      code: 'WIT',
      name: 'Waktu Indonesia Timur',
      location: 'Maluku, Papua (UTC+9)',
      offsetHours: 9,
      flag: '🇮🇩',
    ),
    TimeZoneInfo(
      code: 'London',
      name: 'London Time (GMT/BST)',
      location: 'Inggris Raya (UTC+0 / BST UTC+1)',
      offsetHours: 0, // dynamically handled
      flag: '🇬🇧',
    ),
  ];

  DateTime _convertTimeTo(String targetCode) {
    // 1. Find source offset
    int sourceOffset = 7;
    if (_sourceTimeZone == 'WIB') sourceOffset = 7;
    if (_sourceTimeZone == 'WITA') sourceOffset = 8;
    if (_sourceTimeZone == 'WIT') sourceOffset = 9;
    if (_sourceTimeZone == 'London') sourceOffset = _getLondonOffset();

    // 2. Convert to UTC
    final utcTime = _selectedDateTime.subtract(Duration(hours: sourceOffset));

    // 3. Convert UTC to target offset
    int targetOffset = 7;
    if (targetCode == 'WIB') targetOffset = 7;
    if (targetCode == 'WITA') targetOffset = 8;
    if (targetCode == 'WIT') targetOffset = 9;
    if (targetCode == 'London') targetOffset = _getLondonOffset();

    return utcTime.add(Duration(hours: targetOffset));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final londonDst = _isLondonDst(_selectedDateTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konversi Waktu & Zona'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Selection Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih Waktu Asal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  // Date & Time Picker buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            DateFormat('d MMM yyyy').format(_selectedDateTime),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule_rounded, size: 16),
                          label: Text(
                            DateFormat('HH:mm').format(_selectedDateTime),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Source Timezone selector
                  const Text('Zona Waktu Asal:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _sourceTimeZone,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    items: ['WIB', 'WITA', 'WIT', 'London'].map((z) {
                      return DropdownMenuItem(value: z, child: Text(z, style: const TextStyle(fontWeight: FontWeight.bold)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _sourceTimeZone = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // DST info banner for London
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      londonDst
                          ? 'Waktu London saat ini menggunakan British Summer Time (BST, UTC+1).'
                          : 'Waktu London saat ini menggunakan Greenwich Mean Time (GMT, UTC+0).',
                      style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Conversion Results to all 4 zones
            const Text('Hasil Konversi Seluruh Zona Waktu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),

            ..._timeZones.map((tz) {
              final convertedTime = _convertTimeTo(tz.code);
              final isCurrentSource = tz.code == _sourceTimeZone;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrentSource ? AppColors.primarySurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentSource ? AppColors.primary : AppColors.border,
                    width: isCurrentSource ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(tz.flag, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tz.code,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrentSource ? AppColors.primaryDark : AppColors.textPrimary,
                                ),
                              ),
                              if (isCurrentSource) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('ASAL', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(tz.location, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, d MMMM yyyy').format(convertedTime),
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(convertedTime),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isCurrentSource ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
