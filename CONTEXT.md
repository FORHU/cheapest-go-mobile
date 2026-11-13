# Context Glossary

A shared vocabulary for this codebase. Definitions only — no implementation details.

## Design

- **Design Source** — V2 (`cheapestgo-app-v2`) at its mobile breakpoint. Mobile does not own
  its appearance; it follows V2's. This is the deliberate opposite of **Design Independence**
  in V2's own glossary, which frees V2 from V1 — that freedom is V2's alone and does not pass
  down to mobile by analogy.
  _Avoid_: V1 (`cheapest-go-app`) as a reference; it is neither the source nor a tiebreaker.

- **Design Parity** — a mobile screen carries the same sections in the same order, the same
  components and literally the same strings — V2's own `en`/`ja`/`ko`/`zh` translations, not a
  second set that happens to agree — as its Design Source screen. Judged by whether a person
  recognises it as the same screen, never by pixel comparison: fonts rasterise differently and
  scroll physics are the platform's, not ours.
  Governs behaviour as well as appearance: an affordance V2 does not offer — pull-to-refresh,
  haptics, long-press, native share — is not added here either.
  _Avoid_: "pixel-perfect", "clone" — both promise an identity no native app can hold.

- **Platform Obligation** — the narrow set of behaviours Android delivers whether or not the
  design asks for them; the back gesture is the whole of it today. Not an exception to
  **Design Parity** but a question it has to answer: back does what the browser's back does,
  which is return to the previous screen.
  _Avoid_: treating it as licence for other native affordances — it covers what the OS sends
  us unbidden, nothing we choose to add.

- **Design Pin** — the exact V2 commit this repo's mirrored material was taken from: tokens and
  the shared copy alike. It is what "the APK matches V2" means at any moment, and it moves only
  when a pull request deliberately bumps it.
  _Avoid_: "latest V2" — there is no such thing here; mirroring is against a commit, never a branch.

- **Token Authority** — where a **Design Source** screen contradicts V2's own tokens, the token
  is what mobile implements and the screen is what gets reported. A one-off literal on a V2
  screen is a defect in V2, not a specification for mobile.
  _Avoid_: treating a rendered colour as a token because it shipped.

- **Journey** — the landing page's opening sequence: a descent through everything CheapestGo
  sells, ending where the visitor chooses. Composed of **Stages**. The term is V2's and keeps
  V2's meaning here.

- **Stage** — one step of the **Journey**, putting a single real product surface in front of
  the visitor. A place in the descent, not a section of a document.

- **Plain Journey** — the Journey rendered without choreography: every Stage's heading stated
  outright, nothing driven by scroll position. V2 shows this to visitors who ask for reduced
  motion; on mobile it is the default rendering, not a fallback.
  _Avoid_: calling it "the reduced-motion version" here — on mobile it is simply the Journey.

## Hotel domain

- **Saved Trip** — a hotel or flight a user has marked with the heart icon to revisit later.
  Held against the account on the server, so it survives a reinstall and appears on the web as
  well. **Favorite** is the act of marking one; the stored item is a Saved Trip.
  _Avoid_: "Saved hotel" — a Saved Trip can be a flight. _Avoid_: describing these as
  device-local; they were until 2026-11-10 and are not now.
  Note that V2's landing carries a separate, device-local save button. That is V2's own
  inconsistency, not a second concept to reproduce here.
  Mobile has the act but not yet the Saved Trip: what the heart marks here is held on the
  device and goes with the app, so it is not visible on the web and does not survive a
  reinstall. The definition above is what mobile is owed, not what it currently does.
  A Saved Trip belongs with the account, never among **Bookings** — the two answer different
  questions, and a screen that lists reservations is not where a shortlist lives.

- **Offer / Rate** — a specific bookable price for a room on given dates, identified by an
  `offerId`. A room can carry several rates (e.g. refundable vs non-refundable, with/without
  breakfast). Selecting a room means selecting its first rate.

- **Prebook** — the step that locks a selected rate and returns the *authoritative* price,
  currency, cancellation policy, and a `prebookId`. The prebook price — not any
  display-converted figure — is the source of truth for what the guest is charged.

- **Booking** — a confirmed reservation, created after payment, saved server-side and tied
  to the user's account. Distinct from a Prebook (which is only a held quote).
  It exists because the server says so. A reservation this app knows about and the server does
  not is not a Booking, whatever the screen that produced it claimed.

- **Catalogue** — what CheapestGo has for sale: airports, flights, stays, courses and their
  prices. Impersonal — the same for everybody, and readable signed out.
  _Avoid_: filing a traveller's own records here. A **Booking** belongs to a person and needs
  an account to see; the catalogue knows nothing about either.

- **Lead guest** — the named guest a room is reserved under. Bedbank suppliers
  (TravelgateX) typically require only the lead guest per room, not every occupant.

- **Travel document** — proof a traveller can present to somebody who is not us. Three kinds,
  evidencing three different things that do not become true at the same moment: a **Payment
  Receipt** says money was taken, an **E-ticket** says an airline issued a ticket, and a
  **Hotel Voucher** says a property is holding a room. Each is earned separately, so a booking
  may have one and not another.
  _Avoid_: a single "receipt" standing for all three — that is what lets someone reach a desk
  holding proof of payment and nothing the airline can act on.

- **Ticketed** — an airline has issued a ticket. The gate for an **E-ticket**, and not the same
  thing as holding a **PNR**: a booking can carry a record locator for hours before a ticket
  exists, and sometimes none ever is.
  _Avoid_: treating a PNR, or a successful payment, as evidence of a ticket.

- **Supplier reference** — the reference the property's own system holds, as distinct from the
  `CG-` reference, which is ours and which a front desk has never seen. The supplier's is what
  finds the reservation at check-in.

- **Aggregate score vs Review** — the numeric `reviewRating` / `reviewsCount` on a hotel is
  an **aggregate score**. Individual **reviews** are the per-guest text entries. Mobile has
  the former (real, already in the hotel-details payload) but not the latter (currently
  fabricated on-device, pending wire-up to the real source).

- **Verified review** — a real per-guest review sourced from ETG (the supplier's nightly review
  dump), written by an actual booker. This is the canonical meaning of "verified" in the reviews
  UI; do not apply the word to fabricated or placeholder entries. The real reviews live
  server-side (web repo) and reach mobile through a dedicated reviews endpoint, keyed by the same
  hotel code (`hotelId`) used for hotel details.
