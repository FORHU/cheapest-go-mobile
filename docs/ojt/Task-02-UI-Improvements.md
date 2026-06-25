# OJT Task 02 — UI Improvements & Missing Functionality

**Assigned to:** OJT Trainee
**Supervisor:** Billy Dhen Clir Busilan
**Repo:** `cheapestGo-mobile-app` (React Native / Expo)
**Branch to start from:** `feat/hotel-changes`

---

## How to use this document

- Work through the tasks **top to bottom**. Each task is broken into small
  checkboxes — tick them off (`- [x]`) as you go.
- Every checkbox is one small action. If a checkbox takes more than ~30 min,
  stop and ask the supervisor.
- The **"Where"** line tells you the exact file and roughly which line.
- The **"Acceptance"** checklist at the end of each task is what the supervisor
  will verify. Don't mark the task done until all acceptance boxes are true.
- When you see `// TODO`, that means "leave a comment in the code so we can
  finish it later" — do **not** invent fake data to fill the gap.

---

## Step 0 — Setup (do this once before anything else)

- [ ] Pull the latest code: `git checkout feat/hotel-changes && git pull`
- [ ] Create your working branch: `git checkout -b feat/ojt-ui-polish`
- [ ] Install dependencies if needed: `npm install`
- [ ] Start the app and confirm it runs: `npx expo start`
- [ ] Learn how to toggle dark/light mode on your test device or simulator —
      you must test **both** for every task.
- [ ] Find the lint command in `package.json` (`scripts` section) and run it
      once so you know it passes before you start.

**Rules for every task below:**
- [ ] One small commit per task. Message format: `feat(profile): wire up edit button` etc.
- [ ] Reuse the existing `dark` / `light` theme objects in each file — never
      hardcode a hex color that bypasses the theme.
- [ ] Run lint before each commit.
- [ ] Take a **before** and **after** screenshot (light + dark) for each visual change.

---

## Task 1 — Wire up the dead buttons on the Profile screen

**Why:** Many buttons on the Profile screen render but have **no `onPress`**, so
tapping them does nothing. A button that looks tappable but does nothing is a
bug. Every control must either do something or clearly say it's not ready yet.

**Where:** [app/(tabs)/profile.tsx](../../app/(tabs)/profile.tsx)

