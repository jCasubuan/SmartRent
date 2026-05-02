/// Utility for formatting rental prices consistently across the app.
class PriceFormatter {
  PriceFormatter._();

  /// Formats [price] as a comma-separated integer string.
  ///
  /// Example: `5000.0` → `'5,000'`
  static String format(double price) {
    final parts = price.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    final length = parts.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) buffer.write(',');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}
