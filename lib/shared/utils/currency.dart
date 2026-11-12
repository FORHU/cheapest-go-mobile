import 'package:flutter/foundation.dart';

import 'package:cheapest_go_mobile/shared/lib/http.dart';

/// Reading prices in a currency other than the one they were quoted in. See #39 and V2's
/// `shared/lib/currency.ts`, whose rule this carries over exactly.
///
/// Every price in this app is quoted in pesos — `api_travel_catalog.dart` asks the API for PHP
/// and refuses an offer priced in anything else — so that is what a conversion starts from.

/// What the catalog's prices are in. Not a setting: the API is asked for this currency.
const String catalogCurrency = 'PHP';

/// The currencies V2 offers, in V2's order.
const currencies = <({String code, String label})>[
    (code: 'USD', label: 'US Dollar'),
    (code: 'EUR', label: 'Euro'),
    (code: 'GBP', label: 'British Pound'),
    (code: 'KRW', label: 'Korean Won'),
    (code: 'JPY', label: 'Japanese Yen'),
    (code: 'PHP', label: 'Philippine Peso'),
    (code: 'SGD', label: 'Singapore Dollar'),
    (code: 'AUD', label: 'Australian Dollar'),
    (code: 'CAD', label: 'Canadian Dollar'),
    (code: 'THB', label: 'Thai Baht'),
    (code: 'MYR', label: 'Malaysian Ringgit'),
    (code: 'IDR', label: 'Indonesian Rupiah'),
    (code: 'VND', label: 'Vietnamese Dong'),
    (code: 'CNY', label: 'Chinese Yuan'),
    (code: 'INR', label: 'Indian Rupee'),
    (code: 'AED', label: 'UAE Dirham'),
];

/// One unit in US dollars, as V2's `STATIC_RATES` has them.
///
/// These are a floor, not an answer. V2's own note: the fallback is far enough out to matter —
/// PHP sits at 0.018 here against a live 0.0159, 13% — so a price converted with it is not
/// approximately right, it is wrong. Nothing converts until [ratesAreLive].
const _staticRates = <String, double>{
    'USD': 1.0,
    'PHP': 0.018,
    'KRW': 0.00075,
    'JPY': 0.0067,
    'EUR': 1.087,
    'GBP': 1.266,
    'AUD': 0.658,
    'SGD': 0.74,
    'MYR': 0.21,
    'THB': 0.027,
    'VND': 0.0000392,
    'IDR': 0.0000621,
    'CNY': 0.138,
    'TWD': 0.0307,
    'HKD': 0.127,
    'INR': 0.012,
    'AED': 0.272,
    'CAD': 0.73,
};

/// The rates in force, the fallback until the server answers.
class ExchangeRates extends ChangeNotifier {
    ExchangeRates({HttpClientAdapter? client}) : _client = client ?? HttpClientAdapter();

    final HttpClientAdapter _client;
    final Map<String, double> _rates = Map.of(_staticRates);
    DateTime? _fetchedAt;
    bool _asking = false;

    /// Whether the rates came from the server. False means the built-in fallback, and nothing
    /// may be converted with it.
    bool get live => _fetchedAt != null;

    double? rateFor(String currency) => _rates[currency.toUpperCase()];

    /// Asks once an hour, as V2 does, and says whether anything changed.
    Future<bool> refresh() async {
        if (_asking) return false;
        final at = _fetchedAt;
        if (at != null && DateTime.now().difference(at) < const Duration(hours: 1)) return false;

        _asking = true;
        try {
            final res = await _client.get(
                '/api/v2/exchange-rates',
                options: const HttpRequestOptions(useMobileApiKey: true, requiresAuth: false),
            );
            final body = res is Map<String, dynamic> ? res : const <String, dynamic>{};
            final rates = body['rates'];
            if (body['success'] != true || rates is! Map) return false;

            for (final entry in rates.entries) {
                final rate = entry.value;
                if (rate is num && rate > 0) _rates[entry.key.toString().toUpperCase()] = rate.toDouble();
            }
            _fetchedAt = DateTime.now();
            notifyListeners();
            return true;
        } catch (_) {
            // No rates is not an error a traveller needs to see: prices stay in the currency
            // they were quoted in, which is what [convertForDisplay] does anyway.
            return false;
        } finally {
            _asking = false;
        }
    }

    /// A price and the currency to print beside it.
    ///
    /// Returns the amount **in its original currency** when the rates are not live, rather than
    /// a converted-looking number that is 13% out. Showing "₱3,198" for a moment and then
    /// "₩69,680" is honest; showing "₩76,752" and charging ₩69,680 is not, and a silent
    /// fallback conversion produces the second.
    ///
    /// Callers print the currency this returns, not the one they asked for. That is why both
    /// come back together.
    ({num amount, String currency}) convertForDisplay(num amount, String from, String to) {
        final f = (from.isEmpty ? 'USD' : from).toUpperCase();
        final t = to.toUpperCase();
        if (f == t) return (amount: amount, currency: t);
        if (!live) return (amount: amount, currency: f);

        final fromRate = _rates[f];
        final toRate = _rates[t];
        if (fromRate == null || toRate == null) return (amount: amount, currency: f);

        return (amount: amount * fromRate / toRate, currency: t);
    }
}

/// The app's rates. Replaced in tests.
ExchangeRates exchangeRates = ExchangeRates();
