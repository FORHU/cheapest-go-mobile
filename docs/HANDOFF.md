# Handoff — Bare React Native migration + run on physical phone (WSL2)

**Date:** 2026-06-30
**Repo (Windows):** `C:\Users\USER\Documents\GitHub\cheapestGo-mobile-app`
**Branch:** `chore/bare-react-native` (commit `ced826e`)
**WSL build copy:** `~/projects/cheapestGo-mobile-app` (Ubuntu 26.04, user `userbilly1`, host `DESKTOP-44MT48E`)

## Goal
Migrate the mobile app from the Expo *prebuild* workflow to the **bare React Native
workflow** (commit native folders, build with the RN CLI; **keep** Expo packages +
expo-router), then **build and run it on a physical Android phone** from a Windows machine.

## Background / existing artifacts — read these first (don't re-derive)
- **Full migration guide:** [`docs/MIGRATE_TO_BARE_REACT_NATIVE.md`](./MIGRATE_TO_BARE_REACT_NATIVE.md)
- **WSL toolchain setup script:** [`scratch/setup-wsl.sh`](../scratch/setup-wsl.sh) (note: `scratch/` is gitignored)
- **Commit `ced826e`:** committed the native `android/` project; stripped the secret Mapbox token from `android/gradle.properties`.

## Status — what works
- ✅ Native `android/` committed; bare workflow in place.
- ✅ Confirmed **native Windows cannot build** this project (260-char `MAX_PATH` limit in `ninja`; New Arch codegen + gesture-handler). Decision: **build in WSL2**.
- ✅ WSL2/Ubuntu toolchain installed (JDK 17, Node 20, Android SDK, NDK 27.1.12297006, CMake 3.22.1).
- ✅ Project cloned into the **Linux filesystem** (not `/mnt/c`).
- ✅ **Full native build succeeds in WSL** and the APK **installs and launches** on the phone (**Samsung SM-A226B, Android 13**).

## Status — CURRENT BLOCKER (this is where to resume)
The app launches into the **expo-dev-client launcher** but **cannot connect to Metro**
(the JS dev server) — so the real JS bundle never loads.

Networking facts established via diagnostics:
- WSL `.wslconfig` set to `memory=8GB`, `swap=10GB`, `networkingMode=mirrored`.
- Mirrored mode **is active**: WSL `hostname -I` = `192.168.1.36` (= the Windows Ethernet LAN IP). Phone is `192.168.1.9` on the same subnet.
- Metro **is running** and listening on `*:8081` in WSL.
- `127.0.0.1:8081` reachable from Windows = **True**; `192.168.1.36:8081` = **False** → **Windows/Hyper-V firewall is blocking LAN inbound to 8081**.
- A standard `New-NetFirewallRule` for inbound TCP 8081 did **not** fix it (Hyper-V firewall in mirrored mode).

**Chosen path forward: `adb reverse` (bypasses the firewall/LAN entirely).**
Immediate next steps:
1. `adb devices` — the wireless port rotated (`192.168.1.9:40129` is stale, "device not found"). Get the **current** id. Prefer the stable mDNS id `adb-R9WRB06S36E-...._adb-tls-connect._tcp` if present.
2. In WSL: `export REACT_NATIVE_PACKAGER_HOSTNAME=localhost`
3. `adb -s <current-id> reverse tcp:8081 tcp:8081`  (verify with `... reverse --list`)
4. `npx expo start`
5. On the phone launcher, enter **`localhost:8081`** in the Connect box → Connect.

Fallback if adb reverse is flaky: fix the Hyper-V firewall in an **admin** PowerShell:
`Set-NetFirewallHyperVVMSetting -Name '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -DefaultInboundAction Allow`, then connect the phone to `192.168.1.36:8081`.

## Important environment notes
- **Two terminals in play:** Ubuntu (Linux cmds: `adb`, `npx`, `sed`) vs Windows PowerShell (`wsl --shutdown`, firewall, `.wslconfig`). User has mixed these up — label which is which.
- The app is a **dev build**: native shell is in the APK; **JS is served by Metro** (`npx expo start`). `expo start` staying is correct — bare ≠ Expo-free.
- Daily run loop once connected: `cd ~/projects/cheapestGo-mobile-app && npx expo start` then connect the phone.

## Changes made in the WSL clone NOT yet committed / synced to the Windows repo
- `android/gradle.properties`: `reactNativeArchitectures=arm64-v8a` (single-ABI for faster/lighter dev builds).
- Added dev dep `@react-native-community/cli@^20.2.0` (RN 0.85 decoupled the CLI).
- `chmod +x android/gradlew` (exec bit lost in Windows→Linux clone).
These should be committed on the branch once the app runs.

## Outstanding TODO (post-blocker)
- [ ] 🔐 **Rotate the Mapbox secret token** — it is still in git history via the tracked `.env` (token value redacted here). Regenerate at <https://account.mapbox.com/access-tokens> and update `.env` + CI secrets.
- [ ] **Untrack `.env`:** `git rm --cached .env` (it's in `.gitignore` but still tracked).
- [ ] **iOS:** no `ios/` folder; must be generated/built on a **Mac** (`npx expo prebuild -p ios`).
- [ ] Decide whether to push `chore/bare-react-native` for the senior to review.
- [ ] Optionally move `scratch/setup-wsl.sh` to a tracked dir (e.g. `scripts/`) so the doc link resolves for teammates.

## Suggested skills for the next session
- **`diagnose`** — for the Metro/adb-reverse connection blocker if it persists (reproduce → instrument → fix).
- **`verify`** — once connected, to confirm the app actually runs on the device and the change works.
- **`code-review`** — before pushing the branch, review the WSL-side changes (arch limit, cli dep, gradlew +x).
