# main.dart Runtime Troubleshooting

This document explains why the app may appear unusable when you run `lib/main.dart`, especially during register/login.

## Short answer

Running `lib/main.dart` starts only the Flutter UI app.
It does not start the FastAPI backend.
If backend APIs are unavailable, most app actions fail.

## Why the app can look like it "cannot do anything"

The app is API-driven:

- Startup health check calls `GET /health/db`.
- Auth calls backend endpoints (`/auth/register`, `/auth/login`, `/auth/me`, `/auth/logout`).
- Inventory modules call product, supplier, stock, dashboard, and transaction endpoints.

If backend is down, unreachable, or misconfigured, screens can show:

- database offline state
- request failures
- register/login error snackbars

## Why register shows an error

Registration uses `POST /auth/register`.
Common causes of failure:

1. Backend is not running on `http://127.0.0.1:8000`.
2. Backend is running but database connection is offline.
3. Email already exists (backend returns 400).
4. Invalid or unexpected backend response.

Typical user-visible messages include:

- `Register failed (400): An account already exists for that email`
- network/client exceptions when the API host cannot be reached

## Verify your local run setup

From repository root, run backend first:

```bash
source .venv/bin/activate
python -m uvicorn backend.main:app --reload
```

Then run Flutter app:

```bash
cd frontend/ims_app
flutter pub get
flutter run -d linux
```

## Fast checks when it fails

1. Open `http://127.0.0.1:8000/health` in a browser.
2. Open `http://127.0.0.1:8000/health/db` and confirm `status` is `ok`.
3. Confirm device base URL mapping in `lib/services/api_service.dart` matches your target device.
4. Check backend terminal logs while pressing Register/Login.

## Important behavior to remember

- `main.dart` boots Flutter only.
- Backend must be running for auth and inventory operations.
- Without backend, UI opens, but functional actions fail by design.
