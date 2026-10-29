// Hotel Domain Contracts — aligned with `cheapestgo-api-v2` (`/api/v2/hotels/*`):
// - Stay Total (`stayTotal`) vs Nightly Rate (`price`, divided server-side)
// - Offer / Rate (`offerId`)
// - Prebook (`prebookId`, authoritative price, `display.chargedTotal`, currency, cancellation policy)
// - Property detail (`GET /api/v2/hotels/property/:id` -> `{ content, reviews, reviewItems, rooms }`)

class DestinationSuggestion {
  const DestinationSuggestion({
    required this.type,
    required this.title,
    required this.subtitle,
    this.rung,
    this.countryCode,
    this.id,
    this.code,
    this.lat,
    this.lng,
  });

  final String type;
  final String? rung;
  final String title;
  final String subtitle;
  final String? countryCode;
  final String? id;
  final String? code;
  final double? lat;
  final double? lng;

  factory DestinationSuggestion.fromJson(Map<String, dynamic> json) {
    return DestinationSuggestion(
      type: (json['type'] ?? 'city').toString(),
      rung: json['rung']?.toString(),
      title: (json['title'] ?? json['label'] ?? json['name'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      countryCode: json['countryCode']?.toString(),
      id: json['id']?.toString(),
      code: json['code']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}

class HotelSearchParams {
  const HotelSearchParams({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    this.countryCode,
    this.placeId,
    this.destinationCode,
    this.lat,
    this.lng,
    this.adults = 2,
    this.children = 0,
    this.rooms = 1,
    this.currency = 'USD',
  });

  final String destination;
  final String? countryCode;
  final String? placeId;
  final String? destinationCode;
  final double? lat;
  final double? lng;
  final String checkIn;
  final String checkOut;
  final int adults;
  final int children;
  final int rooms;
  final String currency;
}

class RoomOfferRate {
  const RoomOfferRate({
    required this.offerId,
    required this.roomName,
    required this.stayTotal,
    required this.nightlyRate,
    required this.currency,
    this.refundable = false,
    this.boardName,
  });

  final String offerId;
  final String roomName;
  final double stayTotal;
  final double nightlyRate;
  final String currency;
  final bool refundable;
  final String? boardName;

  factory RoomOfferRate.fromJson(
    Map<String, dynamic> json, {
    String? parentRoomName,
    String fallbackCurrency = 'USD',
  }) {
    // In `cheapestgo-api-v2`, `stayTotal` is the full stay price and `price` is the nightly rate.
    final hasStayTotal = json['stayTotal'] != null || json['totalPrice'] != null;
    final rawStayTotal =
        (json['stayTotal'] ?? json['totalPrice'] ?? json['price'] ?? 0) as num;
    final rawNightly = hasStayTotal
        ? (json['price'] ?? json['nightlyRate'] ?? json['pricePerNight'] ?? rawStayTotal) as num
        : (json['nightlyRate'] ?? json['pricePerNight'] ?? rawStayTotal) as num;

    final tgxMeta = json['_tgx'] as Map<String, dynamic>?;
    final resolvedOfferId =
        (json['offerId'] ?? tgxMeta?['token'] ?? json['id'] ?? '').toString();
    final refTag = json['refundableTag']?.toString().toUpperCase();
    final isRefundable = json['refundable'] == true ||
        refTag == 'RFN' ||
        refTag == 'REFUNDABLE';

    return RoomOfferRate(
      offerId: resolvedOfferId,
      roomName: (json['roomName'] ??
              json['name'] ??
              parentRoomName ??
              'Standard Room')
          .toString(),
      stayTotal: rawStayTotal.toDouble(),
      nightlyRate: rawNightly.toDouble(),
      currency: (json['currency'] ?? fallbackCurrency).toString(),
      refundable: isRefundable,
      boardName: (json['boardName'] ??
              json['boardCode'] ??
              tgxMeta?['boardCode'])
          ?.toString(),
    );
  }
}

class HotelSummary {
  const HotelSummary({
    required this.hotelId,
    required this.name,
    required this.city,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.stayTotal,
    required this.nightlyRate,
    required this.currency,
    this.starRating = 4,
    this.reviewRating,
    this.reviewsCount = 0,
    this.imageUrl,
    this.offers = const [],
  });

  final String hotelId;
  final String name;
  final String city;
  final String countryCode;
  final double latitude;
  final double longitude;
  final double stayTotal;
  final double nightlyRate;
  final String currency;
  final int starRating;
  final double? reviewRating;
  final int reviewsCount;
  final String? imageUrl;
  final List<RoomOfferRate> offers;

  factory HotelSummary.fromJson(Map<String, dynamic> json) {
    final details = json['details'] as Map<String, dynamic>?;
    final coords = json['coordinates'] as Map<String, dynamic>?;
    final lat = (json['lat'] ??
            json['latitude'] ??
            coords?['lat'] ??
            details?['latitude'] ??
            0) as num;
    final lng = (json['lng'] ??
            json['longitude'] ??
            coords?['lng'] ??
            details?['longitude'] ??
            0) as num;

    // `cheapestgo-api-v2` search attaches `stayTotal` alongside nightly `price` (ADR-0020).
    final hasStayTotal = json['stayTotal'] != null || json['totalPrice'] != null;
    final rawStayTotal = (json['stayTotal'] ??
            json['totalPrice'] ??
            json['minPrice'] ??
            json['price'] ??
            120) as num;
    final rawNightly = hasStayTotal
        ? (json['price'] ?? json['nightlyRate'] ?? json['pricePerNight'] ?? rawStayTotal) as num
        : (json['nightlyRate'] ?? json['pricePerNight'] ?? rawStayTotal) as num;

    final currency = (json['currency'] ?? 'USD').toString();
    final rawOffers =
        json['offers'] ?? json['rooms'] ?? json['roomTypes'] ?? const [];
    final offersList = <RoomOfferRate>[];

    if (rawOffers is List) {
      for (final item in rawOffers.whereType<Map<String, dynamic>>()) {
        final roomName = (item['roomName'] ?? item['name'] ?? 'Standard Room').toString();
        final nestedRates = item['rates'];
        if (nestedRates is List && nestedRates.isNotEmpty) {
          for (final rate in nestedRates.whereType<Map<String, dynamic>>()) {
            final parsed = RoomOfferRate.fromJson(
              rate,
              parentRoomName: roomName,
              fallbackCurrency: currency,
            );
            if (parsed.offerId.isNotEmpty) {
              offersList.add(parsed);
            }
          }
        }
        if (offersList.isEmpty || item['offerId'] != null) {
          final direct = RoomOfferRate.fromJson(
            item,
            parentRoomName: roomName,
            fallbackCurrency: currency,
          );
          if (direct.offerId.isNotEmpty) {
            offersList.add(direct);
          }
        }
      }
    }

    // Fallback: if listing has a top-level `offerId` and no nested `offersList`, synthesize one
    final topOfferId = (json['offerId'] ?? json['_tgxToken'] ?? '').toString();
    if (offersList.isEmpty && topOfferId.isNotEmpty) {
      final refTag = json['refundableTag']?.toString().toUpperCase();
      offersList.add(
        RoomOfferRate(
          offerId: topOfferId,
          roomName: 'Standard Room',
          stayTotal: rawStayTotal.toDouble(),
          nightlyRate: rawNightly.toDouble(),
          currency: currency,
          refundable: refTag == 'RFN' || refTag == 'REFUNDABLE',
          boardName: json['boardCode']?.toString(),
        ),
      );
    }

    final images = json['images'];
    final firstImage =
        images is List && images.isNotEmpty ? images.first?.toString() : null;

    return HotelSummary(
      hotelId: (json['hotelId'] ?? json['hotel_id'] ?? json['hotelCode'] ?? json['id'] ?? '')
          .toString(),
      name: (json['name'] ?? details?['name'] ?? 'Hotel Property').toString(),
      city: (json['city'] ?? details?['city'] ?? '').toString(),
      countryCode: (json['country'] ??
              json['countryCode'] ??
              details?['countryCode'] ??
              '')
          .toString(),
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
      stayTotal: rawStayTotal.toDouble(),
      nightlyRate: rawNightly.toDouble(),
      currency: currency,
      starRating:
          ((json['starRating'] ?? json['star_rating'] ?? json['stars'] ?? 4) as num)
              .toInt(),
      reviewRating:
          ((json['reviewRating'] ?? json['rating']) as num?)?.toDouble(),
      reviewsCount:
          ((json['reviewsCount'] ?? json['reviewCount'] ?? json['reviews'] ?? 0) as num)
              .toInt(),
      imageUrl: (json['imageUrl'] ??
              json['image'] ??
              firstImage ??
              details?['mainImage'])
          ?.toString(),
      offers: offersList,
    );
  }

  /// Parses `GET /api/v2/hotels/property/:id` response `{ content, reviews, reviewItems, rooms }`
  factory HotelSummary.fromPropertyResponse(
    Map<String, dynamic> response, {
    HotelSummary? fallback,
    String currency = 'USD',
  }) {
    final content = (response['content'] as Map<String, dynamic>?) ?? response;
    final reviews = response['reviews'] as Map<String, dynamic>?;
    final rawRooms = response['rooms'];

    final offersList = <RoomOfferRate>[];
    if (rawRooms is List) {
      for (final room in rawRooms.whereType<Map<String, dynamic>>()) {
        final roomName =
            (room['name'] ?? room['roomName'] ?? 'Standard Room').toString();
        final roomCurrency = (room['currency'] ?? currency).toString();
        final rates = room['rates'];
        if (rates is List && rates.isNotEmpty) {
          for (final rate in rates.whereType<Map<String, dynamic>>()) {
            final parsed = RoomOfferRate.fromJson(
              rate,
              parentRoomName: roomName,
              fallbackCurrency: roomCurrency,
            );
            if (parsed.offerId.isNotEmpty) {
              offersList.add(parsed);
            }
          }
        } else {
          final parsed = RoomOfferRate.fromJson(
            room,
            parentRoomName: roomName,
            fallbackCurrency: roomCurrency,
          );
          if (parsed.offerId.isNotEmpty) {
            offersList.add(parsed);
          }
        }
      }
    }

    final resolvedOffers =
        offersList.isNotEmpty ? offersList : (fallback?.offers ?? const []);
    final bestOffer = resolvedOffers.firstOrNull;
    final images = content['images'];
    final firstImage =
        images is List && images.isNotEmpty ? images.first?.toString() : null;

    return HotelSummary(
      hotelId: (content['hotel_id'] ??
              content['hotelId'] ??
              fallback?.hotelId ??
              '')
          .toString(),
      name: (content['name'] ?? fallback?.name ?? 'Hotel Property').toString(),
      city: (content['city'] ?? fallback?.city ?? '').toString(),
      countryCode:
          (content['country'] ?? fallback?.countryCode ?? '').toString(),
      latitude: ((content['lat'] ?? fallback?.latitude ?? 0) as num).toDouble(),
      longitude:
          ((content['lng'] ?? fallback?.longitude ?? 0) as num).toDouble(),
      stayTotal: bestOffer?.stayTotal ?? fallback?.stayTotal ?? 0,
      nightlyRate: bestOffer?.nightlyRate ?? fallback?.nightlyRate ?? 0,
      currency: bestOffer?.currency ?? fallback?.currency ?? currency,
      starRating: ((content['star_rating'] ??
                  content['starRating'] ??
                  fallback?.starRating ??
                  4) as num)
          .toInt(),
      reviewRating: ((reviews?['rating'] ??
                  content['review_rating'] ??
                  fallback?.reviewRating) as num?)
          ?.toDouble(),
      reviewsCount: ((reviews?['reviews_count'] ??
                  content['review_count'] ??
                  fallback?.reviewsCount ??
                  0) as num)
          .toInt(),
      imageUrl: firstImage ?? fallback?.imageUrl,
      offers: resolvedOffers,
    );
  }

  Map<String, dynamic> toJson() => {
        'hotelId': hotelId,
        'name': name,
        'city': city,
        'countryCode': countryCode,
        'latitude': latitude,
        'longitude': longitude,
        'stayTotal': stayTotal,
        'nightlyRate': nightlyRate,
        'currency': currency,
        'starRating': starRating,
        'reviewRating': reviewRating,
        'reviewsCount': reviewsCount,
        'imageUrl': imageUrl,
      };
}

class PrebookQuote {
  const PrebookQuote({
    required this.prebookId,
    required this.authoritativePrice,
    required this.chargeCurrency,
    this.displayChargedTotal,
    this.serviceFee,
    this.refundableTag,
    this.boardCode,
    this.cancellationPolicies,
    this.roomSubstituted = false,
    this.substitutedRoomName,
  });

  final String prebookId;
  final double authoritativePrice;
  final String chargeCurrency;
  final double? displayChargedTotal;
  final double? serviceFee;
  final String? refundableTag;
  final String? boardCode;
  final Map<String, dynamic>? cancellationPolicies;
  final bool roomSubstituted;
  final String? substitutedRoomName;

  factory PrebookQuote.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final resolvedPrice = rawPrice is Map
        ? (rawPrice['total'] as num?)?.toDouble() ?? 0.0
        : (rawPrice as num?)?.toDouble() ?? 0.0;
    final display = json['display'] as Map<String, dynamic>?;
    final policies = json['cancellationPolicies'] as Map<String, dynamic>?;

    return PrebookQuote(
      prebookId: (json['prebookId'] ?? '').toString(),
      authoritativePrice:
          (display?['total'] as num?)?.toDouble() ?? resolvedPrice,
      chargeCurrency:
          (display?['currency'] ?? json['currency'] ?? 'USD').toString(),
      displayChargedTotal: (display?['chargedTotal'] as num?)?.toDouble(),
      serviceFee: (display?['serviceFee'] as num?)?.toDouble(),
      refundableTag: policies?['refundableTag']?.toString(),
      boardCode: json['boardCode']?.toString(),
      cancellationPolicies: policies,
      roomSubstituted: json['roomSubstituted'] == true,
      substitutedRoomName: json['substitutedRoomName']?.toString(),
    );
  }
}
