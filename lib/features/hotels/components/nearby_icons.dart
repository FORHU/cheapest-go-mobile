import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:cheapest_go_mobile/shared/search/nearby_api.dart';

/// The glyphs V2 puts to places and to the filters that choose them. See #40.
///
/// V2's `POI_FILTERS` names one lucide icon per category — a fork for food, a cup for a café,
/// a landmark for an attraction — and the same glyph marks the place on the map and the filter
/// above it, so a reader learns the key once.

/// The filter's icon, as `map-discovery.ts` assigns it.
IconData iconForCategory(NearbyCategory category) => switch (category) {
    NearbyCategory.all => LucideIcons.search,
    NearbyCategory.restaurant => LucideIcons.utensils,
    NearbyCategory.cafe => LucideIcons.coffee,
    NearbyCategory.attraction => LucideIcons.landmark,
    NearbyCategory.grocery => LucideIcons.shoppingBasket,
    NearbyCategory.medical => LucideIcons.pill,
    NearbyCategory.transit => LucideIcons.bus,
};

/// A place's own icon, from the Google type api-v2 passes through.
///
/// A type this does not know falls back to a map pin rather than to the "all" magnifier: a
/// magnifying glass on the map would read as a control, and this is a place.
IconData iconForPoi(String type) => switch (type) {
    'restaurant' || 'meal_takeaway' || 'meal_delivery' => LucideIcons.utensils,
    'bar' || 'night_club' => LucideIcons.wine,
    'cafe' || 'bakery' => LucideIcons.coffee,
    'museum' || 'art_gallery' || 'tourist_attraction' || 'amusement_park' || 'zoo' || 'aquarium' =>
        LucideIcons.landmark,
    'park' => LucideIcons.trees,
    'supermarket' || 'grocery_or_supermarket' || 'convenience_store' || 'store' =>
        LucideIcons.shoppingBasket,
    'pharmacy' || 'hospital' || 'doctor' => LucideIcons.pill,
    'bus_station' || 'subway_station' || 'train_station' || 'transit_station' => LucideIcons.bus,
    _ => LucideIcons.mapPin,
};
