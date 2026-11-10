# Tokens and copy are generated from a pinned V2 commit

**Status:** accepted · 2026-11-10

Mobile's colours and strings are not written here. A generator reads them out of
`cheapestgo-app-v2` at one recorded commit — the **Design Pin** — and emits Dart, which is
committed to this repository. CI re-runs the generator against the pin and fails if the output
differs, so the checked-in files cannot quietly stop matching their source.

Colour arrives in two layers, because V2 paints in two layers. Tailwind's stock ramp is the
primitive set, so a Flutter widget names `slate-400` exactly as the web does — that one stop
appears 536 times in V2's components, and 197 distinct stock utilities are in use. V2's 77
`@theme` custom properties sit on top as the semantic roles. Both are generated; the oklch
values are converted to sRGB by the generator rather than by a person.

Copy is converted from V2's `en`/`ja`/`ko`/`zh` JSON into ARB and consumed through `gen-l10n`,
so a renamed key is a build error rather than a blank label discovered by a user. 200 messages
interpolate and 28 use ICU plural or select, which ARB handles.

## Considered Options

`palette.ts` was the obvious source and is what `app_colors.dart` claimed for months. It holds
14 brand constants for the places CSS cannot reach — an SVG stroke, a Mapbox line — and cannot
describe a screen built from `slate-400`. Mirroring it would have meant inventing most colours
on this side, which is the opposite of the point.

Generating at build time from a live checkout was rejected because it makes this repository
unbuildable without the other one, and lets a web merge change a mobile build with no diff
anyone reviewed. Hand-mirroring was rejected because converting 77 oklch values by hand invites
errors that look like design decisions.

## Consequences

The pin, not a branch, is what "the APK matches V2" means. It also fixes an ordering that reads
like a deadlock: a mobile pull request cannot verify a change that has not landed on the web
yet, so the web pull request merges first — its gate wants a *linked* mobile pull request, not a
merged one — and the mobile one then bumps the pin to that merge commit. See ADR-0008 in the
web repository.

Plus Jakarta Sans and JetBrains Mono are bundled as assets rather than fetched at runtime: they
carry 106 of 113 font usages, and an app that tracks a flight offline cannot render in a
fallback face because Google was unreachable. Fredoka and Open Sans (3 and 4 uses) are not
carried; they are raised against V2 as stray one-offs instead.

Seven messages use next-intl rich-text tags, which have no ARB equivalent. They are deliberately
unresolved — flattening them to plain text would silently drop a link or an emphasis, so they
need a decision of their own before the screens carrying them are ported.
