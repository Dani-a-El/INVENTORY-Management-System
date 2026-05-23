# Error Handling Guide

This file explains the most common runtime and user-facing errors in the IMS Flutter app and the recommended fix workflow.

## 1. Database offline on startup

### Where it happens

- `lib/screens/startup_gate.dart`
- `lib/services/api_service.dart`

### What you see

- A screen with a cloud-off icon.
- The message says the database is offline.
- A retry button is shown.

### Why it happens

- The FastAPI backend is not running.
- The backend cannot reach the database.
- The API URL is wrong for the current device.

### Solution

- Start the backend.
- Check the database configuration.
- Make sure the app is using the right `baseUrl`.
- Press Retry after fixing the connection.

## 2. Login fails because the account does not exist

### Where it happens

- `lib/screens/login_screen.dart`
- `lib/services/auth_service.dart`

### What you see

- A snackbar with backend message such as account not found.

### Why it happens

- The email has not been registered yet.
- The user typed a different email than the one they registered.

### Solution

- Use the correct email.
- Register a new account first.
- Check for spelling mistakes in the email address.

## 3. Login fails because the password is wrong

### Where it happens

- `lib/screens/login_screen.dart`
- `lib/services/auth_service.dart`

### What you see

- A snackbar with backend message such as invalid credentials.

### Why it happens

- The password does not match the saved account.

### Solution

- Re-enter the password carefully.
- Use the forgot-password screen if you need to reset the password.

## 4. Password reset code is missing or invalid

### Where it happens

- `lib/screens/forgot_password_screen.dart`
- `lib/services/auth_service.dart`

### What you see

- A snackbar or error message saying the reset code is invalid.

### Why it happens

- The reset code was copied incorrectly.
- The reset code expired.
- A newer reset code was generated and the old one is no longer active.

### Solution

- Request a fresh reset code.
- Copy the code exactly.
- Make sure the email matches the account being reset.

## 5. Profile update fails in settings

### Where it happens

- `lib/screens/settings_screen.dart`
- `lib/services/auth_service.dart`

### What you see

- A snackbar with profile update failure message.

### Why it happens

- Bearer token is missing or expired.
- Email value is malformed.
- Backend profile endpoint rejected the request.

### Solution

- Sign in again if token expired.
- Confirm valid email format.
- Verify backend endpoint `PUT /auth/profile` is reachable.
- Retry after reconnecting backend.

## 6. API request fails with a non-2xx response

### Where it happens

- `lib/services/api_service.dart`

### What it looks like

- The app throws an exception such as `Load products failed (500): ...`.
- The UI may show the error in a `FutureBuilder` or a snackbar.

### Why it happens

- The backend returned an error.
- The request data is invalid.
- The database rejected the update.

### Solution

- Read the response message shown by `_ensureSuccess()`.
- Check the backend logs.
- Validate the form inputs.
- Verify that the database rows exist when editing or deleting.

## 7. Product not found

### Where it happens

- Product edit, delete, stock in, and stock out actions.

### What you see

- `Product not found`

### Why it happens

- The selected product ID does not exist anymore.
- The backend data changed after the page loaded.

### Solution

- Refresh the page.
- Recreate the product if it was deleted.
- Make sure the product dropdown or list item is current.

## 8. Not enough stock for stock out

### Where it happens

- `POST /stock_out`

### What you see

- `Not enough stock for this stock-out operation`

### Why it happens

- The requested stock out quantity is larger than the available quantity.

### Solution

- Enter a smaller quantity.
- Check the product quantity before submitting.

## 9. Form validation errors

### Where it happens

- Product form
- Supplier form
- Stock in/out form

### What you see

- Messages like `Please enter a product name` or `Enter a quantity greater than zero`.

### Why it happens

- A required field is empty.
- A numeric field contains invalid text.

### Solution

- Fill every required field.
- Use numbers only in quantity and price inputs.
- Pick a product from the dropdown before submitting stock changes.
- Use UGX values for product pricing fields.

## 10. Delete action fails

### Where it happens

- Product delete
- Supplier delete

### What you see

- `Delete product failed (...)`
- `Delete supplier failed (...)`

### Why it happens

- The item no longer exists.
- The backend returned an error.
- A foreign key or database rule blocked the delete.

### Solution

- Refresh the list.
- Check whether the item has already been removed.
- Review the backend error message.

## 11. Blank or empty state screens

### Where it happens

- Products
- Suppliers
- Transactions

### What you see

- A friendly empty card such as `No products found` or `No transactions found`.

### Why it happens

- The backend returned no records.
- Search or filters removed all visible items.

### Solution

- Clear the search box.
- Reset date or type filters.
- Add sample data.
- Pull to refresh.

## 12. Route or navigation issue

### Where it happens

- `lib/routes.dart`
- `lib/widgets/app_drawer.dart`

### What you see

- A page does not open from the drawer or action buttons.
- On settings, user cannot return to prior screen.

### Why it happens

- The route constant is wrong.
- The destination screen is not registered in `AppRoutes`.

### Solution

- Check the route name in `routes.dart`.
- Make sure the screen is included in `onGenerateRoute()`.
- Keep the drawer route names in sync with the route table.
- Confirm settings screen includes `drawer: AppDrawer(...)`.
- Confirm app bar uses back action when `Navigator.canPop` is true.

## 13. Android emulator cannot reach backend

### Where it happens

- `lib/services/api_service.dart`

### What you see

- The app keeps showing the offline gate on Android emulator.

### Why it happens

- Android emulator cannot use `127.0.0.1` to reach the host machine.

### Solution

- Use `http://10.0.2.2:8000` for Android emulator.
- Keep `http://127.0.0.1:8000` for desktop, web, and iOS simulator in local development.

## 14. UI changes not visible in launched app

### Where it happens

- During active Flutter run sessions.

### What you see

- Source code has changed, but launched app still shows old UI.

### Why it happens

- Change is in a different screen than the route being viewed.
- Hot reload did not apply due to stale debug session.
- Multiple app processes are running and user is viewing an older window.

### Solution

- Verify route points to expected screen file.
- Use hot restart, and if needed launch a fresh run.
- Close old app windows and keep only newest process.

## 15. Safe debugging steps

When the app fails, use this order:

1. Check whether the backend is running.
2. Check whether the account exists or needs to be registered.
3. Read the snackbar or error message.
4. Check the `/health/db` endpoint.
5. Refresh the page.
6. Review the backend logs.
7. Verify the input values.
8. Retry the action.
