import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateFormatter {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (!_initialized) {
      try {
        await initializeDateFormatting('id_ID', null);
        _initialized = true;
      } catch (_) {}
    }
  }

  static String formatFull(DateTime dateTime) {
    try {
      return DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      return DateFormat('EEEE, d MMMM yyyy HH:mm').format(dateTime);
    }
  }

  static String formatDate(DateTime dateTime) {
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(dateTime);
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(dateTime);
    }
  }

  static String formatTime(DateTime dateTime) {
    try {
      return DateFormat('HH:mm', 'id_ID').format(dateTime);
    } catch (_) {
      return DateFormat('HH:mm').format(dateTime);
    }
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin, ${formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      try {
        return DateFormat('d MMM yyyy', 'id_ID').format(dateTime);
      } catch (_) {
        return DateFormat('d MMM yyyy').format(dateTime);
      }
    }
  }

  static String formatChatTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;

    if (isToday) {
      return formatTime(dateTime);
    } else if (now.difference(dateTime).inDays == 1) {
      return 'Kemarin';
    } else {
      try {
        return DateFormat('dd/MM/yy', 'id_ID').format(dateTime);
      } catch (_) {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    }
  }
}
