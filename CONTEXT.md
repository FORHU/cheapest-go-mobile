# Context Glossary

A shared vocabulary for this codebase. Definitions only — no implementation details.

## Hotel domain

- **Favorite** (synonym: **Saved hotel**) — a hotel a user has marked with the heart
  icon to revisit later. Device-local, not tied to the account. The "Saved" tab and a
  "favorite" are the same concept; prefer **Favorite** for the action, **Saved hotel**
  for the stored item.

- **Offer / Rate** — a specific bookable price for a room on given dates, identified by an
  `offerId`. A room can carry several rates (e.g. refundable vs non-refundable, with/without
  breakfast). Selecting a room means selecting its first rate.

- **Prebook** — the step that locks a selected rate and returns the *authoritative* price,
  currency, cancellation policy, and a `prebookId`. The prebook price — not any
  display-converted figure — is the source of truth for what the guest is charged.

- **Booking** — a confirmed reservation, created after payment, saved server-side and tied
  to the user's account. Distinct from a Prebook (which is only a held quote).

- **Lead guest** — the named guest a room is reserved under. Bedbank suppliers
  (TravelgateX) typically require only the lead guest per room, not every occupant.

- **Aggregate score vs Review** — the numeric `reviewRating` / `reviewsCount` on a hotel is
  an **aggregate score**. Individual **reviews** are the per-guest text entries. The app has
  the former (real, from search payload) but not yet the latter (currently fabricated).
