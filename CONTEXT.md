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

- **Already Here** — what an installed app may drop because opening it already said it. V2
  carries its wordmark on every page, and a second route to the account beside the one in the
  bar, because a website must identify itself on any page somebody might land on cold and
  cannot assume a persistent bar. Neither holds for an app nobody reaches by accident. A
  narrow exception to **Design Parity**, claimed only where the removed thing is repeating
  something the app's own frame states — never for a section, a control or a fact that V2's
  screen is actually there to show.
  _Avoid_: stretching it to anything merely redundant-looking; two ways to the same screen is
  the test, not two things that resemble each other.

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

## Access

- **Gate** — the rule that nothing but the **Open Screens** is reachable without an account.
  A property of the app, not of any one screen: there is no signed-out browsing on mobile, so
  every screen below the gate may assume a user. This is the one place mobile deliberately
  does not follow its **Design Source** — the web has no gate and is not expected to grow one.
  _Avoid_: calling it a paywall or a login prompt. Nothing is being sold, and a prompt is
  something you can dismiss.

- **Open Screens** — what the **Gate** lets through: sign-in, register, forgot password, reset
  password, the auth-error screen, and the four legal documents. The legal ones are open
  because the sign-in screen's own copy links to them — a link that bounces to sign-in is a
  dead end — and because a policy must be readable before somebody creates an account.
  _Avoid_: adding to this list for convenience; each addition is a hole in the Gate and needs
  the same reason the legal screens have.

- **Onboarding** — the setup a newly created account completes before reaching the app:
  **Preferences** first and mandatory, **Traveller Details** after and skippable. It is
  attached to the account, not the install, so it survives a reinstall and does not repeat on
  a second device. Mobile's own flow — the web has no equivalent.
  _Avoid_: "welcome screens" or "intro" — those are something you read, and this is something
  you finish. Nothing here is explanatory; every step stores an answer.

- **Preferences** — display currency, language and email notifications: the three V2 already
  keeps against the account, which is why their labels are mirrored rather than written. Held
  server-side and shared with the web, so changing one in the app changes it in the browser.
  _Avoid_: treating these as device settings. Theme and map tier are device settings; these
  are not.

- **Traveller Details** — birth date, phone and nationality, held against the account so a
  later booking does not ask again. Distinct from the per-passenger details a flight order
  carries: those describe who is flying on one trip, these describe the account holder.
  _Avoid_: assuming they are present. They are skippable, and most accounts predate them.

- **Grandfathered** — an account created before **Onboarding** existed, recognised by having
  neither marker in its preferences. It goes straight into the app. Distinct from an account
  that *started* onboarding and stopped: that one carries a start marker without a completion
  marker, and resumes where it left off.
  _Avoid_: reading a missing marker as "has not onboarded" — that would wall every existing
  user out of the app they already use.

## Guidance

- **Tip** — a one-time, non-blocking pointer at a single control, shown the first time somebody
  reaches the screen that carries it. It names what that control is for and gets out of the
  way: nothing is dimmed, taps pass through to the screen underneath, and acting on the screen
  dismisses it. Each screen owns its own; they are not steps of anything.
  _Avoid_: "coach mark". Everywhere else that word means a dimmed screen with a cut-out, which
  is the thing these deliberately are not — and a name that invites the scrim back is how the
  scrim comes back.
  _Avoid_: calling a run of them a **Journey**. That word is already V2's, for the landing
  page's opening sequence, and means something else entirely.

- **Tip Anchor** — the widget a **Tip** points at, named so the tip can find it without the
  screen knowing a tip exists. A feature may not import another feature, and the things worth
  pointing at are spread across several, so anchors register themselves and are looked up.
  _Avoid_: treating a missing anchor as an error. A screen nobody is looking at has no anchor,
  and that is the normal case.

- **Tipped Out** — somebody who has stopped the **Tips**. Skip does that, from any Tip, and no
  further Tip appears on any screen. Skip means all of them, not the card in front of you: a
  way out that only closes what you are looking at is not a way out.
  _Avoid_: reading "Got it" as stopping them. That is somebody taking the help, not refusing
  it. _Avoid_: expecting Skip to navigate. It stops the help; it does not move anybody, least
  of all out of a booking they are in the middle of.
  _Avoid_: numbering them, or calling them a tour, a walkthrough or a sequence. They were
  numbered once — "Tip 2 of 7" — and it made the help read as a flow the traveller was inside,
  so Skip looked like a door out of it and leaving them where they stood read as broken.

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
  What is saved is **the hotel or the flight, never an Offer**. An Offer is a price for given
  dates and lapses; a shortlist is for coming back to weeks later, so a Saved Trip that
  expired with its rate would be the wrong thing entirely. This is why a saved hotel is named
  by its `hotelId` rather than by whatever rate was on screen when the heart was tapped.
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
  prices. Impersonal — the same for everybody.
  _Avoid_: filing a traveller's own records here. A **Booking** belongs to a person and needs
  an account to see; the catalogue knows nothing about either.
  Being impersonal is not the same as being reachable. On the web the catalogue is readable
  signed out; on mobile it sits behind the **Gate**. The content did not change — who may
  look at it did. See ADR-0005.

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
