import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart'
    show ImageConfiguration, ImageStream, ImageStreamListener, NetworkImage;

import 'package:cheapest_go_mobile/shared/catalog/travel_catalog.dart';
import 'package:cheapest_go_mobile/shared/stores/trip_search_store.dart';

/// V2's artboard is 234 × 268 and this is that shape, drawn larger.
///
/// The web card sits beside a list; on a handset it is the only thing on the map and it was
/// read as small — a photograph that size shows a lobby, not a room. Everything on the card is
/// derived from [stayMapCardScale] rather than re-typed, so the proportions stay V2's and the
/// size is one number to argue about.
///
/// Why not larger still: the card is **Map-Locked** to its pin, so its width is what the
/// camera must ease sideways to reveal when a stay sits near the edge of the screen. At 286 on
/// a 390-wide phone that is already most of the screen, and every point past it is more of the
/// map moving under someone who only tapped a pin.
const double stayMapCardScale = 286 / 234;

/// `CARD_W` and `CARD_H`. The height is fixed because the photo is the card: there is no panel
/// for it to size itself to.
const double stayMapCardWidth = 234 * stayMapCardScale;
const double stayMapCardHeight = 268 * stayMapCardScale;

/// `PIN_CLEARANCE`. How far above its coordinate the card floats: the selected pin stands about
/// 56 logical pixels tall, plus a little air.
const double stayMapCardPinClearance = 62;

/// `RAIL_GUTTER_MOBILE`, which V2 keeps as the map screen's margin: how far the count plate
/// stands off the edges, and how much air the camera leaves around a card it eases into view.
const double mapGutter = 20;

/// `AUTOPLAY_MS`: long enough to look at a room, short enough that a card held open shows more
/// than one.
const Duration _autoplay = Duration(milliseconds: 3400);

/// The **Stay Card**'s state: which stay it stands for, its photography, and where the gallery
/// has got to.
///
/// Not a widget. The card is painted into the map (ADR-0008), so what used to be widget state
/// lives here and the map repaints whenever this says something has changed — a photograph
/// arriving, the gallery advancing, a different stay selected.
class StayCardModel extends ChangeNotifier {
    StayCardModel({this.catalog});

    /// Where the room photography is fetched from, when there is more of it than the search
    /// sent. Null in tests, which leaves the card on the stay's own picture.
    final TravelCatalog? catalog;

    Hotel? _hotel;
    Hotel? get hotel => _hotel;

    /// The property's own gallery, once it has landed.
    ///
    /// The search sends one picture per stay — api-v2 serves `images[0]` through its photo
    /// proxy — so the card opens on that and upgrades in place, which is what V2 does with
    /// `useHotelContent`. One request per card actually opened, not one per pin on screen.
    List<String> _gallery = const [];

    List<String> get photos => _gallery.isNotEmpty ? _gallery : (_hotel?.photos ?? const []);

    int _index = 0;

    int get shown => photos.isEmpty ? 0 : ((_index % photos.length) + photos.length) % photos.length;

    /// Once the traveller pages the gallery themselves the timer stops for good: a carousel
    /// that keeps pulling ahead while someone works back through it is fighting them. V2 cites
    /// WCAG 2.2.2 for the same behaviour.
    bool _userPaging = false;

    Timer? _timer;

    /// The photograph now on the card, decoded and ready to paint. Null until the first one
    /// arrives, which is what the stand-in ground is for.
    ui.Image? _photo;
    ui.Image? get photo => _photo;

    ImageStream? _stream;
    ImageStreamListener? _listener;

    /// Opens the card on [hotel], or closes it when given nothing.
    void show(Hotel? hotel) {
        if (hotel?.id == _hotel?.id) return;

        _hotel = hotel;
        _index = 0;
        _userPaging = false;
        _gallery = const [];
        _releasePhoto();
        _timer?.cancel();

        notifyListeners();
        if (hotel == null) return;

        _loadPhoto();
        _arm();
        _loadGallery();
    }

    void page(int step) {
        if (photos.length < 2) return;
        _userPaging = true;
        _timer?.cancel();
        _index = shown + step;
        _loadPhoto();
        notifyListeners();
    }

    @override
    void dispose() {
        _timer?.cancel();
        _releasePhoto();
        super.dispose();
    }

    /// A timeout re-armed on every change rather than an interval, so a photograph reached by
    /// pressing an arrow gets the same full dwell as one the timer brought up.
    void _arm() {
        _timer?.cancel();
        if (photos.length < 2 || _userPaging) return;
        _timer = Timer(_autoplay, () {
            _index++;
            _loadPhoto();
            notifyListeners();
            _arm();
        });
    }

    /// Decoded here rather than handed to a widget, because the card is a picture and a
    /// picture needs the pixels, not an `Image`.
    void _loadPhoto() {
        final photos = this.photos;
        if (photos.isEmpty) return;

        final wanted = photos[shown];
        final stream = NetworkImage(wanted).resolve(ImageConfiguration.empty);
        final listener = ImageStreamListener(
            (info, _) {
                // The gallery may have moved on while this was in flight.
                if (photos.isEmpty || wanted != this.photos[shown]) {
                    info.image.dispose();
                    return;
                }
                _photo?.dispose();
                _photo = info.image;
                notifyListeners();
            },
            // A card whose photograph will not load keeps its stand-in ground, which is what V2
            // falls back to as well. Nothing here is worth surfacing.
            onError: (_, _) {},
        );

        _releaseStream();
        _stream = stream;
        _listener = listener;
        stream.addListener(listener);
    }

    /// Asked for with the dates that were searched, so the property call this warms is the one
    /// the stay's own page would make anyway rather than a second, differently-dated copy.
    void _loadGallery() {
        final catalog = this.catalog;
        final hotel = _hotel;
        if (catalog == null || hotel == null) return;

        final id = hotel.id;
        final s = tripSearchStore;
        catalog.fetchHotel(id, checkIn: s.checkIn, checkOut: s.checkOut, adults: s.adults).then(
            (fetched) {
                // The card may already have moved to another pin.
                if (fetched == null || _hotel?.id != id) return;
                if (fetched.images.length > 1) {
                    _gallery = fetched.images;
                    _arm();
                    notifyListeners();
                }
            },
            // A preview that cannot load its gallery still shows the picture it opened with.
            onError: (_, _) {},
        );
    }

    void _releaseStream() {
        final stream = _stream;
        final listener = _listener;
        if (stream != null && listener != null) stream.removeListener(listener);
        _stream = null;
        _listener = null;
    }

    void _releasePhoto() {
        _releaseStream();
        _photo?.dispose();
        _photo = null;
    }
}
