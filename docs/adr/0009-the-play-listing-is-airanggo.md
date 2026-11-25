# The Play listing is AirangGo, and its id is com.forhu.airanggo

**Status:** accepted · 2026-11-25

This repository is called `cheapest-go-mobile`, its Android package was
`com.forhu.cheapestgo.cheapest_go_mobile`, and the app it builds is branded **AirangGo** — the
label, the icon, the strings and the brand lock all say so (ADR-0007). The first Play upload
had to resolve that disagreement, because **an `applicationId` cannot be changed once a listing
exists**: a different id is a different app, with its own installs, its own reviews and no
upgrade path for anyone holding the old one.

**One listing ships, it is AirangGo, and its id is `com.forhu.airanggo`.**

The id is named for the brand that ships rather than for the repository that builds it. The
repository name is historical — mobile began as CheapestGo's app and the brand arrived later —
and a Play URL reading `details?id=com.forhu.cheapestgo…` under an AirangGo listing would be
the kind of detail nobody can fix afterwards. Vendor first, product second, so that a second
FORHU app sits beside this one rather than somewhere unrelated.

## Considered and rejected

**Two listings now, one per brand.** The code is already shaped for it: brand is a build-time
constant, and `deploy-prod.yml` says in its own header that a CheapestGo release would be a
separate workflow. Rejected only as a matter of timing — one brand is going out first, and
nothing here prevents `com.forhu.cheapestgo` being added later as its own listing with its own
keystore. This is the decision most likely to be revisited, and revisiting it costs nothing.

**`com.airanggo.app`**, the reverse of the brand's own domain. Defensible if AirangGo is a
product in its own right, but it gives up the shared prefix, so a FORHU estate of apps would
read as unrelated strangers.

**Keeping `com.forhu.cheapestgo.cheapest_go_mobile`.** No work and no risk of a rename going
wrong, at the price of filing an AirangGo listing under a CheapestGo id with a redundant tail,
permanently.

## Consequences

- **Google sign-in must be re-registered.** A native Android OAuth client is bound to a package
  name *and* a signing certificate. Both changed. Until a client exists for `com.forhu.airanggo`
  with the right fingerprint, `idToken` comes back null and sign-in fails with nothing saying
  why. Two fingerprints are needed over time: the debug certificate, so sideloaded test builds
  keep working, and — after the first upload — the certificate **Play** signs with, which is not
  the upload key and cannot be known before then. See ADR-0006's sibling problem in
  `GOOGLE_NATIVE_CLIENT_IDS`: the same sign-in has already been broken once by configuration
  that was simply never set.
- **The upload key is new and must be kept.** Losing it is recoverable through Play support, as
  Play App Signing holds the signing key itself; losing it is still a week nobody wants.
- **`deploy-prod.yml` cannot publish the first release.** Play's API refuses an upload to a
  package it has never seen, so the first AAB goes in by hand through the Console. Every
  release after that can use the workflow.
