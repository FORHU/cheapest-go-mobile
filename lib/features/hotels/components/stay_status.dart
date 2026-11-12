import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_chrome.dart';

/// Looking, found nothing, or could not ask — as V2's `StatusScreen` draws all three.
///
/// One shape for the three states, because they differ only in what they say and whether the
/// ring is turning. V2 covers the whole results surface with it rather than putting a spinner
/// in a corner: until there is something to show, the screen's subject is the waiting.
class StayStatus extends StatelessWidget {
    const StayStatus({
        required this.title,
        required this.lines,
        this.busy = false,
        this.action,
        this.actionLabel,
        super.key,
    });

    final String title;
    final List<String> lines;

    /// Turns the ring. False for an outcome, true while the answer is still coming.
    final bool busy;
    final VoidCallback? action;
    final String? actionLabel;

    @override
    Widget build(BuildContext context) {
        final skin = StaySkin.of(context);

        return ColoredBox(
            color: skin.surface,
            child: Center(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                        DecoratedBox(
                                            decoration: BoxDecoration(color: skin.chipBg, shape: BoxShape.circle),
                                            child: const SizedBox.expand(),
                                        ),
                                        if (busy)
                                            Padding(
                                                padding: const EdgeInsets.all(5),
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    backgroundColor: skin.chipTrack,
                                                    valueColor: AlwaysStoppedAnimation(skin.chipText),
                                                ),
                                            ),
                                        Icon(Icons.apartment_rounded, size: 24, color: skin.chipText),
                                    ],
                                ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: skin.title),
                            ),
                            for (final (i, line) in lines.indexed) ...[
                                SizedBox(height: i == 0 ? 10 : 6),
                                Text(
                                    line,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, height: 1.4, color: skin.muted),
                                ),
                            ],
                            if (action != null && actionLabel != null) ...[
                                const SizedBox(height: 32),
                                Material(
                                    color: skin.chipBg,
                                    borderRadius: BorderRadius.circular(100),
                                    elevation: 6,
                                    shadowColor: const Color(0x47000000),
                                    child: InkWell(
                                        onTap: action,
                                        borderRadius: BorderRadius.circular(100),
                                        child: Container(
                                            height: 62,
                                            alignment: Alignment.center,
                                            padding: const EdgeInsets.symmetric(horizontal: 52),
                                            child: Text(
                                                actionLabel!,
                                                style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w500,
                                                    color: skin.chipText,
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                            ],
                        ],
                    ),
                ),
            ),
        );
    }
}
