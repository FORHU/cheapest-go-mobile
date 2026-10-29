import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// Currency conversion utilities — mirrors `cheapest-go-mobile/lib/currency.ts`.
///
/// Static fallback rates are used until `refreshExchangeRates()` succeeds.
/// All rates are in "USD per 1 unit" format (e.g. PHP: 0.018 means 1 PHP = $0.018).
/// Note per domain glossary: Display Currency conversions on the client are
/// strictly display placeholders; authoritative Charge Currency totals come
/// from server-side prebook/quote responses.

class CurrencyService {
  static final Map<String, double> _staticRates = {
    'USD': 1.0,
    'PHP': 0.018,
    'KRW': 0.00075,
  };

  static final Map<String, double> exchangeRates = Map.from(_staticRates);

  static DateTime? _lastRefresh;

  static Future<bool> refreshExchangeRates() async {
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!) < const Duration(hours: 1)) {
      return false;
    }

    const urls = [
      'https://api.frankfurter.dev/v1/latest?base=USD&symbols=PHP,KRW',
      'https://api.frankfurter.app/latest?base=USD&symbols=PHP,KRW',
    ];

    for (final url in urls) {
      try {
        final data = await http.get(
          url,
          options: const HttpRequestOptions(
            requiresAuth: false,
            timeout: Duration(seconds: 6),
          ),
        );
        if (data is Map<String, dynamic> && data['rates'] is Map) {
          final rates = data['rates'] as Map;
          for (final entry in rates.entries) {
            final ccy = entry.key.toString().toUpperCase();
            final rate = (entry.value as num?)?.toDouble() ?? 0;
            if (rate > 0) {
              exchangeRates[ccy] = 1.0 / rate;
            }
          }
          _lastRefresh = DateTime.now();
          return true;
        }
      } catch (_) {
        // Try next URL
      }
    }
    return false;
  }

  static double convertCurrency(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    if (from == to) return amount;
    final fromRate = exchangeRates[from];
    final toRate = exchangeRates[to];
    if (fromRate == null || toRate == null || toRate == 0) return amount;
    return (amount * fromRate) / toRate;
  }

  static String getCurrencySymbol(String currency) {
    return switch (currency.toUpperCase()) {
      'USD' => r'$',
      'PHP' => '₱',
      'KRW' => '₩',
      _ => currency.toUpperCase(),
    };
  }

  static String formatPrice(double amount, String currency) {
    final rounded = amount.round();
    final formatted = rounded.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '${getCurrencySymbol(currency)}$formatted';
  }
}
