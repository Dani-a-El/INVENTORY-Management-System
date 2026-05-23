# Backend, SQLite, and Offline FAQ

This FAQ clarifies how the IMS app behaves with SQLite, backend auth, and offline usage.

## 1) Does the system run with only SQLite?

Yes, with one condition: backend must still run.

The backend defaults to SQLite (`DB_ENGINE=sqlite`) and auto-creates required tables on startup.
So you can run fully local without MySQL, as long as FastAPI is up.

## 2) Can I log in without backend involvement?

No.

Login is backend-authenticated (`POST /auth/login`) and session restore uses `GET /auth/me`.
There is no local-only auth mode in the current app.

## 3) Can I register users offline?

No, not in the current implementation.

Registration is server-side (`POST /auth/register`).
If backend is unavailable, registration cannot complete.

## 4) Can the app work offline?

Partially, but not for core inventory operations.

What can still work locally:

- App launch and static UI rendering
- Locally stored settings (theme, remember-me preference)

What requires backend connectivity:

- register, login, profile update, logout sync
- dashboard metrics
- products CRUD
- suppliers CRUD
- stock in/out
- transactions list

## 5) Does "offline" mean no internet, or no backend?

These are different:

- No internet + local backend running: app can still work.
- Backend down/unreachable: core features fail, even with internet.

The app depends on API reachability, not public internet.

## 6) Why do I see database offline state?

Startup flow checks `GET /health/db`.
If backend cannot query its configured database, app shows offline retry state.

## 7) Can this app be made truly offline-first?

Yes, but it needs additional architecture:

1. Local data store (for example SQLite in Flutter via Drift/Sqflite).
2. Write queue for pending mutations.
3. Sync engine with conflict resolution.
4. Auth strategy for offline sessions and revalidation.

Those capabilities are not implemented yet in the current codebase.

## Recommended local-only setup (no MySQL)

Run backend with default SQLite mode:

```bash
source .venv/bin/activate
python -m uvicorn backend.main:app --reload
```

Run Flutter app:

```bash
cd frontend/ims_app
flutter run -d linux
```

This is the easiest setup for development when you do not want Docker/MySQL.
