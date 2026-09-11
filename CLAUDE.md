# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Scanrix frontend: a Flutter app (package name `scanrix_frontend`, org `com.scanrix`) that
consumes the Scanrix backend (`../scanrix-backend`, FastAPI) — a "health product scanner".
Given a barcode (camera/manual entry) or OCR'd ingredient text, it shows an ingredient-level
safety analysis.

Product vision, problem statement, and target users: see [VISION.md](VISION.md).

Clean architecture + `flutter_bloc` for state management, `get_it` as a manual service
locator for DI. **No repository/interface layer by design** — domain use cases call the
API directly rather than going through a `Data` implementation of a `Domain`-defined
interface. This was a deliberate simplification (fewer files, faster to build against a
backend that's still moving) traded off against easier mocking/swapping later — see
`../scanrix-backend/CLAUDE.md` if you need backend context, and revisit this decision if
the app outgrows it.

**Networking is not wired up yet.** Every use case currently `throw`s `UnimplementedError`
with a `TODO` at the call site — see "Status / what's not done yet" below before assuming
any feature works end-to-end.

## Commands

```bash
# Setup
flutter pub get

# Run the app (needs the backend running — see ../scanrix-backend/CLAUDE.md)
flutter run

# Static analysis (must stay clean — no issues as of this writing)
flutter analyze

# Tests
flutter test
```

Flutter 3.35.6 / Dart 3.9.2 at time of scaffolding (`flutter --version`). No CI configured.

## Architecture

Each feature under `lib/features/<name>/` follows the same three-layer shape:

```
domain/
  entities/    # plain Dart classes (Equatable), no JSON knowledge
  usecases/    # implements core/usecase/UseCase<R, Params>; where the API call happens
data/
  models/      # extends the matching entity, adds fromJson()/toJson()
presentation/
  bloc/        # <name>_bloc.dart, <name>_event.dart, <name>_state.dart (flutter_bloc)
  pages/       # top-level route widgets
  widgets/     # feature-local widgets (currently empty — just .gitkeep)
```

- `lib/core/constants/api_constants.dart` — base URL + every endpoint path, kept in sync
  with the backend's `app/api/v1/api.py` route prefixes (`/auth`, `/products`, `/scan`,
  `/history`). **Update `baseUrl` here** to point at wherever the backend is actually
  running.
- `lib/core/usecase/usecase.dart` — `abstract class UseCase<R, Params> { Future<R> call(Params params); }`.
  Every use case implements this so Blocs can call them uniformly.
- `lib/core/error/exceptions.dart` — `ServerException`, `NetworkException`. Use cases are
  expected to throw these once networking is wired up; Blocs already catch generic
  exceptions in their event handlers and map them to a `*Failure` state.
- `lib/core/network/dio_client.dart` — currently just a `TODO` comment. This is where the
  shared Dio instance (base options, JWT bearer interceptor) is meant to go.
- `lib/core/di/injection_container.dart` — `final sl = GetIt.instance;` plus `Future<void> init()`,
  called once from `main()` before `runApp`. Registers every use case
  (`registerLazySingleton`) and every Bloc (`registerFactory`). When Dio is added, register
  it here first and inject it into use case constructors.
- `lib/app.dart` — `ScanrixApp`: wraps `MaterialApp` in a `MultiBlocProvider` that pulls
  every top-level Bloc from `sl`. Currently boots straight to `LoginPage`; there's no
  router/auth-gate yet.
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` → `di.init()` → `runApp`.

### Feature ↔ backend endpoint map

| Feature    | Backend route                                  | Notes |
|------------|-------------------------------------------------|-------|
| `auth`     | `POST /auth/register`, `POST /auth/login`       | `AuthTokenEntity` mirrors the `Token` schema; login doesn't yet persist the token anywhere (no secure storage set up). |
| `products` | `GET /products/{barcode}`                       | `ProductEntity.isAnalyzing` is true when `verdict == "analyzing"` — the backend runs AI analysis as a background task, so the product page is expected to **poll** this endpoint until the verdict flips (see backend's scan flow docs). Polling isn't implemented yet. |
| `scan`     | `POST /scan/`, `POST /scan/analyze-text`        | `analyze-text` is the OCR path — synchronous, nothing persisted server-side. Its response is `{"success": bool, "analysis": {...}}`; `TextAnalysisModel.fromJson` expects the inner `analysis` object directly, not the wrapper — the use case will need to unwrap `["analysis"]` before parsing. |
| `history`  | `GET /history/?limit=`                          | `ScanHistoryEntity` mirrors `history_helper()`'s dict, not a Pydantic schema (backend returns `List[dict]`). |

## Status / what's not done yet

- **No Dio (or any HTTP client) dependency added.** Every use case's `call()` throws
  `UnimplementedError`. This is the main next step.
- No token storage (e.g. `flutter_secure_storage`) — nothing persists the JWT from login yet.
- No routing package — `app.dart` hardcodes `home: const LoginPage()`. Navigation between
  auth → scan → product detail → history isn't wired.
- Pages (`login_page.dart`, `register_page.dart`, `scan_page.dart`,
  `product_detail_page.dart`, `history_page.dart`) are all placeholder `Scaffold`s with a
  single `Text` widget — no forms, no `BlocBuilder`/`BlocListener` wiring to their Blocs yet.
- `presentation/widgets/` folders are empty (just `.gitkeep`) in every feature.
- No camera/barcode-scanning or OCR package chosen yet, despite `scan` being the core flow.

## Gotchas

- The Flutter client is expected to **poll** `GET /products/{barcode}` after a scan until
  `verdict` is no longer `"analyzing"` (`"error"`/`"unknown"` are terminal too) — this is a
  backend design choice (see `../scanrix-backend/CLAUDE.md`'s "Scan flow" section), not
  optional client behavior.
- `core/di/injection_container.dart` registers Blocs with `registerFactory` (a new instance
  every `sl<XBloc>()` call) and use cases with `registerLazySingleton` (one shared instance).
  Keep that split when adding new features — don't singleton a Bloc.
