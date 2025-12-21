import 'package:intl/intl.dart';

class AppFormatters {
  // Currency formatter (Euro)
  static String formatCurrency(double amount, {String locale = 'fr_FR'}) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '€',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  // Compact currency formatter (1.2K, 1.5M, etc.)
  static String formatCompactCurrency(double amount, {String locale = 'fr_FR'}) {
    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      symbol: '€',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  // Date formatter
  static String formatDate(DateTime date, {String pattern = 'dd MMM yyyy'}) {
    final formatter = DateFormat(pattern, 'fr_FR');
    return formatter.format(date);
  }

  // Date with time formatter
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');
    return formatter.format(date);
  }

  // Relative date formatter (Aujourd'hui, Hier, etc.)
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    }
  }

  // Phone number formatter (French)
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 8)} ${cleaned.substring(8, 10)}';
    }
    
    return phone;
  }

  // SIRET formatter
  static String formatSiret(String siret) {
    final cleaned = siret.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.length == 14) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9, 14)}';
    }
    
    return siret;
  }

  // Percentage formatter
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Number formatter with separator
  static String formatNumber(double number, {int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}', 'fr_FR');
    return formatter.format(number);
  }

  // File size formatter
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
