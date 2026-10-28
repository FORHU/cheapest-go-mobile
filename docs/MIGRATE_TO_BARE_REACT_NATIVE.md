# Migrating to Bare React Native (Windows + WSL2)

Build the app with the native `android/` folder committed and compiled directly via the
RN CLI. Expo packages and `expo-router` stay. **On Windows you must build inside WSL2** —
native Windows hits a hard path-length limit in the C++ build.

> iOS is not covered: the `ios/` folder must be generated and built on a **Mac**.

---

## Phase 1 — Commit the native Android project (one-time)

1. In [`.gitignore`](../.gitignore), keep `/android` and `/ios` un-ignored (tracked).
2. Remove the secret Mapbox `sk.` token line from `android/gradle.properties` before
   committing (it's read from the `RNMAPBOX_MAPS_DOWNLOAD_TOKEN` env var instead).
3. Commit:
   ```bash
   git add .gitignore android/
   git commit -m "chore: commit native android project for bare React Native workflow"
   ```

---

## Phase 2 — Install WSL2 + Ubuntu (one-time)

```powershell
wsl --install -d Ubuntu
```
Create a UNIX username + password on first launch.

---

## Phase 3 — Install the Linux toolchain (one-time)

From inside Ubuntu, run the setup script (installs JDK 17, Node 20, Android SDK, NDK 27,
CMake 3.22.1 and sets `ANDROID_HOME`/`JAVA_HOME`):
```bash
sed -i 's/\r$//' /mnt/c/Users/USER/Documents/GitHub/cheapestGo-mobile-app/scratch/setup-wsl.sh
bash /mnt/c/Users/USER/Documents/GitHub/cheapestGo-mobile-app/scratch/setup-wsl.sh
source ~/.bashrc
node -v && java -version && adb version   # verify
```

---

## Phase 4 — Clone into the Linux filesystem (one-time)

> Do **not** build from `/mnt/c` — the project must live under your Linux home.

```bash
git config --global --add safe.directory '*'
git clone /mnt/c/Users/USER/Documents/GitHub/cheapestGo-mobile-app ~/projects/cheapestGo-mobile-app
cd ~/projects/cheapestGo-mobile-app
git checkout chore/bare-react-native
npm install
npm install --save-dev @react-native-community/cli@^20.2.0
chmod +x android/gradlew
```

---

## Phase 5 — Connect your phone (Wi-Fi) and build

On the phone (Android 11+, same Wi-Fi): **Developer Options → Wireless debugging → ON**,
then open **Pair device with pairing code**.

```bash
adb pair <ip>:<pairing-port>      # enter the 6-digit code
adb connect <ip>:<connect-port>   # the main-screen port (different from pairing)
adb devices                       # must show your phone as "device"

npx react-native run-android
```

---

## Quick fixes

| Error | Fix |
|---|---|
| `dubious ownership` | `git config --global --add safe.directory '*'` |
| `spawn ./gradlew EACCES` | `chmod +x android/gradlew` |
| `depends on @react-native-community/cli` | `npm i -D @react-native-community/cli@^20.2.0` |
| `adb connect` times out | Set `networkingMode=mirrored` in `~/.wslconfig`, then `wsl --shutdown` |
| `npx react-native doctor` errors (Android Studio/SDK/Metro) | Ignore — false positives on headless WSL |
