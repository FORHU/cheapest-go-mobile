import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/utils/currency.dart';
import 'package:cheapest_go_mobile/shared/utils/money.dart';

/// What the property is: its score, its nightly rate, what it offers, and what it says about
/// itself. See #40 and V2's `property-description.tsx`.
class PropertyDescription extends StatefulWidget {
    const PropertyDescription({required this.hotel, required this.currency, super.key});

    final Hotel hotel;
    final String currency;

    @override
    State<PropertyDescription> createState() => _PropertyDescriptionState();
}

class _PropertyDescriptionState extends State<PropertyDescription> {
    bool _expanded = false;

    /// Lines shown before "Read more", as V2 clamps it.
    static const _clamp = 5;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final hotel = widget.hotel;
        final shown = exchangeRates.convertForDisplay(
            hotel.fromRate,
            hotel.currency,
            widget.currency,
        );
        final description = _clean(hotel.description);

        return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            if (hotel.score > 0)
                                // Flexible: the band and the review count can be long, and
                                // the price beside them must keep its full width.
                                Flexible(
                                    child: _Score(
                                        score: hotel.score,
                                        reviews: hotel.reviews,
                                        skin: skin,
                                    ),
                                ),
                            const Spacer(),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                    Text(
                                        formatMoney(shown.amount, shown.currency),
                                        style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: skin.title,
                                        ),
                                    ),
                                    Text('/night', style: TextStyle(fontSize: 12, color: skin.muted)),
                                ],
                            ),
                        ],
                    ),

                    if (hotel.checkInTime != null || hotel.checkOutTime != null) ...[
                        const SizedBox(height: 16),
                        Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                                if (hotel.checkInTime != null)
                                    _Fact(icon: Icons.login_rounded, label: 'Check-in ${hotel.checkInTime}', skin: skin),
                                if (hotel.checkOutTime != null)
                                    _Fact(icon: Icons.logout_rounded, label: 'Check-out ${hotel.checkOutTime}', skin: skin),
                            ],
                        ),
                    ],

                    if (description != null) ...[
                        const SizedBox(height: 18),
                        Text(
                            description,
                            maxLines: _expanded ? null : _clamp,
                            overflow: _expanded ? null : TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, height: 1.6, color: skin.muted),
                        ),
                        // Only offered when there is more to read: a two-line description
                        // with a "Read more" under it reads as a broken control.
                        if (description.length > 280)
                            TextButton(
                                onPressed: () => setState(() => _expanded = !_expanded),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
                                child: Text(_expanded ? 'Read less' : 'Read more'),
                            ),
                    ],

                    if (hotel.amenities.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                            'What this place offers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: skin.title),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                                for (final amenity in hotel.amenities.take(12))
                                    _Fact(icon: Icons.check_rounded, label: amenity, skin: skin),
                            ],
                        ),
                    ],
                ],
            ),
        );
    }

    /// Suppliers send HTML, double spaces and their own marketing headers. V2 cleans the same
    /// text before showing it; this is the part of that worth having on a phone.
    static String? _clean(String? raw) {
        if (raw == null || raw.trim().isEmpty) return null;
        final text = raw
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'&nbsp;?', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'&amp;', caseSensitive: false), '&')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return text.isEmpty ? null : text;
    }
}

/// The **aggregate score** — a number over all stays, not a review. CONTEXT.md keeps the two
/// apart, and so does this: the words beside it describe the number, never a guest's opinion.
class _Score extends StatelessWidget {
    const _Score({required this.score, required this.reviews, required this.skin});

    final double score;
    final int reviews;
    final StaySkin skin;


    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        gradient: score >= 8 ? StaySkin.chipGradient : null,
                        color: score >= 8 ? null : const Color(0xFF0369A1),
                        borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            scoreBand(score),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: skin.title),
                        ),
                        Text(
                            '$reviews reviews',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: skin.muted),
                        ),
                    ],
                  ),
                ),
            ],
        );
    }
}

class _Fact extends StatelessWidget {
    const _Fact({required this.icon, required this.label, required this.skin});

    final IconData icon;
    final String label;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: skin.imageBg,
                borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Icon(icon, size: 14, color: skin.muted),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(fontSize: 12, color: skin.title)),
                ],
            ),
        );
    }
}
