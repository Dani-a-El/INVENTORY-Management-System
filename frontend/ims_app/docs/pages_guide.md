# Pages Guide

This guide describes each visible page in the IMS Flutter app and explains user interactions, data dependencies, and expected outcomes.

## 0. Splash Screen

File: `lib/screens/splash_screen.dart`

What it shows:

- App logo and name
- Loading indicator
- Short tagline

What it does:

- Initializes the local auth session.
- Waits briefly so the splash feels intentional.
- Routes to login if no account is signed in.
- Routes to the dashboard if a session already exists.
- Avoids navigation race conditions by checking mounted state before routing.

## 1. Login Screen

File: `lib/screens/login_screen.dart`

What it shows:

- Email field
- Password field
- Password visibility toggle
- Remember-me checkbox
- Login button
- Register button
- Forgot password link

What it does:

- Validates the form.
- Signs the user into the backend-backed auth session.
- Sends the user to the dashboard on success.
- Shows an error message if login fails.
- Stores token persistence preference from remember-me.
- Opens the forgot-password screen for account recovery.

## 2. Register Screen

File: `lib/screens/register_screen.dart`

What it shows:

- Full name field
- Email field
- Password field
- Confirm password field
- Register button

What it does:

- Validates all fields.
- Checks that the password and confirmation match.
- Saves the account through the FastAPI auth endpoint.
- Sends the user back to login after a successful registration.

## 3. Forgot Password Screen

File: `lib/screens/forgot_password_screen.dart`

What it shows:

- Email field
- Send reset code button
- Reset code field
- New password and confirm password fields

What it does:

- Requests a reset code from the backend.
- Shows the reset code in the UI for this demo setup.
- Sends the new password and reset code to the backend.
- Returns the user to login after a successful reset.

## 4. Dashboard

File: `lib/screens/dashboard.dart`

What it shows:

- Total products
- Total stock
- Low stock alerts
- Total suppliers
- Quick action buttons
- A simple animated stock chart

What it does:

- Loads dashboard data from the backend.
- Refreshes when the user pulls down.
- Opens product, stock, and supplier screens from the quick actions.
- Shows a warning banner when the database health check is not OK.

## 5. Product List

File: `lib/screens/product_list.dart`

What it shows:

- Product name
- SKU
- Category
- Quantity
- Price in UGX
- Low stock badge when quantity is small

What it does:

- Loads products from the backend.
- Supports search filtering.
- Supports swipe actions for edit and delete.
- Uses a floating action button to open the product form.
- Uses a confirmation dialog before deleting a product.
- Shows currency consistently as UGX in product cards.

## 6. Product Form

File: `lib/screens/product_list.dart`

What it does:

- Adds a new product.
- Edits an existing product.
- Validates the form fields.
- Sends data to the backend with loading feedback.
- Uses explicit UGX labeling for the price field.

## 7. Stock In / Stock Out

File: `lib/screens/stock_in_out.dart`

What it shows:

- Product dropdown
- Quantity field
- Optional notes field
- Stock In and Stock Out toggle buttons

What it does:

- Lets the user choose a product.
- Validates quantity before submission.
- Shows a confirmation dialog before sending the stock change.
- Displays a success dialog after the backend accepts the request.

## 8. Supplier List

File: `lib/screens/supplier_list.dart`

What it shows:

- Supplier name
- Contact number
- Email
- Search field

What it does:

- Loads suppliers from the backend.
- Filters suppliers using the search box.
- Opens the supplier form for add and edit.
- Confirms delete actions before removing a supplier.

## 9. Supplier Form

File: `lib/screens/supplier_list.dart`

What it does:

- Adds a supplier.
- Edits a supplier.
- Validates the fields.
- Returns to the list after saving.

## 10. Transaction History

File: `lib/screens/transaction_history.dart`

What it shows:

- Product name
- Transaction type
- Quantity
- Timestamp
- Green badge for stock in
- Orange/red badge for stock out

What it does:

- Loads transactions from the backend.
- Supports search by product name, type, or time text.
- Filters by stock in, stock out, or date.
- Uses pull-to-refresh to reload the list.

## 11. Startup Gate

File: `lib/screens/startup_gate.dart`

What it does:

- Checks whether the database is online.
- Shows a friendly offline screen if the backend is not reachable.
- Lets the user retry the connection.
- Opens the dashboard when the backend is healthy.
- Redirects unauthenticated users to login before app content is shown.

## 12. Drawer Navigation

File: `lib/widgets/app_drawer.dart`

What it shows:

- Profile header with avatar
- Name and email
- Navigation items for Dashboard, Products, Stock, Suppliers, Transactions, Settings, and Logout

What it does:

- Highlights the current page.
- Uses animated selection styling.
- Navigates with a smooth page replacement.
- Logs the user out and returns to the login screen.

## 13. Settings Screen

File: `lib/screens/settings_screen.dart`

What it shows:

- Current user card
- Editable profile fields: display name and email
- Save profile action with loading state
- Dark mode switch
- Remember-me switch
- Forgot-password shortcut

What it does:

- Lets the user update profile data through the backend profile endpoint.
- Lets the user change the app theme.
- Lets the user change the remember-me preference.
- Opens password reset tools.
- Supports drawer access for global navigation.
- Shows a back button when there is a previous route in stack.
