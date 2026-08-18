class NumberUtils {
  static double toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int paramInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String formatRating(dynamic rating) {
    return toDouble(rating).toStringAsFixed(1);
  }

  static String formatCurrency(dynamic amount) {
    return toDouble(amount).toStringAsFixed(0);
  }
}
