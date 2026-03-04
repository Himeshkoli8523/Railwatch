# CCTV Train Monitoring UI (Minimal Production-Ready)

Flutter UI scaffold for an Enterprise IoT CCTV Train Monitoring Platform.

## Run

1. `flutter pub get`
2. `flutter run --dart-define=FLAVOR=dev`

Supported flavors: `dev`, `staging`, `prod`.

## Expected Clean Architecture Structure

```text
lib/
├─ core/ (error, network, utils, constants)
├─ features/
│  ├─ auth/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ dashboard/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ videos/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ alerts/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ profile/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  └─ settings/
│     ├─ data/
│     ├─ domain/
│     └─ presentation/
└─ main.dart
```

Composition root and dependency wiring are in `lib/app/`.

## Auth UI (API-aligned)

Auth screen now matches onboarding/password API payloads with mock flows:

- `POST /auth/login` (`phone_no`, `password`)
- `POST /auth/signup` (`full_name`, `phone_no`, `email?`, `password`, `zone`, `division`, `location`)
- `POST /auth/forgot-password` (`phone_no`)
- `POST /auth/change-password` (`new_password`, optional `phone_no`/`reset_token`)
- `POST /auth/change-password/authenticated` (`new_password`)

No live backend call is performed yet; forms are wired to local mock client methods.

## Offline / Slow Backend Simulation

- Open Settings tab.
- `Toggle offline` to show offline banner and last sync.
- `Toggle slow backend` to show slow-backend fallback banner.
- `Resolve conflict` opens Keep Local / Keep Server modal.

## Mock API Stubs

Implemented in `lib/core/network/mock_api_client.dart`:

- Auth onboarding and password endpoints listed above
- `GET /api/videos` style pagination/filter mock
- `GET /api/stream/{file_path}` style playback placeholder flow
- report/bucket-oriented dashboard placeholders

Mock payload file: `assets/mock_data.json`

## Videos UI

- Debounced search + horizontal filter chips
- Infinite scroll pagination
- Toggle between `List` and `Grid` views for gallery-style browsing
- Detail view keeps secure playback indicator and metadata/report-oriented actions

## Sequence Diagram (ASCII)

```text
User             Videos UI                 Video Detail UI
 | select item       |                            |
 |------------------>| push /video route          |
 |                   |--------------------------->| load metadata + stream placeholder
 |                   |                            | show signed-status + markers
 |                   |                            | render report/download actions
```

## State Flow Summary

Global state (Riverpod providers):

- auth/session (`authProvider`)
- connection/reconnect/offline (`connectionProvider`)
- user profile (`authProvider.user`)
- offline status + last sync (`connectionProvider`)
- notifications and sync queue

Local state (screen-scoped):

- video list selection and search debounce
- list/grid toggle and item selection
- filters and modals (auth/settings/videos)
- temporary loading/error placeholders

## Notes

- UI keeps AI outputs as simple tags + confidence labels only.
- No advanced overlays/heatmaps are implemented by design.

