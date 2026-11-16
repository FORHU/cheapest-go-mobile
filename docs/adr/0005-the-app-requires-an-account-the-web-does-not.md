# The app requires an account, the web does not

**Status:** accepted · 2026-11-16

CONTEXT.md opens by saying mobile does not own its appearance: it follows V2, and **Design
Parity** governs behaviour as well as looks. **Catalogue** said the things CheapestGo sells are
"readable signed out". Both were true of this app until now.

#62 asks for a sign-in wall on first launch and an onboarding flow after registration. V2 has
neither. `src/middleware.ts` in `cheapestgo-app-v2` gates exactly one path — `/admin`, and only
on the staff host — so every storefront route, search included, answers a signed-out visitor.
Nothing in V2 matches `*onboard*` at all. Mobile matched that: no route guard, and a checkout
that showed a sign-in banner rather than turning anyone away at the door.

**Mobile now requires an account before anything but the Open Screens, and the web is not
expected to follow.** This is a deliberate divergence from the **Design Source**, the first one
this repo has taken, and it is scoped to reachability: every screen behind the gate still
mirrors V2 exactly as before. What changed is who may open the app, not what the app looks
like.

The cost is real and worth stating plainly. Most of this market — Booking.com, Expedia, Agoda,
Airbnb, Trip.com — lets a visitor search before it asks for anything, because a traveller
comparing prices across four apps will close the one that demands an email first. We are
accepting that loss knowingly, in exchange for every session being attributable to an account
and for a traveller profile that exists before a booking needs it rather than during one.

**Onboarding is attached to the account, never the install.** It records its state in
`profiles.preferences`, the JSON blob api-v2 already serves through `GET`/`PATCH
/api/v2/users/preferences`, so a reinstall does not repeat it and a second device does not
either. Two markers, not one: a start written when the account is created, a completion written
when the last mandatory step is answered. A start without a completion is someone who closed
the app halfway and must resume; neither marker is an account that predates this decision, and
it goes straight in.

**The start marker is written by api-v2 at account creation, not by the app.** Mobile cannot
tell a first-time Google user from a returning one — `POST /api/v2/auth/google/native` returns
`{ user }` and says nothing about having just created the row. Had the app written the marker
after registering, every account made through Google would have arrived with neither marker,
been read as grandfathered, and skipped onboarding for good. Writing it where the account is
born closes that by construction rather than by the client remembering to.

## Considered Options

**Keeping parity and declining the ticket** was rejected. The glossary is a record of decisions
taken, not a constraint on taking new ones, and **Already Here** shows the shape was always
allowed: it exists because an installed app may assume things a website cannot. That entry
licenses removing what the app frame already states; this decision is the same reasoning
pointed the other way, and it needs saying out loud rather than being smuggled in under an
exception written for something else.

**A soft gate** — browse freely, require an account to book, save or open Trips — was rejected
on instruction, having been put and considered. It is what the rest of the market does and what
mobile nearly did already, and it would have satisfied every acceptance criterion in #62 except
the first. The first is the one that was wanted.

**Deriving completion from whether the fields are filled**, with no marker at all, was
rejected. It reads well until a field is optional, and three of the six are: an account that
skipped its traveller details would look unfinished forever and be walled on every launch.
Adding a seventh field later would also silently un-onboard everybody who had finished.

**A new `users.onboarded_at` column** was rejected on cost, not on design — it is the cleaner
model. This project has no working migration pipeline; changes sit in `db/migrations`
unapplied, so the column would need hand-running against each environment before the app could
ship. `profiles.preferences` is already there, already served, and already carries account
state of exactly this kind.

**Making all six fields mandatory** was rejected. Currency, language and notifications are taps
with working defaults and cost a traveller nothing. A phone number demanded between install and
the first hotel price is where an install is uninstalled, so birth date, phone and nationality
are asked for and may be skipped.

## Consequences

A database trigger creates the profile row, and nothing in either repository says so.
`on_user_created` calls `handle_new_user`, which inserts `profiles (id, email)` as the user row
lands. It is not in any migration that has ever run and not in the Prisma schema, so the first
attempt here — nesting the profile creation under the user creation, to make the marker
unmissable — failed the primary key on every registration. The marker is written by updating
that row inside the same transaction instead. Anything else that creates an account will hit
the same wall.

`profiles.preferences` is replaced on write, not merged — `users.repository.ts` is explicit
that "a key it omits is a key it deleted". Mobile must read, modify and write it, or setting an
onboarding marker will wipe the display currency somebody chose in the browser.

The signed-out branches in `hotel_checkout_view.dart` become unreachable. They are left in
place: they are correct, they cost nothing, and they are what the screen needs again if the
gate is ever softened.

Onboarding's own copy — step titles, progress wording — has no V2 original, which ADR-0002 has
no provision for. Those strings are hand-written into the four ARB files and must be marked so
the generator does not treat them as drift and remove them.
