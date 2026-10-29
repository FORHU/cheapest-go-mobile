# CheapestGo Mobile App (Flutter — 3-Tier FAOS Architecture)

Flutter mobile application for CheapestGo (flights & hotels search, prebook, checkout, saved hotels, booked trips, and user profile), structured using the **3-Tier FAOS (Feature-Oriented Architecture Standard)** pattern (`lib/app/`, `lib/features/`, `lib/shared/`).

## Architecture Overview

```text
lib/
├── main.dart                     # Entrypoint & startup initialization
├── app/                          # Thin composer layer (zero business logic)
│   ├── app.dart                  # Root MaterialApp.router
│   ├── router/                   # GoRouter routes & 6-tab StatefulShellRoute
│   └── theme/                    # Material 3 light/dark themes
├── features/                     # Isolated business domains (cannot import each other)
│   ├── auth/                     # Lucia / JWT auth, RBAC Can widget, Login/Register/Reset
│   ├── hotels/                   # Search, details, Offer/Rate, Prebook lock, Stripe checkout
│   ├── flights/                  # Multi-provider flight search (Duffel & Mystifly) & checkout
│   ├── trips/                    # Booked trips & PNR status
│   ├── saved/                    # Device-local favorite / saved hotels
│   ├── explore/                  # Home landing & curated guides
│   └── profile/                  # Account, Display Currency (USD/PHP/KRW), Theme preferences
└── shared/                       # Deterministic infrastructure (never imports features/ or app/)
    ├── auth/                     # Role, Permission, RBAC evaluator
    ├── components/               # Skeleton loader
    ├── errors/                   # ApiError, error_router, retry_policy
    ├── flags/                    # Feature FlagEngine
    ├── lib/                      # env.dart, http.dart, token.dart
    ├── pagination/               # PaginationState
    ├── stores/                   # UiSettingsStore (Display Currency & ThemeMode)
    └── utils/                    # CurrencyService (live Frankfurter FX + fallback rates)

tools/
└── validate_architecture.dart    # Static import-boundary validator
```

## Boundary Rules (Enforced by `tools/validate_architecture.dart`)

- **Rule 1 (`shared/`):** Cannot import from `features/` or `app/`.
- **Rule 2 (`features/<name>/`):** Cannot import from any other feature (`features/<other>/`). Cross-feature composition happens strictly in `lib/app/`.
- **Rule 3 (`app/`):** Contains zero business logic and cannot import `package:http/http.dart` directly.
- **Rule 4:** Deep relative imports (`../..`) are forbidden; use `package:cheapest_go_mobile/...`.
- **Rule 5:** `feature_manifest.dart` is CI-only and must never be imported at runtime.

## Commands

```bash
# Install dependencies
flutter pub get

# Validate FAOS architectural boundaries
dart run tools/validate_architecture.dart

# Run static analysis
flutter analyze

# Run unit & widget tests
flutter test

# Start the app
flutter run
```
