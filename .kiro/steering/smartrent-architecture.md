# SmartRent — Architecture & Coding Standards

This document is the single source of truth for the SmartRent Flutter project structure, conventions, and rules. **Read this before making any change to the codebase.** No new files, folders, widgets, or patterns should be introduced without checking this document first.

---

## Project Overview

SmartRent is a Flutter gown rental management app backed by Firebase (Firestore + Auth) and Cloudinary for image storage. It has two user roles:

- **Admin** — manages inventory, customers, rentals, reports
- **Client** — browses gowns, rents, manages their account

The app targets Android (primary) and iOS.

---

## Folder Structure

```
lib/
├── controllers/              # Business logic controllers and sign-in handlers
│   ├── login_controller.dart
│   ├── signup_controller.dart
│   ├── splash_controller.dart
│   ├── google_sign_in_handler.dart
│   └── facebook_sign_in_handler.dart
│
├── core/
│   ├── constants/
│   │   └── app_colors.dart   # ALL colors — never use raw Color() or Colors.X outside here
│   ├── models/
│   │   ├── gown_model.dart
│   │   ├── category_model.dart
│   │   └── rental_model.dart
│   ├── utils/
│   │   ├── guest_preferences.dart # Persists guest session across app restarts
│   │   ├── logout_helper.dart    # Shared logout flow (confirm → loading → signOut → landing)
│   │   └── price_formatter.dart  # PriceFormatter.format(double) → '5,000'
│   └── widgets/                  # Shared reusable widgets used across the whole app
│       ├── action_card.dart
│       ├── analytics_card.dart
│       ├── app_footer.dart
│       ├── field_label.dart      # Small uppercase label above form fields
│       ├── gown_card.dart        # Universal gown card (2-col grid, BoxFit.contain image)
│       ├── gown_form_field.dart  # TextFormField for admin gown forms (optional prefix icon)
│       ├── input_field.dart      # TextFormField for auth screens (required prefix icon)
│       ├── social_icon_button.dart
│       └── stat_summary_card.dart
│
├── repositories/
│   └── auth_repository.dart  # All Firebase Auth + Firestore auth operations
│
├── screens/
│   ├── admin/
│   │   ├── customers/
│   │   │   ├── customer_list_screen.dart   # Unique customers from rentals, paginated, searchable
│   │   │   └── customer_history_screen.dart # Per-customer approved/completed rental history
│   │   └── gowns/
│   │       ├── add_gown_screen.dart
│   │       ├── edit_gown_screen.dart
│   │       ├── gown_detail_screen.dart
│   │       └── inventory_screen.dart
│   ├── auth/
│   │   ├── forgot_password_screen.dart
│   │   ├── landing_page.dart
│   │   ├── loading_screen.dart
│   │   ├── signin_screen.dart
│   │   └── signup_screen.dart
│   ├── client/
│   │   ├── gown_detail_screen.dart     # Customer gown detail — image carousel, rent button
│   │   ├── rental_request_screen.dart  # Rental request form — submit to Firestore
│   │   └── request_details_screen.dart # View/modify/cancel a pending rental request
│   ├── home/
│   │   ├── admin_tabs/
│   │   │   ├── admin_profile_tab.dart  # Admin profile + logout
│   │   │   ├── dashboard_tab.dart      # Main admin dashboard
│   │   │   ├── inbox_tab.dart          # Stub
│   │   │   ├── reports_tab.dart        # Stub
│   │   │   └── scanner_tab.dart        # Stub
│   │   ├── client_tabs/
│   │   │   ├── home_tab.dart           # Real HomeTab — loads from Firestore
│   │   │   ├── notifications_tab.dart  # Stub
│   │   │   ├── profile_tab.dart        # Client profile + logout (guest + logged-in states)
│   │   │   └── transactions_tab.dart   # Stub
│   │   ├── admin_home.dart
│   │   └── client_home.dart
│   └── splash/
│       ├── splash_animations.dart
│       └── splash_screen.dart
│
├── services/
│   ├── category_service.dart
│   ├── cloudinary_service.dart
│   ├── customer_service.dart
│   ├── gown_service.dart
│   ├── notification_service.dart
│   ├── rental_service.dart
│   ├── stats_service.dart
│   └── user_service.dart
│
├── firebase_options.dart
└── main.dart
```

