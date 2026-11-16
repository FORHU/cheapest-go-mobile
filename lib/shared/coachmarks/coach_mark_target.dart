import 'package:flutter/widgets.dart';

/// Where a coach mark points. See #63.
///
/// A tour has to know where things are on screen, and the things are spread across features —
/// the search tabs belong to Home, the bar belongs to the shell. A feature cannot import
/// another feature, and neither should have to know a tour exists, so each one wraps the
/// widget it is willing to have pointed at and the tour looks it up by name.
///
/// Registration is by id rather than by passing keys around because the tour runs above
/// everything in the app layer, and threading a key from the shell into Home's private
/// widgets would couple the two in exactly the way the architecture forbids.
class CoachMarkIds {
  /// Stays · Flights · Golf, on Home.
  static const String searchFaces = 'home.searchFaces';

  /// The first step of the search — where someone is going.
  static const String searchStart = 'home.searchStart';

  /// The bottom bar: Home · Trips · Settings.
  static const String bottomBar = 'shell.bottomBar';
}

/// The live registry of anchors, keyed by id.
///
/// Entries come and go with the widgets themselves: a target on a screen nobody is looking at
/// has no position, and pointing at it would draw a box over empty space. The tour skips a
/// step whose anchor is missing rather than guessing where it used to be.
class CoachMarkRegistry {
  CoachMarkRegistry._();

  static final Map<String, GlobalKey> _anchors = {};

  static void register(String id, GlobalKey key) => _anchors[id] = key;

  static void unregister(String id, GlobalKey key) {
    if (_anchors[id] == key) _anchors.remove(id);
  }

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
  static void clear() => _anchors.clear();
}

/// Wraps a widget so a coach mark can point at it. Draws nothing itself.
class CoachMarkTarget extends StatefulWidget {
  const CoachMarkTarget({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<CoachMarkTarget> createState() => _CoachMarkTargetState();
}

class _CoachMarkTargetState extends State<CoachMarkTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    CoachMarkRegistry.register(widget.id, _key);
  }

  @override
  void dispose() {
    CoachMarkRegistry.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
