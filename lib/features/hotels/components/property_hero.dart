import 'package:flutter/material.dart';

import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// The property page's opening: the photographs, with the hotel's name and address standing
/// on them. See #40 and V2's `property-view.tsx`.
///
/// Full-bleed rather than a framed gallery, because V2 opens on the picture and lets the page
/// start underneath it. The photograph does not move with the page — the content scrolls over
/// it — and the dots under the name say how many there are.
class PropertyHero extends StatefulWidget {
    const PropertyHero({
        required this.hotel,
        required this.onBack,
        required this.onToggleTheme,
        super.key,
    });

    final Hotel hotel;
    final VoidCallback onBack;
    final VoidCallback onToggleTheme;

    /// Tall enough to be the page's opening image, short enough that the description under it
    /// is visible without scrolling on a phone.
    static const height = 420.0;

    @override
    State<PropertyHero> createState() => _PropertyHeroState();
}

class _PropertyHeroState extends State<PropertyHero> {
    final _pages = PageController();
    int _at = 0;

    @override
    void dispose() {
        _pages.dispose();
        super.dispose();
    }

    List<String> get _photos => widget.hotel.photos;

    @override
    Widget build(BuildContext context) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final top = MediaQuery.viewPaddingOf(context).top;

        return SizedBox(
            height: PropertyHero.height,
            child: Stack(
                fit: StackFit.expand,
                children: [
                    PageView.builder(
                        controller: _pages,
                        itemCount: _photos.isEmpty ? 1 : _photos.length,
                        onPageChanged: (i) => setState(() => _at = i),
                        itemBuilder: (context, i) => _photos.isEmpty
                            ? ColoredBox(color: dark ? const Color(0xFF111827) : const Color(0xFFE2E8F0))
                            : Image.network(
                                _photos[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => ColoredBox(
                                    color: dark ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
                                    child: Icon(
                                        Icons.apartment_rounded,
                                        size: 40,
                                        color: dark ? Colors.white24 : Colors.black26,
                                    ),
                                ),
                            ),
                    ),

                    // The name sits on the photograph, so the foot of it darkens enough to
                    // read against whatever the picture happens to be.
                    const Positioned.fill(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x66000000), Color(0x00000000), Color(0xCC000000)],
                                    stops: [0, 0.45, 1],
                                ),
                            ),
                        ),
                    ),

                    Positioned(
                        top: top + 8,
                        left: 12,
                        right: 12,
                        child: Row(
                            children: [
                                _Round(icon: Icons.arrow_back_rounded, onTap: widget.onBack),
                                const Spacer(),
                                _Round(
                                    icon: dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    onTap: widget.onToggleTheme,
                                ),
                            ],
                        ),
                    ),

                    Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    widget.hotel.name,
                                    style: const TextStyle(
                                        fontSize: 26,
                                        height: 1.15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.5,
                                        color: Colors.white,
                                        shadows: [Shadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 4))],
                                    ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    // The street address as the design has it, and only the
                                    // city and country when the supplier sent no street.
                                    widget.hotel.address?.isNotEmpty == true
                                        ? widget.hotel.address!
                                        : widget.hotel.area,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xE6FFFFFF),
                                        shadows: [Shadow(color: Color(0x73000000), blurRadius: 12, offset: Offset(0, 2))],
                                    ),
                                ),
                                if (_photos.length > 1) ...[
                                    const SizedBox(height: 14),
                                    // One dot per photograph, however many there are.
                                    Center(
                                        child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                                for (var i = 0; i < _photos.length; i++)
                                                    GestureDetector(
                                                        onTap: () => _pages.animateToPage(
                                                            i,
                                                            duration: const Duration(milliseconds: 240),
                                                            curve: Curves.easeOut,
                                                        ),
                                                        child: Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                color: i == _at ? Colors.white : const Color(0x80FFFFFF),
                                                            ),
                                                        ),
                                                    ),
                                            ],
                                        ),
                                    ),
                                ],
                            ],
                        ),
                    ),
                ],
            ),
        );
    }
}

class _Round extends StatelessWidget {
    const _Round({required this.icon, required this.onTap});

    final IconData icon;
    final VoidCallback onTap;

    @override
    Widget build(BuildContext context) {
        return Material(
            color: const Color(0x4D000000),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap,
                child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: Colors.white)),
            ),
        );
    }
}