### Rules
- **Controllers** live in `lib/controllers/` — never inside `lib/screens/`
- **Shared widgets** live in `lib/core/widgets/` — never scoped to a single screen folder
- **Utilities** live in `lib/core/utils/`
- **Screen-private widgets** (prefixed `_`) are allowed inside a screen file but only if they are used exclusively by that screen and are too small to warrant a separate file
- Do **not** create a `widgets/` subfolder inside any screen folder — that pattern was removed

---

## Color System — `AppColors`

**Every color in the app must come from `AppColors`.** Never use raw `Color(0xFF...)`, `Colors.white`, `Colors.red`, `Colors.grey`, etc. directly in widget code.

### Full token reference

```dart
// Brand
AppColors.primary           // Color(0xFFC79F1D) — gold

// Text
AppColors.textDark          // Color(0xFF2C2C2C)
AppColors.textMid           // Color(0xFF666666)
AppColors.textLight         // Color(0xFF999999)

// Input
AppColors.inputHint         // Color(0xFFBBBBBB)

// Borders
AppColors.border            // Color(0xFFE0E0E0)

// Backgrounds
AppColors.background        // Colors.white — default scaffold/card background
AppColors.surfaceGrey       // Color(0xFFF5F5F5) — search bars, placeholders, stat cards
AppColors.surfaceMidGrey    // Color(0xFFF0F0F0) — admin badge chip
AppColors.surfaceCream      // Color(0xFFF9F6EC) — measurement grid cells

// Foreground on coloured surfaces
AppColors.defaultForeground // Colors.white — text/icons on primary or dark backgrounds

// Semantic
AppColors.error             // Colors.redAccent — errors, delete actions
AppColors.errorHighlight    // Colors.redAccent — alias, kept for compatibility

// Overlays / scrims
AppColors.overlayDark       // black @ 35% — back button circle on images
AppColors.overlayDarker     // black @ 45% — image counter badge, remove-image button
AppColors.overlayModal      // black @ 30% — full-screen loading overlay

// Gown status
AppColors.statusAvailable   // = primary (gold)
AppColors.statusRented      // Color(0xFF9E9E9E) — grey
AppColors.statusCleaning    // Color(0xFF2196F3) — blue
AppColors.statusRepair      // Color(0xFFF44336) — red
```

### Gown status helpers

Never write a `switch` on gown status strings in widget code. Use the centralized helpers:

```dart
AppColors.gownStatusColor('available') // → Color
AppColors.gownStatusLabel('rented')    // → 'RENTED'
```

### `withOpacity` is banned

Always use `.withValues(alpha: x)` instead:

```dart
// ✗ Wrong
color: AppColors.primary.withOpacity(0.6)

// ✓ Correct
color: AppColors.primary.withValues(alpha: 0.6)
```

---

## Shared Utilities

### `PriceFormatter`
```dart
import 'package:smart_rent/core/utils/price_formatter.dart';

PriceFormatter.format(5000.0) // → '5,000'
```
Use this everywhere a rental price is displayed. Never write a manual comma-formatting loop.

### `LogoutHelper`
```dart
import 'package:smart_rent/core/utils/logout_helper.dart';

await LogoutHelper.logout(context);
```
Handles: confirm dialog → loading screen → `FirebaseAuth.signOut()` → `GuestPreferences.clear()` → navigate to `LandingPage`. Use this in every profile tab. Never duplicate this flow.

