# A Saved Trip names the thing, not the price

**Status:** accepted · 2026-11-15

`saved_trips` has never held a row. The table is sound — `type`, `title`, `subtitle`, `price`,
`currency`, `image_url`, `deep_link`, `snapshot` — but `POST /bookings/saved-trips` cannot
write to it. The repository writes `hotel_id`, `hotel_name` and `details`, none of which are
columns, and only compiles because of an `as any`. The controller's schema demands a
`hotelId` that the table has no place for, which also rejects the payload V2's own flight
button sends.

Both clients hide this. V2's flight save catches the failure — *"non-fatal, save locally
anyway"* — and writes to `localStorage`; its hotel bookmark does not even try, and says so:
*"no server story attached to it yet"*. Mobile's hearts write to the device. Four stores of
"saved", none of them the one the glossary describes.

#43 fixes api-v2 to match its own table, and this records the contract both clients then
write against.

## A Saved Trip is identified by what it is, from `snapshot`

A saved hotel is `snapshot.hotelId`. A saved flight is `snapshot.provider` with
`snapshot.offerId`, which is what V2 already matches on.

**Not the Offer.** CONTEXT.md defines an **Offer / Rate** as a price for given dates, and it
lapses. A shortlist is for coming back to weeks later, so keying a saved hotel to the rate
that happened to be on screen would expire the heart with the price, and re-saving would make
a second row for the same hotel. The thing being saved is the hotel.

There is no `hotel_id` column and this decision does not add one. A migration would leave
flights still matched from JSON, so there would be two mechanisms rather than one; and the
match is made once per screen against a list the client already holds, not queried per row.

## `deep_link` is always V2's web path

The column is NOT NULL and V2's account view renders it as an `href`. Mobile writes
`/property/<id>` — V2's route, not its own — so that a stay saved on a phone opens from the
account page on the web. Mobile ignores the field when reading and routes from
`snapshot.hotelId` to its own `/hotel/:id`.

**An absolute URL** was rejected: it would bake a host into a database row, which is wrong
for the AirangGo brand and in every non-production environment.

**Mobile's own route** was rejected because it breaks the link on the web, which is the
interoperation this slice exists to deliver.

## Consequences

The list of saved trips is rendered from the server's rows, which carry `title`, `price` and
`image_url`. It is not assembled by looking ids up in the catalogue: `ApiTravelCatalog.hotel`
reads a cache that searches fill, so after a fresh launch it resolves nothing and the screen
silently shows an empty list. That was the behaviour #42 shipped.

A row written by either client is readable by the other, so the two products share one
shortlist. Until V2 stops falling back to `localStorage`, it will also keep a private copy
that mobile cannot see; that is V2's to remove and is not fixed here.

Device-local favourites are not migrated. They are bare ids, and a row needs a title and a
`deep_link` that an id alone cannot supply without a lookup per saved hotel — one that
silently drops anything the supplier no longer returns, and that never runs at all for
somebody who does not sign in. They are announced once and cleared instead, so the loss is
stated rather than silent.
