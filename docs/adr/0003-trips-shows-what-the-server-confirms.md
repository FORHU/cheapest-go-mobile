# Trips shows what the server confirms

**Status:** accepted · 2026-11-13

Until #42, the Trips screen rendered `shared/stores/bookings_store.dart`: a list in
SharedPreferences, seeded at launch with five invented past trips and appended to by whatever
checkout the traveller walked through. It never asked the server anything. A reinstall emptied
it, the web knew nothing of it, and five of its rows had never happened at all.

Only hotels book for real. #41 wired hotel checkout to `prebook → create-payment → confirm`,
so a hotel stay now exists in api-v2. Flight and golf checkout still wait 600ms, write a local
row and congratulate the traveller.

**Trips now reads `/bookings` and `/golf/bookings`, and shows nothing else.** A reservation
this app believes in and the server does not is not a **Booking** — see CONTEXT.md, which this
decision sharpened.

The immediate cost is that bookings made through the two mock checkouts stop appearing. That
is the point: they stopped being displayed because they never existed, and a screen that lists
them as reservations is making a promise no supplier is holding. What those flows must not do
is contradict the new screen, so they no longer end on `/trips` quoting a reference.

## Considered Options

**Merging server rows with local ones** was rejected. It keeps every screen populated and
makes Trips unreadable: a real reservation and a 600ms fiction appear as the same card, and
nothing on either tells a traveller which will be honoured at a desk. The bug this invites —
someone flying on a booking that does not exist — is worse than an empty tab.

**Wiring flight and golf checkout for real first** was rejected only on sequencing. It is the
right end state and two more tickets; blocking Trips on them leaves the fake store on screen
for longer.

**Deleting the mock checkouts** was rejected because they are the only way to walk those
journeys at all, and the journeys are what the next tickets are specified against.

## Bookings read through their own seam

Mock builds still need a populated Trips: CI has no server, and the demo APK is handed to
people without an account. The app already solves this for products with `TravelCatalog`,
chosen by `--dart-define=CATALOG=mock|api`.

Bookings get a **parallel** seam — `BookingsSource`, with a mock and an api implementation,
switched by that same `CATALOG` define — rather than new methods on `TravelCatalog`.

One switch still governs where all data comes from, which is the property worth having. What
is not worth having is `TravelCatalog` meaning two things. Every method on it today is a
product lookup: airports, flights, stays, courses, prices. It is impersonal and readable
signed out. A **Booking** belongs to one account and needs a session to see. Hanging
`myBookings()` off the catalogue would force `MockTravelCatalog` to invent a signed-in
traveller, and would leave the word "catalogue" meaning "everything we fetch".

The api implementation fetches hotels-and-flights and golf **independently**, because they are
separate endpoints and a golf outage should cost the golf rows and nothing else. V2 does the
same, for the same reason.

## Consequences

`bookingsStore` survives this ticket but loses its last reachable reader: Trips no longer uses
it, and #42 also removes the *Track* button that was the Map tab's last entry point (see
ADR-0001). It still backs the mock flight and golf checkouts and the Map's flight tracking, so
it is dormant rather than dead — the same managed dormancy ADR-0001 describes, and it ends
when those two checkouts become real.

`seedDemoHistory()` no longer reaches any screen. It stays until the mock checkouts do.

#41 left a deliberate stopgap — hotel confirm wrote a local row "so Trips still shows it until
#42". That row is now a duplicate of a server one with no way to tell them apart, so it goes.

Signed out, an api build gets a 401 and sends the traveller to sign in. A mock build has no
session to lack and shows its fixtures, which is what makes the demo APK and CI possible.
