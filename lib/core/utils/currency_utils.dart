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

  /// Returns the symbol for a currency code, falling back to the code itself.
  static String symbol(String code) {
    final key = code.trim().toUpperCase();
    return _symbols[key] ?? key;
  }

  /// Returns a human-readable name for a currency code.
  static String name(String code) {
    final key = code.trim().toUpperCase();
    return _names[key] ?? key;
  }

  /// Format a money value with the currency symbol and Indian-style
  /// abbreviations (k / L / Cr). Handles negative values.
  ///
  /// Example: format(45230, 'INR') → '₹45.2k'
  static String format(double value, String code) {
    final sym = symbol(code);
    final neg = value < 0;
    final abs = value.abs();
    String s;
    if (abs >= 10000000) {
      s = '${(abs / 10000000).toStringAsFixed(2)}Cr';
    } else if (abs >= 100000) {
      s = '${(abs / 100000).toStringAsFixed(2)}L';
    } else if (abs >= 1000) {
      s = '${(abs / 1000).toStringAsFixed(1)}k';
    } else {
      s = abs.toStringAsFixed(0);
    }
    return neg ? '-$sym$s' : '$sym$s';
  }
}
