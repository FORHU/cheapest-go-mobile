# The Stay Card is drawn by the map

**Status:** accepted · 2026-11-24 · completes the carousel removal the code already cites as ADR-0008

V2's search page keeps a rail of cards along the foot of the map and opens a preview over the
selected marker. The client asked for the rail gone on mobile — on a phone it covered a quarter
of the map to show two and a half cards — leaving the preview as the only card on the screen.
**That preview, the Stay Card, is painted to an image and handed to Mapbox as an annotation,
exactly as the Stay Pins are, rather than laid out as a Flutter widget over the map.**

The reason is the one already written at the top of `stay_pin_painter.dart`, which says why the
pins stopped being widgets. Anything drawn over the map learns where the ground went from a
camera event crossing a platform channel, and acts on it a frame later — so through a pan it
trails the thing it names. Three attempts narrowed that gap and none closed it: asking the map
to project the coordinate (a round trip per frame), computing the projection in Dart from the
camera the event carries (no round trip, still a frame late), and holding the card still for
the gesture and placing it on idle (no drift, but a card that visibly jumps). The gap is not an
implementation fault; it is what being outside the map's frame costs. A thing that must hold
its place on the ground has to be drawn by whatever draws the ground.

## Consequences

- **The card is a picture, so nothing on it is a widget.** Its close button, gallery arrows and
  dots are regions of that picture; taps are hit-tested against the card's own rect, projected
  from the camera. The dots snap rather than stretching, because there is no widget tree to
  animate — the picture is repainted.
- **A new photo means a new picture.** The gallery still advances every 3.4 seconds, and each
  advance repaints the card and replaces the annotation's image.
- **The card cannot be clamped into view.** Clamping is moving the card relative to the map,
  which is the drift this removes. Instead the camera eases on select, just far enough that the
  whole card clears the search bar, and holds still from then on.
- **The results Tip lost its anchor.** It pointed at the first rail card, and since the rail
  went it has had nothing to point at — a painted card cannot hold it either. It now points at
  the stay-count plate, which is on the screen whether or not a card is open. See ADR-0006.
- **Rotate and pitch gestures are off on this map.** Hit-testing and placement project the
  camera flat; both are exact only north-up and level, and neither gesture earns its keep on a
  search map.
