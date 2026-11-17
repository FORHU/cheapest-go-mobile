# Tips point without blocking

**Status:** accepted · 2026-11-17 · reverses part of #63

#63 put three coach marks on Home: the screen dimmed, a cut-out lit the control being
described, and a card explained it. They ran once per device, on launch, and nothing but Home
carried one. A traveller who got past Home was on their own from the search box to the card
form — which is the part nobody has done before.

**Every screen on the way to a booking now carries its own Tip, and a Tip never blocks.** No
scrim, no cut-out, taps pass through to the screen underneath, and acting on the screen
dismisses it. Six of them: hotel results, the property, hotel checkout, flight search, flight
checkout, and Trips.

**One Tip per screen, including Home.** #63 stacked three on Home — the faces, the search box
and the bar. Home keeps one, the bar, because the other two are the screen's own subject and
explain themselves, while the bar is the thing a newcomer has no reason to read. Stacking
instructional overlays is what NN/g warns makes an app look daunting, and "a Tip per screen" is
a rule somebody can apply without asking; "three here, one there" is not.

Each one belongs to its screen and is shown the first time somebody reaches it, whatever path
they took. They are not steps of a tour. A tour has to assume where somebody goes next, and the
moment they tap Flights where it expected Stays it is pointing at a control that is not there.

**They wait for the screen to settle, and for a pause.** A Tip appears once the screen has
content and nobody has acted for about two seconds. Somebody who knows what they are doing taps
straight through and never sees one; somebody hesitating gets the help. Material's own guidance
is that a prompt on app open reaches people who opened the app to do something specific, and
that interruptive moments should be avoided — which is exactly what #63 did and what this stops.

**Skip ends the walkthrough, from any Tip.** This started the other way round — one Skip
silenced one Tip, and three refusals ended them — on the reasoning that waving away a hint
about a list of hotels says nothing about wanting help at payment. Watching it on a handset
settled it: somebody mid-booking wants one way out that means what it says, and a Skip that
closes only the card in front of them is not one. Three separate refusals to achieve silence is
an app not listening.

**Nothing is numbered.** A counter was tried — "Tip 3 of 7" — to make the help read as one
thing rather than unrelated popups. On a device it did the opposite: it made the help read as a
*flow the traveller was inside*, so Skip looked like the door out of that flow, and a Skip that
left them standing on a results screen read as broken. The counter went, and with it the
expectation it created. Each Tip is now one hint about what is in front of somebody.

This also matches the only comparable evidence found. Airbnb asks for an account at *Reserve*
rather than at install, and its tutorials are single tooltips announcing one feature, not a
numbered run through a funnel. No consumer-app material was found for Booking.com or Expedia,
so "OTAs do not do this" is unproven for them rather than established — worth saying plainly,
because this decision rests on one teardown and one UX write-up.

## Considered Options

**Continuing the existing tour across screens** was rejected. It is the most literal reading of
"show how it's done until he can book", and it is the fragile one: the steps have to be ordered,
and the order is a guess about a traveller who can go to Stays, Flights or Golf from the same
screen. A tour that stalls because somebody chose the other product teaches nothing and cannot
be debugged from a screenshot.

**Keeping the spotlight** was rejected on evidence rather than taste. Tooltips are meant to
explain without blocking interaction, the quiet forms are a badge or a tooltip that never blocks
the primary action, and stacking instructional overlays strains short-term memory and makes an
app look daunting. A checkout is the clearest case: covering the price while asking somebody to
read about paying, with no way to tap past it, is the opposite of help. None of the sources
measured conversion, so this rests on usability guidance, not on numbers.

**Leaving Home's three as they were** was rejected, and it was the tempting option — it is free.
It would have left two kinds of tip in one app, looking and behaving differently for no reason a
traveller could see, with the older kind keeping the two behaviours the guidance names as
unhelpful. The cost of the rewrite is paid once; the confusion would be paid by every reader
afterwards.

**Covering golf** was rejected because golf cannot be booked. `golf_view.dart` writes a tee time
to `bookingsStore`, the on-device store, and Trips shows only what api-v2 confirms (ADR-0003).
Teaching somebody to complete a booking that never reaches the server is teaching a fiction, and
ADR-0003 exists to stop this app presenting that as real.

## Consequences

**The rename is load-bearing.** `coach_*` becomes `tip_*` across ten keys in four locale files,
and `_locallyOwnedPrefixes` in `tools/sync_design.dart` has to change with it. That list is what
stops the generator deleting strings V2 has no original for. A rename that misses it leaves four
languages of tip copy alive until the next sync and gone after it, with nothing failing in
between.

**"Coach mark" is now the wrong word for what this app does**, and it is the word the rest of
the industry uses for the dimmed version. The code says `Tip`, the glossary says `Tip`, and the
_Avoid_ on that entry exists so the scrim does not come back by way of a familiar name.

**Six new strings have no V2 original**, because V2 has no equivalent screens. They are written
here and translated here, like onboarding's, and carry the same risk: nothing upstream will ever
correct them.

## Consequences, found on a device

**The hotel results screen opens on the map, not the list.** `_mapView` starts true, so the
first stay card the first Tip was anchored to does not exist when somebody arrives. The anchor
is on the rail as well, which is what a traveller actually sees there. A Tip anchored to one of
two interchangeable layouts is anchored to nothing half the time.

**A Tip cannot be scheduled on having a position.** An anchor registers during `initState`,
before layout, so asking where it is at that moment always answers nowhere. Scheduling keys off
the anchor existing; the rectangle is asked for when the Tip is about to be drawn.

**Waiting for an anchor cannot have a deadline.** Home's TipScope mounts above the router while
the traveller is still at the sign-in wall, and the bottom bar it points at does not exist until
they are through the gate and past onboarding — minutes, not seconds. Two attempts at this
failed on a handset: one look, then a twenty-second poll. Anchors now announce themselves and a
waiting Tip reacts, which has no window to get wrong.
