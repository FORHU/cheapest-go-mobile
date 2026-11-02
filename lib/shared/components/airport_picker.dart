import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/theme/tokens/app_colors.dart';

/// Bottom sheet listing the arrival airports; returns the picked code.
Future<String?> showAirportPicker(
  BuildContext context, {
  required String selected,
  TravelCatalog catalog = travelCatalog,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final c = context.colors;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Arrival airport', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final a in catalog.airports())
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
                subtitle: Text(a.name, style: TextStyle(color: c.textMuted)),
                trailing: a.code == selected ? Icon(Icons.check_rounded, color: c.accent) : null,
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
