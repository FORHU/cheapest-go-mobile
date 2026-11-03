# CheapestGo Mobile App (Flutter — 3-Tier FAOS Architecture)

Flutter mobile application for CheapestGo (stays and golf near your arrival airport: airport hubs, hotel booking, tee times, trips, and profile; currently on mock data), structured using the **3-Tier FAOS (Feature-Oriented Architecture Standard)** pattern (`lib/app/`, `lib/features/`, `lib/shared/`).

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
│   ├── home/                     # Arrival airport search (Stays / Golf / Stay + Golf)
│   ├── airports/                 # Airport hub: stays and golf nearest one airport
│   ├── hotels/                   # Results, detail + room choice, checkout (mock payment)
│   ├── golf/                     # Courses near the airport, tee times, tee-time booking
│   ├── map/                      # Mapbox 3D globe / 2D map with airport hubs
│   ├── trips/                    # Upcoming / past bookings and saved stays
│   └── profile/                  # Account, theme (system / light / dark), map preferences
└── shared/                       # Deterministic infrastructure (never imports features/ or app/)
    ├── auth/                     # Role, Permission, RBAC evaluator
    ├── catalog/                  # TravelCatalog interface + MockTravelCatalog (airports, hotels, golf)
    ├── components/               # UI kit (cards, rating badge, tabs, pills), airport picker, buttons
    ├── errors/                   # ApiError, error_router, retry_policy
    ├── flags/                    # Feature FlagEngine
    ├── lib/                      # env.dart, http.dart, token.dart
    ├── pagination/               # PaginationState
    ├── stores/                   # Trip search, bookings, saved stays, UI settings (ThemeMode, map)
    ├── theme/tokens/             # AppColors light + dark (v1 web theme), radius, spacing, effects
    └── utils/                    # Peso, date, and tee-time formatting

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
