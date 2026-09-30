# Android Billing Software

A Flutter based billing and order management app built for small food stalls and similar retail setups. Handles the full order lifecycle, from placing and editing orders to serving, printing receipts, and viewing business reports.

---

## Features

### Orders

- Place new orders with customer name and itemised menu selection
- Edit pending orders before they're served
- Mark orders as Served or Cancelled with confirmation dialogs
- Search pending orders by customer name or order number
- View full order details in a bottom sheet with itemised breakdown
- Print receipts directly to a Bluetooth thermal printer (58mm)
- Reprint receipts anytime from Served or Cancelled tabs
- Summary header showing live count of Pending, Served, and Cancelled orders

### Menu Management

- Organised into two tabs, Categories and Items
- Add, edit, and delete categories
- Add, edit, and delete menu items with name, price, and category
- Items grouped by category in the Items tab
- Deleting a category moves its items to Uncategorized automatically

### Reports

- Filter by Today, Week, Month, or All Time
- Revenue, order count, average order value, and cancellation count
- Top 5 best selling items
- Category leaders, the top item per category
- Business patterns, including peak day, slowest day, and peak hour
- Weekday demand pattern, showing the favourite item per day of the week
- Worst performing items
- Danger zone, with the option to reset all business data behind double confirmation

### Bluetooth Printing

- Connects to any ESC/POS 58mm thermal Bluetooth printer
- Printer is saved after first selection, so there is no need to re-select every time
- Receipt includes shop name, date and time, order number, customer name, itemised list, and total
- "Change Printer" option available from the success snackbar
- If printing fails, the saved printer is cleared and the picker reopens next time

---

## Tech Stack

- **Flutter** (Dart)
- **SQLite** via `sqflite` for local data storage
- **shared_preferences** for saving printer address
- **flutter_bluetooth_printer** for ESC/POS Bluetooth printing
- Material 3 design with a custom brown colour palette

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, theme, preloads menu data
├── data/
│   ├── app_data.dart          # In-memory store for categories and menu items
│   └── database_helper.dart   # SQLite helper, all DB operations
└── screens/
    ├── orders_screen.dart     # Orders list, tabs, print, serve/cancel flow
    ├── billing_screen.dart    # New order and edit order screen
    ├── menu_screen.dart       # Category and item management
    └── reports_screen.dart    # Business analytics and reports
```

---

## Getting Started

### Prerequisites

- Flutter SDK
- Android device or emulator (Android 6.0+)
- A 58mm Bluetooth thermal printer (ESC/POS compatible)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Arunan-Kavirajan/Android-Billing-Software.git
   cd Android-Billing-Software
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Build Release APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## Android Permissions

The following permissions are required in `AndroidManifest.xml` for Bluetooth printing:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```
