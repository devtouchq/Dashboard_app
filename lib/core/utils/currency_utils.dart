/// Currency utilities. The API returns a currency code in
/// `Currency.DefaultCurrency`; we map it to a symbol and full name and
/// expose a shared money formatter so every screen displays values the
/// same way.
class CurrencyUtils {
  CurrencyUtils._();

  static const _symbols = <String, String>{
    'INR': '₹',
    'USD': '\$',
    'DOLLAR': '\$',
    'AED': 'د.إ',
    'EUR': '€',
    'OMR': '﷼',
  };

  static const _names = <String, String>{
    'INR': 'Indian Rupee',
    'USD': 'US Dollar',
    'DOLLAR': 'US Dollar',
    'AED': 'UAE Dirham',
    'EUR': 'Euro',
    'OMR': 'Omani Rial',
  };

  /// Symbol for a currency code; falls back to the code itself if unknown.
  static String symbol(String code) {
    final key = code.trim().toUpperCase();
    return _symbols[key] ?? key;
  }

  /// Human-readable currency name.
  static String name(String code) {
    final key = code.trim().toUpperCase();
    return _names[key] ?? key;
  }

  /// Format a money value with the currency symbol, international
  /// comma grouping, and 2 decimal places.
  ///
  /// Examples:
  ///   format(6000, 'INR')           → ₹6,000.00
  ///   format(61166637.97, 'INR')    → ₹61,166,637.97
  ///   format(-2879640.82, 'INR')    → -₹2,879,640.82
  ///   format(0, 'USD')              → $0.00
  static String format(double value, String code) {
    final sym = symbol(code);
    final neg = value < 0;
    final abs = value.abs();
    final s = _withCommas(abs);
    return neg ? '-$sym$s' : '$sym$s';
  }

  /// Convert a double to a string with two decimals and international
  /// thousands separators. Avoids the `intl` package dependency.
  ///
  /// 61166637.97 → "61,166,637.97"
  /// 1000        → "1,000.00"
  /// 0           → "0.00"
  static String _withCommas(double value) {
    // Always show exactly 2 decimal places.
    final fixed = value.toStringAsFixed(2);
    // Split into integer + fractional parts.
    final dotIdx = fixed.indexOf('.');
    final intPart = fixed.substring(0, dotIdx);
    final fracPart = fixed.substring(dotIdx); // includes the '.'

    // Insert a comma every 3 digits, right-to-left, in the integer part.
    final buf = StringBuffer();
    var count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      }
    }
    final reversed = buf.toString().split('').reversed.join();
    return '$reversed$fracPart';
  }
}
