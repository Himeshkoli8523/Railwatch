# CCTV Train Monitoring UI (Minimal Production-Ready)

Flutter UI scaffold for an Enterprise IoT CCTV Train Monitoring Platform.

## Run

1. `flutter pub get`
2. `flutter run --dart-define=API_BASE_URL=<your Device/lan IP add>:8000`
3. `cd D:\cctv\backend`
4. `python -m venv .venv`
5. `.\.venv\Scripts\Activate.ps1`
6. `pip install -r requirements.txt`
7. `uvicorn main:app --host 0.0.0.0 --port 8000 --reload`

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

## Part 2: Scalability & Resilience Design

This section documents architecture decisions for large-scale video workloads and failure handling,
and explicitly marks what is already implemented vs what is planned.

Status labels used below:

- `Implemented`: available in the current codebase
- `Working Phase`: should be implemented next
- `Future`: planned for later phases

### 1) Scalability Challenge: Listing 100,000+ videos

Architecture answer:

- Use cursor-based pagination on the API contract (stable sort by timestamp + id).
- Fetch only lightweight list payloads first (id, camera, train, timestamp, severity, thumbnail URL),
	then fetch details on demand.
- Render with virtualized builders (`ListView.builder` / `GridView.builder`) and incremental loading.
- Keep filters/search server-side for very large datasets to avoid client-wide scans.

Status:

- `Implemented`:
	- Infinite scrolling + paged fetch flow in `lib/features/videos/presentation/video_list_screen.dart`
	- Cursor-based list state in `lib/features/videos/presentation/videos_provider.dart`
	- Virtualized rendering (`ListView.builder` and `GridView.builder`) in video list screens
- `Working Phase`:
	- Move backend `/api/videos` to true server-side pagination/cursor response (currently returns full filtered list)
	- Add backend indexes and query optimization for train/camera/time filters
- `Future`:
	- Pre-computed timeline partitions (day/week buckets) for fast deep history navigation
	- CDN edge thumbnail variants for high-scale fleet browsing

### 2) Resilience Challenge: Backend slowdown / partial data

Architecture answer:

- Enforce request timeout + bounded retries for idempotent GET requests.
- Return and display partial data sections when one backend dependency is slow.
- Use stale-cache fallback for read-only views when live fetch fails.
- Surface degradation state in UI without blocking the whole screen.

Status:

- `Implemented`:
	- HTTP timeout in `lib/core/network/api_client.dart` (`12s`)
	- Slow/offline UI banners in `lib/app/main_shell.dart`
	- Safe fallback values in dashboard repository on API failure in `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart`
	- Manual retry actions on multiple screens (zones/cameras/video list)
- `Working Phase`:
	- Add centralized retry policy (exponential backoff + jitter) in API client wrapper
	- Add stale-cache read fallback for zones/cameras/video lists
	- Add explicit partial-data response contract in backend endpoints
- `Future`:
	- Circuit breaker and per-endpoint health metrics
	- Graceful degradation mode with feature-level kill switches

### 3) Performance: Memory optimization, lazy thumbnails, avoiding UI freezes

Architecture answer:

- Keep only current pages in memory and evict old pages when thresholds are crossed.
- Lazy-load thumbnails with placeholders, error fallback, and bounded decode size.
- Avoid heavy parsing on main isolate; move expensive transforms to background isolate when needed.
- Prevent large synchronous rebuilds by limiting widget scope and using immutable page appends.

Status:

- `Implemented`:
	- Lazy thumbnail loading with placeholders/error fallback via `Image.network` builders in video screens
	- Virtualized list/grid rendering to avoid loading all widgets at once
	- Debounced search in `lib/features/videos/presentation/videos_provider.dart`
- `Working Phase`:
	- Add image cache policy (max objects/bytes) and thumbnail downscaling strategy
	- Add page-window eviction for very long browsing sessions
	- Add isolate-based parsing for very large payloads
- `Future`:
	- Predictive thumbnail prefetch for next viewport window
	- Adaptive quality thumbnails based on network class and device memory

Status:

- `Implemented`:
	- Stream/player failure state with user-triggered retry in `lib/features/videos/presentation/video_player_screen.dart`
	- Offline banner and sync queue placeholder in `lib/core/widgets/common_widgets.dart`
	- Thumbnail failure fallback icons in list/grid video cards
- `Working Phase`:
	- Add AI job status fields and failure reason propagation from backend to UI
	- Add request retry tokens/idempotency for mutation endpoints
	- Add automatic reconnection strategy for interrupted stream sessions
- `Future`:
	- Persistent offline action queue with conflict resolution
	- End-to-end failure tracing (request id, AI job id, user-visible diagnostics)

## Delivery Note

This README section is the source of truth for Part 2 design commitments.
Any item marked `Working Phase` or `Future` should be tracked in sprint planning before production rollout.





