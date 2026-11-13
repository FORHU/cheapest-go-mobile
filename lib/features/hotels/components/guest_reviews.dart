import 'package:flutter/material.dart';



import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';
import 'package:cheapest_go_mobile/l10n/generated/app_localizations.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// What guests said. See #40.
///
/// These are **verified reviews** — real per-guest entries from the supplier's nightly dump,
/// written by people who booked. The word is reserved for them in CONTEXT.md, and nothing on
/// this screen invents one: where the supplier has none, the section does not appear.
///
/// Distinct from the **aggregate score** above it, which is one number over all stays.
class GuestReviews extends StatefulWidget {
    const GuestReviews({required this.reviews, required this.score, required this.count, super.key});

    final List<Review> reviews;
    final double score;
    final int count;

    @override
    State<GuestReviews> createState() => _GuestReviewsState();
}

/// V2 offers the same three, in this order.
enum _Sort { recent, highest, lowest }

class _GuestReviewsState extends State<GuestReviews> {
    _Sort _sort = _Sort.recent;

    /// A page at a time, as V2 pages them.
    static const _page = 6;
    int _shown = _page;

    List<Review> get _ordered {
        final list = [...widget.reviews];
        switch (_sort) {
            case _Sort.recent:
                // Undated reviews keep their place rather than sinking: the supplier sends
                // the date inconsistently, and an entry without one is not an old one.
                list.sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));
            case _Sort.highest:
                list.sort((a, b) => b.score.compareTo(a.score));
            case _Sort.lowest:
                list.sort((a, b) => a.score.compareTo(b.score));
        }
        return list;
    }

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);
        final t = AppLocalizations.of(context)!;
        if (widget.reviews.isEmpty) return const SizedBox.shrink();

        final ordered = _ordered;
        final visible = ordered.take(_shown).toList();

        return Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text(
                        t.reviewsSection_guestReviews,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: skin.title),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        // The aggregate score, then how many of these are verified. The two
                        // counts differ — the score is over every stay, the reviews are the
                        // ones a guest wrote — and saying so is the point of the distinction.
                        '${widget.score.toStringAsFixed(1)} · ${scoreBand(widget.score)} · '
                        '${t.reviewsSection_verifiedReviewCount(widget.reviews.length)}',
                        style: TextStyle(fontSize: 13, color: skin.muted),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                        spacing: 8,
                        children: [
                            for (final sort in _Sort.values)
                                _SortChip(
                                    label: switch (sort) {
                                        _Sort.recent => t.reviewsSection_sort_newestFirst,
                                        _Sort.highest => t.reviewsSection_sort_highestRated,
                                        _Sort.lowest => t.reviewsSection_sort_lowestRated,
                                    },
                                    selected: _sort == sort,
                                    skin: skin,
                                    onTap: () => setState(() => _sort = sort),
                                ),
                        ],
                    ),
                    const SizedBox(height: 14),
                    for (final review in visible) ...[
                        _ReviewCard(review: review, skin: skin),
                        const SizedBox(height: 12),
                    ],
                    if (_shown < ordered.length)
                        Center(
                            child: TextButton(
                                onPressed: () => setState(() => _shown += _page),
                                child: Text(t.reviewsSection_showMore),
                            ),
                        ),
                ],
            ),
        );
    }
}

class _ReviewCard extends StatelessWidget {
    const _ReviewCard({required this.review, required this.skin});

    final Review review;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: skin.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: skin.hairline),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    gradient: review.score >= 8 ? StaySkin.chipGradient : null,
                                    color: review.score >= 8 ? null : const Color(0xFF0369A1),
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                    review.score.toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                    ),
                                ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    [review.author, review.country].where((s) => s?.isNotEmpty ?? false).join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: skin.title),
                                ),
                            ),
                            if (review.travellerType?.isNotEmpty ?? false)
                                Text(
                                    review.travellerType!,
                                    style: TextStyle(fontSize: 11.5, color: skin.muted),
                                ),
                        ],
                    ),
                    if (review.headline?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 10),
                        Text(
                            review.headline!,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: skin.title),
                        ),
                    ],
                    // Liked and disliked are separate fields and stay separate: run together
                    // they read as one opinion that contradicts itself.
                    if (review.pros?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        _Side(icon: Icons.add_rounded, text: review.pros!, tint: const Color(0xFF2FB67F), skin: skin),
                    ],
                    if (review.cons?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        _Side(icon: Icons.remove_rounded, text: review.cons!, tint: skin.muted, skin: skin),
                    ],
                ],
            ),
        );
    }
}

class _Side extends StatelessWidget {
    const _Side({required this.icon, required this.text, required this.tint, required this.skin});

    final IconData icon;
    final String text;
    final Color tint;
    final StaySkin skin;

    @override
    Widget build(BuildContext context) {
        return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Icon(icon, size: 15, color: tint),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        text,
                        style: TextStyle(fontSize: 13, height: 1.45, color: skin.muted),
                    ),
                ),
            ],
        );
    }
}

class _SortChip extends StatelessWidget {
    const _SortChip({required this.label, required this.selected, required this.skin, required this.onTap});

    final String label;
    final bool selected;
    final StaySkin skin;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: selected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? Colors.transparent : skin.hairline),
                    ),
                    child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : skin.title,
                        ),
                    ),
                ),
            ),
        );
    }
}
