# What changed

<!-- One or two sentences. What someone using the app would notice. -->

## Design parity

Delete this section if the change touches no screen.

This app takes its appearance from V2 at the mobile breakpoint — see `CONTEXT.md` for
**Design Source**, **Design Parity** and **Token Authority**, and `docs/adr/0002` for how the
tokens and copy get here.

- [ ] Same sections, in V2's order, with nothing added or dropped
- [ ] Every string comes from the generated ARB — no literal copy in a widget
- [ ] Every colour, size and radius comes from the generated tokens — no hex, no magic numbers
- [ ] Compared against V2 at phone width, not from memory
- [ ] Where V2's screen contradicts its own tokens, the token was implemented and the screen
      raised as a V2 issue (link it here)

If a V2 change prompted this, link the V2 pull request. The gate there wants a linked mobile
pull request, and the Design Pin is bumped on this side once the V2 one has merged.

## Checks

- [ ] `flutter analyze` clean
- [ ] `flutter test` passing
- [ ] `dart run tools/sync_design.dart --check` passing, or the pin was bumped deliberately
