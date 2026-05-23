# Development Guide

This guide provides practical commands and engineering conventions for developing the IMS Flutter app and its FastAPI backend.

## Project Layout

- `frontend/ims_app/lib/main.dart` - app entry point and theme.
- `frontend/ims_app/lib/routes.dart` - named routes and page transitions.
- `frontend/ims_app/lib/services/auth_service.dart` - auth/session/reset/profile integration.
- `frontend/ims_app/lib/services/app_settings_service.dart` - theme preference persistence.
- `frontend/ims_app/lib/services/api_service.dart` - backend API calls.
- `frontend/ims_app/lib/screens/` - all UI pages.
- `frontend/ims_app/lib/widgets/` - reusable widgets.
- `frontend/ims_app/test/widget_test.dart` - smoke test.
- `backend/main.py` - FastAPI backend.
- `database.sql` - SQL schema reference including auth tables.

## How to Run

### Flutter app

```bash
cd frontend/ims_app
flutter pub get
flutter run
```

### Backend API

```bash
cd backend
source ../.venv/bin/activate
python -m uvicorn main:app --reload
```

Alternative from repository root:

```bash
source .venv/bin/activate
python -m uvicorn backend.main:app --reload
```

## How the app connects

- Web and desktop use `http://127.0.0.1:8000`.
- Android emulator uses `http://10.0.2.2:8000`.
- Physical devices need a reachable LAN IP or a tunneled backend URL.

## Core Development Rules

- Keep route registration in `lib/routes.dart` as single source of truth.
- Keep API calls inside service classes; do not call HTTP directly from widgets.
- Always validate form fields before submit actions.
- Show user feedback for success/failure using snackbars or dialogs.
- Use confirmation dialogs for delete and critical operations.
- Keep product price text and labels consistent as UGX.

## Useful Editing Rules

- Keep screens small and focused.
- Reuse `AppDrawer` instead of building a separate drawer in every page.
- Keep API calls inside `ApiService`.
- Add validation before sending form data.
- Use confirmation dialogs for destructive actions.

## Verification Checklist After Changes

1. Run static analysis:

```bash
cd frontend/ims_app
flutter analyze
```

2. Run widget tests:

```bash
cd frontend/ims_app
flutter test
```

3. Validate backend syntax quickly:

```bash
cd backend
python -m py_compile main.py
```

4. Manual sanity check in app:

- login/register flow
- drawer navigation
- settings profile save
- products CRUD with UGX price labels
- stock movement and transactions

## Testing

The project already has a widget smoke test. Run it after UI changes.

```bash
cd frontend/ims_app
flutter test
```

## Adding a New Page

1. Create a new file in `lib/screens/`.
2. Add the route in `lib/routes.dart`.
3. Add a drawer item in `lib/widgets/app_drawer.dart`.
4. Connect the page to `ApiService` if it needs backend data.
5. Add the page to this documentation folder.

## Updating Existing Pages Safely

1. Identify all route entry points and callers.
2. Update UI text, validation, and backend payload mapping together.
3. Keep compatibility export files intact if imports depend on old names.
4. Run analyzer and tests before launch.
5. Hot restart app, and if stale state persists, launch a fresh run process.

## Documentation Maintenance

When implementation changes, update all five docs in the same PR:

1. `docs/README.md` for high-level manual updates.
2. `docs/system_overview.md` for contracts and architecture.
3. `docs/pages_guide.md` for visible UX behavior.
4. `docs/code_walkthrough.md` for file-level technical notes.
5. `docs/error_handling.md` for failure modes and recovery.

## Notes for Beginners

- Prefer simple widgets over custom packages.
- Keep state local unless you really need shared state.
- Use `FutureBuilder` for API-backed pages.
- Use `RefreshIndicator` for lists that can reload.
- Use `showDialog` for confirm-before-action flows.
