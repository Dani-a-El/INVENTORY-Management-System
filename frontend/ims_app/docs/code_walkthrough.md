# Code Walkthrough

This walkthrough explains how the current Flutter IMS app is structured and how core features are implemented.

## `lib/main.dart`

This file is the app entry point.

- `main()` starts the app with `IMSApp`.
- `_IMSAppState` bootstraps settings and auth services before UI routing.
- A loading scaffold is shown while bootstrap is running.
- `ValueListenableBuilder<ThemeMode>` listens to `AppSettingsService` for live theme changes.
- `initialRoute` is `AppRoutes.splash`.
- Route generation is delegated to `AppRoutes.onGenerateRoute`.

### Theme helpers

- `_buildLightTheme()` defines color system, card style, input style, button style, FAB style, and drawer style.
- `_buildDarkTheme()` provides the dark color seed and Material 3 setup.

## `lib/routes.dart`

This file defines named routes.

- Route constants include `splash`, `login`, `register`, `forgotPassword`, `settings`, `dashboard`, `products`, `stock`, `suppliers`, and `transactions`.
- `onGenerateRoute()` picks the correct screen for each route.
- `_buildRoute()` wraps each page in a `PageRouteBuilder`.
- The transition uses a fade plus a small slide animation.
- `buildPageRoute()` is used when opening forms and detail pages.

## `lib/services/auth_service.dart`

This file manages the backend-backed auth state.

- `AuthUser` is a small data class for id, name, and email.
- `AuthService.instance` is the singleton used across the app.
- `initialize()` restores the saved token and current user.
- `signIn()` calls `POST /auth/login`.
- `signUp()` calls `POST /auth/register`.
- `requestPasswordReset()` calls `POST /auth/forgot-password`.
- `resetPassword()` calls `POST /auth/reset-password`.
- `updateProfile()` calls `PUT /auth/profile`.
- `signOut()` calls `POST /auth/logout` and clears the session.
- `updateRememberMePreference()` controls whether token/session data is persisted.

## `lib/services/app_settings_service.dart`

This file stores app preferences.

- It persists the selected theme mode.
- It exposes a `ValueNotifier<ThemeMode>` so the app updates instantly when the theme changes.

## `lib/screens/splash_screen.dart`

This file handles startup routing.

- It initializes auth data on app launch.
- It shows a loading screen during startup.
- It routes to login if no session exists.
- It routes to the dashboard if the user is already signed in.
- It safely cancels delayed navigation timer during dispose.

## `lib/screens/login_screen.dart`

This file contains the sign-in form.

- It validates email and password.
- It toggles password visibility.
- It includes a remember-me checkbox.
- It signs the user in with the backend auth service.
- It links to the register screen.
- It links to the forgot-password screen.

## `lib/screens/register_screen.dart`

This file contains the registration form.

- It validates name, email, password, and password confirmation.
- It checks that both passwords match.
- It sends the new account to the backend.
- It returns the user to the login screen after registering.

## `lib/screens/forgot_password_screen.dart`

This file handles password reset.

- It requests a reset code from the backend.
- It displays the reset code in the UI for the demo flow.
- It submits the code and new password to reset the account password.

## `lib/screens/settings_screen.dart`

This file handles app preferences.

- It shows current signed-in user identity.
- It provides editable profile fields for name and email.
- It saves profile updates through `AuthService.updateProfile()`.
- It toggles dark mode.
- It toggles remember-me behavior.
- It links to the forgot-password screen.
- It includes `AppDrawer` so users can navigate from settings.
- It shows a back button when `Navigator.canPop` is true.

## `lib/screens/startup_gate.dart`

This file protects the app from showing a broken UI when the backend is offline.

- `StartupGate` starts a database health check in `initState()`.
- `FutureBuilder` listens to that health check.
- While waiting, the app shows a loading spinner.
- If the database is offline, the app shows a retry screen.
- If the database is online, the dashboard is shown.
- If user session is missing, it redirects to login.

## `lib/services/api_service.dart`

This file handles all HTTP requests.

- `baseUrl` chooses the correct backend URL for web, Android emulator, or desktop.
- `client` stores the reusable HTTP client.
- `_ensureSuccess()` checks whether the HTTP response is successful.
- `checkDatabaseHealth()` reads the health endpoint.
- `getProducts()`, `getDashboard()`, `getTransactions()`, and `getSuppliers()` load data.
- `addProduct()`, `updateProduct()`, `deleteProduct()` manage products.
- `stockIn()` and `stockOut()` post stock movement requests.
- `addSupplier()`, `updateSupplier()`, and `deleteSupplier()` manage suppliers.

## `lib/widgets/app_drawer.dart`

This file builds the side navigation drawer.

- The top section shows a profile header.
- The drawer items point to each main page.
- The selected route is highlighted.
- Tapping a drawer item closes the drawer and navigates with replacement.
- Logout signs out and resets route stack to login.

## `lib/screens/dashboard.dart`

This file builds the dashboard page.

- It loads dashboard data, health data, and suppliers together.
- It shows the hero card with summary statistics.
- It shows quick action buttons.
- It shows a simple animated stock chart built with basic Flutter widgets.
- It supports pull-to-refresh.

## `lib/screens/product_list.dart`

This file builds the product list and product form.

- The list page fetches products from the backend.
- Search filters the cards by product name, SKU, or category.
- Each product card shows key inventory details.
- Price is rendered explicitly in UGX.
- Swipe gestures allow quick edit and delete actions.
- The floating action button opens the product form.
- The form can create or edit a product.
- Price input uses `Price (UGX)` labeling and `UGX` prefix.

## `lib/screens/stock_in_out.dart`

This file handles stock movements.

- It fetches products for the dropdown.
- It validates the selected product and quantity.
- It lets the user pick stock in or stock out.
- A confirmation dialog appears before submission.
- A success dialog confirms the result after the backend responds.

## `lib/screens/supplier_list.dart`

This file handles suppliers and the supplier form.

- The page fetches suppliers from the backend.
- Search filters suppliers by name, contact, or email.
- Each supplier card shows contact data and action icons.
- The form can add or edit a supplier.
- Delete uses a confirmation dialog.

## `lib/screens/transaction_history.dart`

This file displays stock activity.

- It loads the transaction list from the backend.
- Search matches product name, transaction type, or timestamp text.
- Filter chips limit the list to stock in or stock out.
- A date picker filters by day.
- Transaction cards use color to make the movement type easy to read.

## Compatibility files

These files exist only to preserve old import paths:

- `lib/screens/dashboard_screen.dart`
- `lib/screens/product_list_screen.dart`
- `lib/screens/stock_screen.dart`
- `lib/screens/supplier_list_screen.dart`
- `lib/screens/transaction_history_screen.dart`
- `lib/widgets/main_drawer.dart`

Each of them re-exports the newer file with the cleaner name.
