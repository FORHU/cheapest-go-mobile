import 'package:intl/intl.dart';

/// An amount in the currency a person has chosen to read prices in.
///
/// V2 formats money with `Intl.NumberFormat(style: 'currency', maximumFractionDigits: 0)`,
/// which gives `₩287,730` and `$412`. `NumberFormat.simpleCurrency` is the same formatter
/// under a different name, so the two products print a price identically.
///
/// The locale is fixed to `en_US` as V2 fixes it: the grouping and the symbol's side are part
/// of the design, and a Korean handset would otherwise render the same stay differently from
/// the website on the same account.
String formatMoney(num amount, String currency) => NumberFormat.simpleCurrency(
        locale: 'en_US',
        name: currency.toUpperCase(),
        decimalDigits: 0,
    ).format(amount);
