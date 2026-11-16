/// Finding a booking by what the traveller remembers of it. V2's `booking-search.ts`.
///
/// A hotel's or a course's name, an airport code, a passenger, or a reference out of an email.
/// Every word typed has to appear somewhere in the booking, in any order, so "seoul jeju"
/// narrows rather than widens.
library;

/// Lower case, without accents, so "cebu" finds "Cebú".
///
/// Dart has no `String.normalize`, so the handful of marks that actually turn up in place and
/// passenger names are folded directly. A letter this misses still matches when typed as it is
/// written; what it buys is that the unaccented spelling works too.
String fold(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
        buffer.write(_marks[rune] ?? String.fromCharCode(rune));
    }
    return buffer.toString();
}

const _marks = <int, String>{
    0xE0: 'a', 0xE1: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a', 0x101: 'a', 0x103: 'a',
    0xE7: 'c', 0x107: 'c', 0x10D: 'c',
    0xE8: 'e', 0xE9: 'e', 0xEA: 'e', 0xEB: 'e', 0x113: 'e', 0x11B: 'e',
    0xEC: 'i', 0xED: 'i', 0xEE: 'i', 0xEF: 'i', 0x12B: 'i',
    0xF1: 'n', 0x144: 'n',
    0xF2: 'o', 0xF3: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o', 0x14D: 'o', 0xF8: 'o',
    0xF9: 'u', 0xFA: 'u', 0xFB: 'u', 0xFC: 'u', 0x16B: 'u',
    0xFD: 'y', 0xFF: 'y',
    0x15F: 's', 0x161: 's', 0x15B: 's',
    0x17E: 'z', 0x17A: 'z', 0x17C: 'z',
};

/// The words of a query.
///
/// Dashes, arrows and slashes separate words as spaces do, so "MNL-ICN" and "MNL → ICN" both
/// find the route, and a reference typed whole, "CG-AB12CD", still finds itself as its halves.
List<String> queryTerms(String query) =>
    fold(query).split(RegExp(r'[\s,\-–—→>/·|]+')).where((t) => t.isNotEmpty).toList();

/// Whether every word of the query is in the text. No words, no narrowing.
bool matchesTerms(String text, List<String> terms) =>
    terms.every((term) => text.contains(term));

/// Builds the haystack for a booking out of the parts worth searching.
String searchTextOf(Iterable<String?> parts) =>
    fold(parts.where((p) => p != null && p.isNotEmpty).join(' '));