### `GuestPreferences`
```dart
import 'package:smart_rent/core/utils/guest_preferences.dart';

// When user taps "Continue as Guest":
await GuestPreferences.setGuestMode();

// On logout or successful sign-in (handled automatically by LogoutHelper
// and the sign-in handlers — do not call manually):
await GuestPreferences.clear();
```
Persists guest session using `shared_preferences`. Cleared on uninstall. Never call `setGuestMode()` outside of `LandingPage`'s "Continue as Guest" button.

---

## Shared Widgets

### `FieldLabel` — label above a form field
```dart
import 'package:smart_rent/core/widgets/field_label.dart';

const FieldLabel(label: 'EMAIL ADDRESS')
```

### `InputField` — auth screen text fields (required prefix icon)
```dart
import 'package:smart_rent/core/widgets/input_field.dart';

InputField(
  controller: _emailController,
  hint: 'example@gmail.com',
  prefixIcon: Icons.mail_outline,
  keyboardType: TextInputType.emailAddress,
  validator: _controller.validateEmail,
)
```

### `GownFormField` — admin gown form text fields (optional prefix icon)
```dart
import 'package:smart_rent/core/widgets/gown_form_field.dart';

GownFormField(
  controller: _nameController,
  hint: 'Enter gown name',
  prefixIcon: Icons.checkroom_outlined, // optional
  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
)
```

### `GownCard` — universal gown card for both admin and client grids
```dart
import 'package:smart_rent/core/widgets/gown_card.dart';

GownCard(
  gown: gown,
  onTap: () => Navigator.push(...),  // required — pass context-appropriate navigation
  showDetails: true,                  // shows category + color lines (admin only)
)
```
- Image uses `BoxFit.contain` — portrait photos are never cropped, letterboxed against `surfaceGrey`
- Status badge always visible
- Used in `inventory_screen.dart` (admin, `showDetails: true`) and `home_tab.dart` (client, `showDetails: false`)
- Never duplicate this card — always use this widget

### `SocialIconButton` — Google / Facebook sign-in icon buttons
```dart
import 'package:smart_rent/core/widgets/social_icon_button.dart';

SocialIconButton(
  icon: SvgPicture.asset('assets/icons/Google__G__logo.svg', height: 20, width: 20),
  onTap: () => handleGoogleSignIn(context),
)
```

---

## Data Layer

### Architecture pattern
```
Screen → Controller → Repository / Service → Firebase / Cloudinary
```

- **Screens** hold UI state only. They call controllers or services.
- **Controllers** (`lib/controllers/`) hold validation logic, error mapping, and coordinate between screens and repositories.
- **Repositories** (`lib/repositories/`) wrap Firebase SDK calls. They throw exceptions — they do not catch them.
- **Services** (`lib/services/`) are static utility classes for Firestore operations. They catch exceptions and return safe fallback values (`false`, `[]`, `0`, `null`), and log via `debugPrint`.

### Error handling in services

Every `catch` block in a service must log the error in debug mode:

```dart
} catch (e) {
  debugPrint('[ServiceName.methodName] $e');
  return false; // or [], 0, null as appropriate
}
```

Never use `catch (_)` — always name the error `e` and print it.

### Models

| Model | Key fields |
|---|---|
| `GownModel` | `id`, `code`, `name`, `category`, `color`, `measurements`, `rentalPrice`, `status`, `imageUrls`, `description`, `addedAt`, `isFavorite` |
| `CategoryModel` | `id`, `name`, `order` |

`GownModel.isFavorite` is client-side only — not stored in Firestore.

---

## Gown Status Values

The valid status strings stored in Firestore are:

| String | Meaning |
|---|---|
| `'available'` | Ready to rent |
| `'rented'` | Currently rented out |
| `'cleaning'` | Being cleaned |
| `'repair'` | Under repair |
| `'overdue'` | Rental overdue |

Always use these exact lowercase strings. Use `AppColors.gownStatusColor()` and `AppColors.gownStatusLabel()` to display them.

---

## Navigation

Navigation is imperative (`Navigator.push`, `pushReplacement`, `pushAndRemoveUntil`). No named routes. No router package.

