# System Overview

## Purpose

The Flutter application is the user-facing client for the IMS platform. It provides authenticated inventory operations through a clean, beginner-friendly codebase and a modern Material 3 interface.

## Functional Modules

- Authentication: register, login, token restore, logout, password reset, profile update.
- Dashboard: summary metrics and quick actions.
- Products: browse, search, add, edit, delete, and view stock health.
- Stock operations: stock in and stock out with confirmation.
- Suppliers: list, add, edit, delete, and search.
- Transactions: filterable movement history.
- Settings: profile editing, theme mode, remember-me preference, password reset shortcut.

## Runtime Architecture

- `lib/main.dart`: initializes settings and auth services, then creates `MaterialApp`.
- `lib/routes.dart`: centralized route table with animated page transitions.
- `lib/screens/splash_screen.dart`: startup transition and auth routing decision.
- `lib/screens/startup_gate.dart`: backend health guard before dashboard rendering.
- `lib/services/auth_service.dart`: auth API integration and local session persistence.
- `lib/services/api_service.dart`: IMS business API integration.
- `lib/services/app_settings_service.dart`: persistent app-level preferences.
- `lib/widgets/app_drawer.dart`: shared module navigation plus logout.

## Request and State Flow

1. App starts and initializes persisted settings and auth token.
2. Splash screen decides route: authenticated flow or login flow.
3. Startup gate validates backend health.
4. Screen widgets fetch data through service classes.
5. Service classes call FastAPI endpoints.
6. UI updates with success states, empty states, or snackbar errors.

## UX Conventions

- Material 3 components with custom light and dark themes.
- Drawer-based navigation for all major modules.
- Pull-to-refresh for list-like screens.
- Confirmation dialogs before destructive or critical operations.
- Snackbars for operation feedback.
- Consistent price language in product module: UGX.

## Backend Contract

### Core IMS endpoints

- `GET /health/db`
- `GET /dashboard`
- `GET /products`
- `POST /products`
- `PUT /products/{id}`
- `DELETE /products/{id}`
- `GET /suppliers`
- `POST /suppliers`
- `PUT /suppliers/{id}`
- `DELETE /suppliers/{id}`
- `GET /transactions`
- `POST /stock_in`
- `POST /stock_out`

### Auth endpoints

- `POST /auth/register`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/logout`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`
- `PUT /auth/profile`

## Session and Settings Persistence

- Auth token and remember-me preference are managed in `AuthService`.
- Theme mode is managed in `AppSettingsService` via `ValueNotifier<ThemeMode>`.
- Settings changes propagate immediately through app-level listeners.

## Design Objective

The project intentionally uses clear separation by feature and small methods so developers can reason about behavior quickly, debug safely, and extend features without broad rewrites.
