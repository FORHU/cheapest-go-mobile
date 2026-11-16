import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/features/flights/components/flight_chrome.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/generated/tw_palette.dart';

/// V2's `StateScreen`: an icon in a ring, a title, what to know, and what to do next.
class FlightStatus extends StatelessWidget {
  const FlightStatus({
    required this.icon,
    required this.title,
    required this.lines,
    this.action,
    this.secondary,
    super.key,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final (String, VoidCallback)? action;
  final (String, VoidCallback)? secondary;

  @override
  Widget build(BuildContext context) {
    final skin = FlightSkin.of(context);
    final dark = skin == FlightSkin.dark;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? const Color(0x14FFFFFF) : TwPalette.white,
            border: Border.all(color: skin.hairline),
          ),
          child: Icon(icon, size: 26, color: dark ? TwPalette.slate300 : TwPalette.slate600),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: skin.title),
        ),
        for (final line in lines) ...[
          const SizedBox(height: 6),
          Text(
            line,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: skin.muted),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 20),
          GradientPill(label: action!.$1, onTap: action!.$2, radius: 999),
        ],
        if (secondary != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: secondary!.$2,
            child: Text(
              secondary!.$1,
              style: TextStyle(color: skin.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

/// An amber note above the results: a fare that has gone, or a search that is slow.
class FlightNotice extends StatelessWidget {
  const FlightNotice({required this.icon, required this.title, required this.body, this.spinning = false, super.key});

  final IconData? icon;
  final String title;
  final String body;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? TwPalette.amber400 : TwPalette.amber600;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? TwPalette.amber950.withValues(alpha: 0.3) : TwPalette.amber50,
          border: Border.all(color: dark ? TwPalette.amber800 : TwPalette.amber200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: spinning
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: TwPalette.amber400),
                    )
                  : Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? TwPalette.amber200 : TwPalette.amber800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(body, style: TextStyle(fontSize: 12, color: dark ? TwPalette.amber300 : TwPalette.amber700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