### Auth flow
```
SplashScreen
  ├── LandingPage          (unauthenticated)
  │   ├── SigninScreen
  │   │   └── ForgotPasswordScreen
  │   └── SignupScreen
  ├── AdminHome            (role == 'admin')
  └── ClientHome           (role == 'client' or guest)
```

### Dev shortcut (debug only)
To skip login during development, set the override in `main.dart`:

```dart
// 1. Add import:
import 'package:smart_rent/controllers/splash_controller.dart';

// 2. Set override before runApp():
SplashController.debugOverride = SplashDestination.adminHome;
// SplashController.debugOverride = SplashDestination.clientHome;
// SplashController.debugOverride = SplashDestination.landing;
```

This is guarded by `kDebugMode` — it has zero effect in release builds. Comment it back out before committing.

---

## Assets

```
assets/
├── icons/    # App icons, logo, action card icons
└── images/   # General images (currently empty, folder exists)
```

Both folders are declared in `pubspec.yaml`. Do not add new asset folders without updating `pubspec.yaml`.

### Icon files
| File | Usage |
|---|---|
| `smart_rent_logo.jpg` | Splash screen, sign-in screen, loading screen |
| `smart_rent_logo.png` | Dashboard header |
| `app_logo.png` | Launcher icon |
| `Google__G__logo.svg` | Google sign-in button |
| `Facebook_Logo_Primary.png` | Facebook sign-in button |
| `profile.png` | Admin profile placeholder |
| `total_gowns.png`, `customer.png`, `overdue.png`, `cleaning.png`, `rented.png`, `add_gown.png` | Dashboard action cards |

---

## Firebase Collections

| Collection | Purpose |
|---|---|
| `users` | User profiles. Fields: `name`, `email`, `role` (`'admin'`/`'client'`), `createdAt`, `bookmarks` (array of gown IDs) |
| `users/{uid}/notifications` | In-app notifications per customer. Fields: `title`, `body`, `type` (`'approved'`/`'rejected'`/`'completed'`), `rentalId`, `gownName`, `isRead`, `createdAt`. Written by admin actions via `NotificationService`. |
| `gowns` | Gown inventory. Fields match `GownModel.toFirestore()` |
| `categories` | Gown categories. Fields: `name`, `order` |
| `rentals` | Rental requests. Fields: `gownId`, `gownName`, `gownCode`, `customerId`, `customerName`, `phone`, `pickupDate`, `returnDate`, `status` (`pending`/`approved`/`rejected`/`cancelled`/`completed`), `createdAt` |

---

## Dependencies (key packages)

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Firebase |
| `google_sign_in` | Google OAuth |
| `flutter_facebook_auth` | Facebook OAuth |
| `flutter_svg` | SVG rendering (Google logo) |
| `image_picker` | Gallery/camera access for gown images |
| `permission_handler` | Runtime permissions |
| `device_info_plus` | Android SDK version check for permissions |
| `http` | Cloudinary image upload |
| `shared_preferences` | Guest session persistence across app restarts |

Do not add new dependencies without discussion. Prefer packages already in use.

---

## Coding Conventions

### Imports
Always use full package imports, not relative imports, except within the same immediate folder:

```dart
// ✓ Correct — package import
import 'package:smart_rent/core/constants/app_colors.dart';

// ✓ Acceptable — relative import within same folder
import 'splash_animations.dart';

// ✗ Wrong — relative import crossing folder boundaries
import '../../core/constants/app_colors.dart';
```

### Widget structure
- `StatelessWidget` for pure display widgets
- `StatefulWidget` for anything with local state (loading, form, animation)
- Keep `build()` methods readable — extract private `_SomeWidget` classes within the same file if a subtree is complex and reused within that screen

### Form fields
- Auth screens → use `InputField` (from `core/widgets/`)
- Admin gown forms → use `GownFormField` (from `core/widgets/`)
- Multi-line text areas → use `TextFormField` directly with consistent border decoration matching `AppColors`

