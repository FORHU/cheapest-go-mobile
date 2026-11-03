import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// Bottom sheet listing airports; returns the picked code. Lists the arrival
/// airports unless [departures] is set, then the airports you can fly from.
Future<String?> showAirportPicker(
  BuildContext context, {
  required String selected,
  TravelCatalog catalog = travelCatalog,
  bool departures = false,
}) {
  final airports = departures ? catalog.origins() : catalog.airports();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(departures ? 'Flying from' : 'Arrival airport', style: Theme.of(context).textTheme.titleLarge),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (final a in airports)
                      ListTile(
                        onTap: () => Navigator.pop(context, a.code),
                        leading: SizedBox(
                          width: 52,
                          child: Text(
                            a.code,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: c.accent),
                          ),
                        ),
                        title: Text(a.city, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${a.name} · ${a.country}', style: TextStyle(color: c.textMuted)),
                        trailing: a.code == selected ? Icon(Icons.check_rounded, color: c.accent) : null,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
