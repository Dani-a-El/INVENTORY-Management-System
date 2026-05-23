# ims_app

Flutter client for the Inventory Management System (IMS).

## Documentation

The full manual is available at [docs/README.md](docs/README.md).

- [System Overview](docs/system_overview.md): architecture, data flow, and endpoint contracts.
- [Pages Guide](docs/pages_guide.md): screen-by-screen behavior and user actions.
- [Code Walkthrough](docs/code_walkthrough.md): implementation-level guidance by file.
- [Error Handling Guide](docs/error_handling.md): common errors and recovery workflow.
- [Development Guide](docs/development_guide.md): setup, run commands, test checklist, and extension rules.

## Core Features

- Auth flow: splash, login, register, forgot password, logout.
- Inventory modules: dashboard, products, stock operations, suppliers, transactions.
- Settings: profile update, dark mode, remember-me, password reset shortcut.
- Product prices displayed and entered in UGX.

## Getting Started

```bash
cd frontend/ims_app
flutter pub get
flutter run
```

Backend (from `backend/`):

```bash
source ../.venv/bin/activate
python -m uvicorn main:app --reload
```

For general Flutter reference:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