### Naming
| Thing | Convention | Example |
|---|---|---|
| Files | `snake_case` | `gown_detail_screen.dart` |
| Classes | `PascalCase` | `GownDetailScreen` |
| Private widgets in file | `_PascalCase` | `_GownCard` |
| Variables / methods | `camelCase` | `_isLoading`, `_handleLogin()` |
| Constants | `camelCase` | `_maxAttempts` |

### State management
Currently using `setState` throughout. This is acceptable for the current scale. Before adding any state management package (Provider, Riverpod, Bloc), document the decision here first.

---

## What Is Still a Stub (needs implementation)

These screens exist but show placeholder content. Do not remove the stubs — replace them with real implementations when the feature is ready:

| File | Stub content | Notes |
|---|---|---|
| `inbox_tab.dart` | `'Inbox'` text | ✅ Implemented — real-time rental requests + Active tab with Mark as Returned |
| `scanner_tab.dart` | `'Scanner'` text | Needs QR scanner |
| `reports_tab.dart` | `'Reports'` text | Needs analytics |
| `client_tabs.dart` → `TransactionsTab` | `'Transactions'` text | ✅ Implemented — My Rental Requests with 4 tabs (Current, Approved, Declined, Completed) |
| `client_tabs.dart` → `NotificationsTab` | `'Notifications'` text | ✅ Implemented — in-app notifications with unread badge |
| `home_tab.dart` → bookmark icon (top bar, logged in) | navigates nowhere | Needs bookmarks page |
| `dashboard_tab.dart` → Customer card | `TODO` | Navigate to customer list |
| `dashboard_tab.dart` → Overdue card | `TODO` | Navigate to overdue list |
| `dashboard_tab.dart` → Cleaning card | `TODO` | Navigate to cleaning list |
| `dashboard_tab.dart` → Rented card | `TODO` | Navigate to rented list |
| `analytics_card.dart` | Placeholder chart | Needs real chart widget |
| `home_tab.dart` → filter chips | UI only | Filter logic not wired |

---

## Cloudinary

Images are uploaded via unsigned preset (`smartrent_uploads`) to the `gowns/<code>/` folder. The `api_secret` is never stored client-side — deletion of Cloudinary images must be done manually from the Cloudinary dashboard.

The `optimizeUrl()` method in `cloudinary_service.dart` is commented out but available for future use when image optimization is needed.

---

## Change Log

| Date | Change |
|---|---|
| 2026-05-02 | Tier 1: Expanded `AppColors`, replaced all `withOpacity`, created `assets/images/` |
| 2026-05-02 | Tier 2: Moved widgets to `core/widgets/`, created `GownFormField`, `PriceFormatter`, `LogoutHelper`, deleted `screens/auth/widgets/` |
| 2026-05-02 | Tier 3: Fixed duplicate Resend Email button, removed unused imports, replaced dev shortcuts with `kDebugMode` guard, added `debugPrint` to all service catch blocks |
| 2026-05-02 | Tier 4: Moved `screens/controllers/` → `controllers/`, implemented real `home_tab.dart` |
| 2026-05-02 | Added guest session persistence via `shared_preferences` + `GuestPreferences` utility |
| 2026-05-16 | Rental lifecycle: added `completeRental()` to `RentalService`; `InboxTab` now has Pending + Active tabs with "Mark as Returned" (available or cleaning); `completed` status added to `RentalModel` and `AppColors` |
| 2026-05-16 | In-app notifications: added `NotificationService` + `users/{uid}/notifications` subcollection; approve/reject/complete all write notifications; `NotificationsTab` fully implemented with unread badge on client nav |
| 2026-05-16 | Customer list + history: `CustomerService`, `CustomerListScreen`, `CustomerHistoryScreen`; dashboard Customer card now navigates to list; dashboard "Ongoing" stat counts active (approved) rentals instead of registered users |
