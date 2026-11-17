import 'package:flutter/widgets.dart';

/// What a **Tip** points at. See #62 and ADR-0006.
///
/// The things worth pointing at are spread across features — the search faces belong to Home,
/// the bar to the shell, the first result to hotels. A feature may not import another, and no
/// screen should have to know a Tip exists, so each one wraps the widget it is willing to have
/// pointed at and the Tip looks it up by name.
///
/// Registration is by id rather than by passing keys around because Tips live above the
/// router, and threading a key from the shell into a feature's private widgets would couple
/// the two in exactly the way the architecture forbids.
class TipAnchors {
  /// Stays · Flights · Golf, on Home.
  static const String searchFaces = 'home.searchFaces';

  /// The first step of the search — where someone is going.
  static const String searchStart = 'home.searchStart';

  /// The bottom bar: Home · Trips · Settings.
  static const String bottomBar = 'shell.bottomBar';

  // ── On the way to a booking (#62) ──────────────────────────────────────────
  // One per screen somebody passes through to book. Golf has none: a tee time is written to
  // the on-device store and never reaches Trips (ADR-0003), so there is nothing honest to
  // teach there.

  /// The first stay in the results list.
  static const String hotelResult = 'hotels.firstResult';

  /// The rooms on a property, which is what turns a stay into something bookable.
  static const String hotelRooms = 'hotel.rooms';

  /// Hotel checkout: what the price already includes.
  static const String hotelCheckout = 'checkout.total';

  /// The flight search, which asks five questions rather than three.
  static const String flightSearch = 'flights.search';

  /// Flight checkout: the card is authorised now and taken when the airline confirms.
  static const String flightCheckout = 'flightCheckout.total';

  /// Where a booking turns up afterwards.
  static const String trips = 'trips.list';
}

/// The live registry of anchors, keyed by id.
///
/// Entries come and go with the widgets themselves: a target on a screen nobody is looking at
/// has no position, and pointing at it would draw a box over empty space. The tour skips a
/// step whose anchor is missing rather than guessing where it used to be.
class TipAnchorRegistry {
  TipAnchorRegistry._();

  static final Map<String, GlobalKey> _anchors = {};

  /// Bumped whenever an anchor appears or goes. A Tip still waiting for its anchor listens
  /// to this rather than polling for it.
  ///
  /// Polling needed a deadline, and any deadline is a guess about how long somebody takes to
  /// arrive. Twenty seconds looked generous until a traveller signed up, chose a currency and
  /// typed a birth date first: by the time Home had a bottom bar, the Tip had given up. An
  /// anchor saying "I am here" has no such limit.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void register(String id, GlobalKey key) {
    _anchors[id] = key;
    revision.value++;
  }

  static void unregister(String id, GlobalKey key) {
    if (_anchors[id] != key) return;
    _anchors.remove(id);
    revision.value++;
  }

  /// Whether an anchor of this id exists at all.
  ///
  /// Distinct from having a position: an anchor registers during `initState`, before it has
  /// been laid out, so a Tip schedules itself on this and asks for the rectangle later.
  static bool has(String id) => _anchors.containsKey(id);

  /// Where the anchor is on screen, or null when it is not mounted or not laid out yet.
  static Rect? rectOf(String id) {
    final context = _anchors[id]?.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Only for tests: forget everything registered so far.
  @visibleForTesting
  static void clear() {
    _anchors.clear();
    revision.value++;
  }
}

/// Wraps a widget so a coach mark can point at it. Draws nothing itself.
class TipAnchor extends StatefulWidget {
  const TipAnchor({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<TipAnchor> createState() => _TipAnchorState();
}

class _TipAnchorState extends State<TipAnchor> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    TipAnchorRegistry.register(widget.id, _key);
  }

  /// An anchor whose id changed has to change its registration with it.
  ///
  /// Flutter reuses this State when the same widget position carries a different id — a
  /// screen switching which control it offers for pointing at. Without this the old id stays
  /// registered and the new one never is, so the Tip finds nothing and silently says nothing.
  @override
  void didUpdateWidget(TipAnchor old) {
    super.didUpdateWidget(old);
    if (old.id == widget.id) return;
    TipAnchorRegistry.unregister(old.id, _key);
    TipAnchorRegistry.register(widget.id, _key);
  }

  @override
  void dispose() {
    TipAnchorRegistry.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
