import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/home/components/stage_chrome.dart';
import 'package:cheapest_go_mobile/shared/search/destinations_api.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_scale.dart';

/// The controls inside the search steps. See #38.
///
/// Public rather than private to the step search only because they live in their own file;
/// nothing outside the landing should use them.

/// One suggestion: its code in a chip, the place in bold, and what it actually is beneath —
/// "MNL · Manila · Ninoy Aquino International Airport · Philippines".
class PlaceRow extends StatelessWidget {
    const PlaceRow({required this.option, required this.onTap, super.key});

    final DestinationSuggestion option;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        final code = option.iata;
        final detail = [
            option.name,
            if (option.countryCode.isNotEmpty) option.countryCode,
        ].join(' · ');

        return InkWell(
            onTap: onTap,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: TwSpace.of(2.5)),
                child: Row(
                    children: [
                        if (code != null) ...[
                            Container(
                                width: 42,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: const Color(0x1FFFFFFF),
                                    borderRadius: BorderRadius.circular(TwRadius.md),
                                ),
                                child: Text(
                                    code,
                                    style: TextStyle(
                                        fontSize: TwText.xs.size,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                    ),
                                ),
                            ),
                            SizedBox(width: TwSpace.of(3)),
                        ],
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        option.city ?? option.name,
                                        style: TextStyle(
                                            fontSize: TwText.sm.size,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                        ),
                                    ),
                                    Text(
                                        detail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: TwText.xs.size, color: Colors.white60),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/// A month, drawn rather than opened: V2 shows the calendar inside the step, not behind a
/// button that summons the platform picker.
class MonthCalendar extends StatelessWidget {
    const MonthCalendar({
        required this.month,
        required this.range,
        required this.onMonth,
        required this.onPick,
        super.key,
    });

    final DateTime month;
    final DateTimeRange? range;
    final ValueChanged<DateTime> onMonth;
    final ValueChanged<DateTime> onPick;

    /// Sunday first, as the reference draws it.
    static const _dayInitials = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
    static const _monthNames = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
    ];

    bool _inRange(DateTime day) {
        final r = range;
        if (r == null) return false;
        return !day.isBefore(r.start) && !day.isAfter(r.end);
    }

    /// The two days a person actually chose — the night they arrive and the night they leave.
    ///
    /// V2 draws these with `ACCENT`, which is the brand gradient, and washes the days between
    /// them instead. Filling the whole range with one flat blue says the eight nights were
    /// each picked, and loses the two that were.
    bool _isEdge(DateTime day) {
        final r = range;
        if (r == null) return false;
        return day == DateUtils.dateOnly(r.start) || day == DateUtils.dateOnly(r.end);
    }

    @override
    Widget build(BuildContext context) {
        final today = DateUtils.dateOnly(DateTime.now());
        final first = DateTime(month.year, month.month);
        final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
        final leading = first.weekday % 7;

        return Column(
            children: [
                Row(
                    children: [
                        RoundBlueButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Previous month',
                            onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
                        ),
                        Expanded(
                            child: Text(
                                '${_monthNames[month.month - 1]} ${month.year}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: TwText.base.size,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                ),
                            ),
                        ),
                        RoundBlueButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Next month',
                            onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
                        ),
                    ],
                ),
                SizedBox(height: TwSpace.of(2)),
                Row(
                    children: [
                        for (final d in _dayInitials)
                            Expanded(
                                child: Text(
                                    d,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: TwText.xs.size, color: Colors.white54),
                                ),
                            ),
                    ],
                ),
                SizedBox(height: TwSpace.of(1)),
                for (var week = 0; week * 7 < leading + daysInMonth; week++)
                    Row(
                        children: [
                            for (var slot = 0; slot < 7; slot++)
                                Expanded(
                                    child: Builder(builder: (_) {
                                        final dayNumber = week * 7 + slot - leading + 1;
                                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                                            return const SizedBox(height: 36);
                                        }
                                        final day = DateTime(month.year, month.month, dayNumber);
                                        // A day already gone is shown, not hidden — the shape of
                                        // the month is part of reading it — but it is not a choice.
                                        final past = day.isBefore(today);
                                        final selected = _inRange(day);
                                        final edge = _isEdge(day);
                                        return InkWell(
                                            onTap: past ? null : () => onPick(day),
                                            borderRadius: BorderRadius.circular(TwRadius.md),
                                            child: Container(
                                                height: 36,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    // The chosen nights wear the gradient;
                                                    // the ones between them are washed.
                                                    gradient: edge ? brandGradient : null,
                                                    color: edge
                                                        ? null
                                                        : selected
                                                            ? const Color(0x1FFFFFFF)
                                                            : null,
                                                    borderRadius: BorderRadius.circular(TwRadius.md),
                                                    border: day == today && !selected
                                                        ? Border.all(color: const Color(0x66FFFFFF))
                                                        : null,
                                                ),
                                                child: Text(
                                                    '$dayNumber',
                                                    style: TextStyle(
                                                        fontSize: TwText.sm.size,
                                                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                                        color: past ? Colors.white24 : Colors.white,
                                                    ),
                                                ),
                                            ),
                                        );
                                    }),
                                ),
                        ],
                    ),
            ],
        );
    }
}

/// Adults or children: the name, who that means, and a round button either side of the count.
class Counter extends StatelessWidget {
    const Counter({
        required this.label,
        required this.sublabel,
        required this.value,
        required this.fewerLabel,
        required this.moreLabel,
        required this.onChanged,
        super.key,
    });

    final String label;
    final String sublabel;
    final int value;
    final String fewerLabel;
    final String moreLabel;
    final ValueChanged<int> onChanged;

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: EdgeInsets.symmetric(vertical: TwSpace.of(3)),
            child: Row(
                children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    label,
                                    style: TextStyle(
                                        fontSize: TwText.base.size,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                    ),
                                ),
                                Text(
                                    sublabel,
                                    style: TextStyle(fontSize: TwText.xs.size, color: Colors.white60),
                                ),
                            ],
                        ),
                    ),
                    RoundBlueButton(
                        icon: Icons.remove_rounded,
                        tooltip: fewerLabel,
                        onPressed: () => onChanged(value - 1),
                    ),
                    SizedBox(
                        width: 44,
                        child: Text(
                            '$value',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: TwText.base.size,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                            ),
                        ),
                    ),
                    RoundBlueButton(
                        icon: Icons.add_rounded,
                        tooltip: moreLabel,
                        onPressed: () => onChanged(value + 1),
                    ),
                ],
            ),
        );
    }
}
