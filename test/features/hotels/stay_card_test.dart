import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_test/flutter_test.dart';

import 'package:cheapest_go_mobile/features/hotels/components/stay_card_painter.dart';
import 'package:cheapest_go_mobile/features/hotels/components/stay_map_card.dart';
import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';

/// The **Stay Card** now that the map draws it (ADR-0008).
///
/// There is no widget to tap, so what has to hold is the pair underneath: the geometry, which
/// says what a press landed on, and the model, which says what is painted. They are the whole
/// of the card's behaviour — the picture itself is proved on a device.
Hotel _stay({List<String> photos = const []}) => Hotel(
  id: 'h1',
  airportCode: 'MNL',
  name: 'Bayside Grand Manila',
  area: 'Malate',
  distanceKm: 1,
  distanceFrom: 'MNL',
  score: 8.7,
  reviews: 412,
  tags: const [],
  rooms: const [Room(id: 'r1', name: 'Deluxe', meta: 'Room only', nightlyRate: 88677)],
  images: photos,
  address: '1225 A. Mabini Street, Malate',
);

void main() {
  group('what a press on the card lands on', () {
    const gallery = StayCardGeometry(photos: 4);

    test('the middle of the card is the way through to the stay', () {
      expect(
        gallery.hitTest(const Offset(stayMapCardWidth / 2, stayMapCardHeight / 2)),
        StayCardPress.open,
      );
    });

    test('the close disc closes rather than opening', () {
      expect(gallery.hitTest(gallery.close.center), StayCardPress.close);
    });

    test('the arrows page, and page the right way', () {
      expect(gallery.hitTest(gallery.previous!.center), StayCardPress.previous);
      expect(gallery.hitTest(gallery.next!.center), StayCardPress.next);
      expect(gallery.previous!.center.dx, lessThan(gallery.next!.center.dx));
    });

    /// The copy sits across the foot of the card, which is also where a right-handed thumb
    /// lands. Nothing there may page or close — it opens the stay, like the rest of the body.
    test('the copy at the foot is body, not controls', () {
      expect(
        gallery.hitTest(const Offset(stayMapCardWidth - 20, stayMapCardHeight - 30)),
        StayCardPress.open,
      );
    });

    /// V2 draws no arrows for a single picture rather than two controls that do nothing, so
    /// there is nothing there to press either.
    test('a single photo has no arrows to hit', () {
      const single = StayCardGeometry(photos: 1);
      expect(single.previous, isNull);
      expect(single.next, isNull);
      expect(
        single.hitTest(const Offset(20, stayMapCardHeight * 0.32)),
        StayCardPress.open,
      );
    });

    /// A finger is wider than a 24px disc. The close control answers for a little more than it
    /// draws — but not so much that it eats the photograph beside it.
    test('the close disc forgives a near miss without swallowing the card', () {
      expect(gallery.hitTest(gallery.close.center + const Offset(14, 14)), StayCardPress.close);
      expect(gallery.hitTest(gallery.close.center + const Offset(40, 40)), StayCardPress.open);
    });
  });

  group('the gallery the card paints', () {
    test('no stay means nothing to paint', () {
      final card = StayCardModel();
      addTearDown(card.dispose);

      expect(card.hotel, isNull);
      expect(card.photos, isEmpty);
    });

    test('a stay with one picture cannot be paged', () {
      final card = StayCardModel()..show(_stay(photos: const ['https://example.test/1.jpg']));
      addTearDown(card.dispose);

      expect(card.photos, hasLength(1));
      card.page(1);
      expect(card.shown, 0, reason: 'there is nowhere to page to');
    });

    test('paging wraps in both directions', () {
      final card = StayCardModel()
        ..show(_stay(photos: const [
          'https://example.test/1.jpg',
          'https://example.test/2.jpg',
          'https://example.test/3.jpg',
        ]));
      addTearDown(card.dispose);

      expect(card.shown, 0);
      card.page(1);
      expect(card.shown, 1);
      card.page(-1);
      card.page(-1);
      expect(card.shown, 2, reason: 'back past the first picture is the last one');
    });

    test('showing another stay starts its gallery over', () {
      final card = StayCardModel()
        ..show(_stay(photos: const ['https://example.test/1.jpg', 'https://example.test/2.jpg']));
      addTearDown(card.dispose);

      card.page(1);
      expect(card.shown, 1);

      card.show(Hotel(
        id: 'h2',
        airportCode: 'MNL',
        name: 'Another',
        area: 'Malate',
        distanceKm: 1,
        distanceFrom: 'MNL',
        score: 8,
        reviews: 10,
        tags: const [],
        rooms: const [],
        images: const ['https://example.test/x.jpg', 'https://example.test/y.jpg'],
      ));
      expect(card.shown, 0);
      expect(card.hotel!.id, 'h2');
    });

    test('closing the card lets go of the stay', () {
      final card = StayCardModel()..show(_stay(photos: const ['https://example.test/1.jpg']));
      addTearDown(card.dispose);

      card.show(null);
      expect(card.hotel, isNull);
      expect(card.photos, isEmpty);
    });
  });

  group('the picture the map carries', () {
    setUp(WidgetsFlutterBinding.ensureInitialized);

    test('is the artboard, at the screen\'s own scale', () async {
      final painted = await const StayCardPainter(ratio: 3).paint(
        name: 'Bayside Grand Manila',
        address: '1225 A. Mabini Street, Malate',
        price: '₩88,677/박',
        rating: '8.7 평점',
        photo: null,
        photos: 1,
        shown: 0,
      );

      // The size it reports is what it occupies on screen; the bytes are three times that in
      // each direction, because Mapbox draws an annotation's bitmap one pixel to one device
      // pixel and a card drawn at logical size would be soft.
      expect(painted.size.width, stayMapCardWidth);
      expect(painted.size.height, stayMapCardHeight);
      expect(painted.bytes, isNotEmpty);
    });

    test('paints without a photograph, and without a rating', () async {
      final painted = await const StayCardPainter(ratio: 1).paint(
        name: 'A stay with no pictures and no score yet',
        address: '',
        price: '₩88,677/박',
        rating: null,
        photo: null,
        photos: 0,
        shown: 0,
      );
      expect(painted.bytes, isNotEmpty);
    });
  });
}