### 1a — Add the imports you'll need
- [ ] At the top of the file, add `Linking` to the existing `react-native`
      import (it's used to open URLs and the app store).
- [ ] Confirm `useRouter` is already imported (it is — used for navigation).

### 1b — Add placeholder link constants
- [ ] Near the top of the file (after the imports, before the component), add a
      small constants block so links live in one place:
  ```tsx
  // TODO: replace these with the real production URLs
  const LINKS = {
    helpCenter: 'https://cheapestgo.com/help',
    terms: 'https://cheapestgo.com/terms',
    appStore: 'https://cheapestgo.com', // TODO: real App Store / Play Store link
  };
  ```

### 1c — "Change password" row → navigate to the existing screen
- [ ] Find the **"Change password"** `SettingRow` (~line 289).
- [ ] There is already a screen at
      [app/(auth)/update-password.tsx](../../app/(auth)/update-password.tsx).
- [ ] Add an `onPress` that navigates there:
      `onPress={() => router.push('/(auth)/update-password')}`
- [ ] Test: tapping the row opens the update-password screen.

### 1f — "Language" row → honest "coming soon" message
- [ ] The app has no multi-language support yet, so don't fake it.
- [ ] Find the **"Language"** row (~line 309) and add:
      `onPress={() => Alert.alert('Coming soon', 'Multiple languages are not available yet.')}`
- [ ] (`Alert` is already imported in this file.)
- [ ] Test: tapping shows the message instead of doing nothing.

### 1g — "Edit" button and avatar "Camera" button
- [ ] These two open the edit flow — that's **Task 2**. For now, just confirm
      they exist (~line 220 for "Edit", ~line 251 for the camera) so you know
      where they are.



## Task 2 — Replace hardcoded Profile stats & build a basic "Edit profile" flow

**Why:** The stats shown to the user are **fake hardcoded numbers**, and the
Edit / avatar buttons don't open anything. Showing invented data is misleading.

**Where:** [app/(tabs)/profile.tsx](../../app/(tabs)/profile.tsx)

### 2a — Understand the current fake data
- [ ] Look at the stats block (~lines 276–280). Note the hardcoded values:
      `BOOKINGS = "4"`, `SAVED = "12"`, `REVIEWS = "3"`.
- [ ] Look at the **"Price alerts"** row (~line 305): `"3 active alerts"` and the
      `"ON"` badge are also hardcoded.

### 2b — Make the SAVED count real
- [ ] There is a helper `getSavedHotels()` in
      [lib/favorites.ts](../../lib/favorites.ts). See how
      [app/(tabs)/saved.tsx](../../app/(tabs)/saved.tsx) calls it (lines 41–45).
- [ ] Add state: `const [savedCount, setSavedCount] = useState(0);`
- [ ] Load it with `useFocusEffect` (import from `expo-router`) so it refreshes
      when the user returns to the tab:
  ```tsx
  useFocusEffect(
    useCallback(() => {
      getSavedHotels().then(list => setSavedCount(list.length));
    }, [])
  );
  ```
- [ ] Use `savedCount` in the SAVED `StatItem` instead of the hardcoded `"12"`.

### 2c — Don't fake the other numbers
- [ ] For **BOOKINGS** and **REVIEWS**: if you can't find a real data source,
      show `0` (or `—`) and add a `// TODO: wire to real bookings/reviews count`.
- [ ] For **Price alerts**: replace `"3 active alerts"` with neutral text like
      `"Manage your price alerts"` and add a `// TODO`. Don't show a fake count
      or a fake "ON" badge.

### 2d — Build a simple "Edit profile" UI
- [ ] When **"Edit"** (~line 220) or the **avatar camera** (~line 251) is
      tapped, open an edit UI. Simplest approach: a modal with two text inputs
      (First name, Last name) and the email shown read-only.
- [ ] Pre-fill the inputs from `user.firstName` / `user.lastName`.
- [ ] Look in [context/AuthContext.tsx](../../context/AuthContext.tsx) for an
      existing "update profile" method.
  - [ ] If one exists, wire the Save button to it.
  - [ ] If none exists, build the UI and wire Save to a stub:
        `// TODO: call profile update API` + show a "Saved (stub)" alert, then
        **tell the supervisor** so we can add the backend call.
- [ ] Match the styling of other modals in the app (e.g. look at
      [components/ui/CurrencyPickerModal.tsx](../../components/ui/CurrencyPickerModal.tsx)
      for the modal pattern used here).

### ✅ Task 2 Acceptance
- [ ] SAVED stat shows the **real** number of saved hotels and updates when you
      add/remove a favorite and return to the tab.
- [ ] No fake/hardcoded counts remain (BOOKINGS, REVIEWS, price-alerts count).
- [ ] Tapping Edit / avatar opens a working name-edit UI, pre-filled.
- [ ] Save either calls a real method or a clearly-marked stub (supervisor notified).
- [ ] Works in light **and** dark mode.
- [ ] Committed: `feat(profile): real saved count and edit-profile UI`

---

## Task 3 — Add pull-to-refresh + optimized images to the Saved screen

**Why:** The Saved list can't be refreshed by the user, and it uses the raw
React Native `Image` (no caching, no placeholder) while the rest of the app uses
an optimized image component.

**Where:** [app/(tabs)/saved.tsx](../../app/(tabs)/saved.tsx)

### 3a — Add pull-to-refresh
- [ ] Import `RefreshControl` from `react-native`.
- [ ] Add state: `const [refreshing, setRefreshing] = useState(false);`
- [ ] Write a refresh handler that re-loads the list:
  ```tsx
  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      const list = await getSavedHotels();
      setHotels(list);
    } finally {
      setRefreshing(false);
    }
  }, []);
  ```
- [ ] Pass a `refreshControl` to the `FlatList` (~line 90):
  ```tsx
  refreshControl={
    <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={C.blue} colors={[C.blue]} />
  }
  ```
- [ ] Reference: [app/(tabs)/trips.tsx](../../app/(tabs)/trips.tsx) already uses
      `RefreshControl` — copy that pattern.

### 3b — Use OptimizedImage for the thumbnail
- [ ] Look at [components/ui/OptimizedImage.tsx](../../components/ui/OptimizedImage.tsx)
      to see its props.
- [ ] In Saved, find the `Image` at ~line 104.
- [ ] Replace it with `OptimizedImage` (import it from `@/components/ui/OptimizedImage`),
      passing the same `uri` and matching the existing `style` and
      `resizeMode`/`contentFit`.
- [ ] Remove the now-unused `Image` import **only if** nothing else in the file uses it.

### ✅ Task 3 Acceptance
- [ ] Pulling down on the Saved list shows a spinner and refreshes the data.
- [ ] Thumbnails fade in with a placeholder instead of popping in.
- [ ] No unused imports left behind (lint passes).
- [ ] Works in light **and** dark mode.
- [ ] Committed: `feat(saved): pull-to-refresh and optimized thumbnails`

---

## Task 4 — Make the saved-hotel date selection sensible

**Why:** Tapping any saved hotel always opens it with **today → tomorrow**, so a
hotel you saved for a future trip always shows same-day rates.

**Where:** [app/(tabs)/saved.tsx](../../app/(tabs)/saved.tsx) — `handleNavigate` (~line 52)

### 4a — Improve the default dates
- [ ] In `handleNavigate`, instead of check-in = today, default check-in to
      **7 days from today** and check-out to the night after.
  ```tsx
  const checkIn = new Date();
  checkIn.setDate(checkIn.getDate() + 7);
  const checkOut = new Date(checkIn);
  checkOut.setDate(checkIn.getDate() + 1);
  ```
- [ ] Use these in the `router.push` params (keep the existing `fmt` formatter).
- [ ] Keep adults/rooms as they are for now.

### 4b — (Bonus, only if time allows — confirm with supervisor first)
- [ ] Show a small date hint on the saved card, **or** let the user pick dates
      before opening. Keep scope small. **Do not** build a full custom date
      picker without asking first.

### ✅ Task 4 Acceptance
- [ ] Opening a saved hotel uses a future check-in (not same-day).
- [ ] Check-out is exactly one night after check-in.
- [ ] No regressions to the hotel detail screen.
- [ ] Committed: `fix(saved): use sensible default dates when opening a hotel`

---

## Task 5 — Accessibility & tap-target pass on icon-only buttons

**Why:** Icon-only buttons with no label are invisible to screen readers and are
often too small to tap reliably.

**Where:** Profile, Saved, and
[components/search/modals/ModalHeader.tsx](../../components/search/modals/ModalHeader.tsx)

### 5a — Add accessibility labels
- [ ] Saved: the heart "unsave" button (~line 160) →
      add `accessibilityLabel="Remove from saved"` and `accessibilityRole="button"`.
- [ ] Profile: the avatar camera button (~line 251) →
      `accessibilityLabel="Change profile photo"`.
- [ ] Modal header: any close/back icon button → add a matching label
      (`"Close"` / `"Back"`).

### 5b — Ensure tap targets are big enough
- [ ] Each icon-only button should have at least a ~44×44 tap area.
- [ ] Where the icon must stay visually small, add `hitSlop` to expand the
      touch area (the Saved heart already uses `hitSlop={8}` — apply the same
      idea to the others).

### 5c — Verify with a screen reader
- [ ] Turn on TalkBack (Android) or VoiceOver (iOS) on at least one screen.
- [ ] Swipe through the buttons and confirm each announces a meaningful label.

### ✅ Task 5 Acceptance
- [ ] Every icon-only button has an `accessibilityLabel`.
- [ ] Each has a comfortable tap target (real or via `hitSlop`).
- [ ] Verified once with a screen reader.
- [ ] Committed: `feat(a11y): labels and tap targets for icon buttons`

---

## Stretch tasks (optional — only after Tasks 1–5 are reviewed)

### S1 — Empty-state audit
- [ ] Compare the nice empty states in Saved and Trips against
      [app/flights.tsx](../../app/flights.tsx).
- [ ] Make sure every list has a friendly empty / no-results state in **both**
      themes.

### S2 — Loading skeletons
- [ ] The project has [components/ui/Skeleton.tsx](../../components/ui/Skeleton.tsx).
- [ ] Find a list that shows a blank screen or bare spinner while loading and
      swap in skeleton placeholders.

---

## Final submission checklist

- [ ] Branch `feat/ojt-ui-polish` pushed to the remote.
- [ ] One small, clearly-named commit per task.
- [ ] Every visual change tested in **light and dark** mode.
- [ ] No new hardcoded/fake data; all gaps marked with `// TODO`.
- [ ] `npm run lint` passes with no new warnings/errors.
- [ ] Before/after screenshots attached to the PR for each visual change.
- [ ] PR opened against `feat/hotel-changes` and assigned to the supervisor.
- [ ] Any stubbed handlers (e.g. profile update) flagged to the supervisor in
      the PR description.
