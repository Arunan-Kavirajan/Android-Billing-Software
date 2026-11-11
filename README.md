<div align="center">

# D Brownies Billing App

**Billing and order management for small food stalls.**

*A Flutter app that handles the full order lifecycle, from placing orders to printing receipts on a Bluetooth thermal printer and tracking business performance.*

<br />

<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
<img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
<img src="https://img.shields.io/badge/Material_3-757575?style=for-the-badge&logo=materialdesign&logoColor=white" alt="Material 3" />
<br />
<br />
<img src="https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge" alt="License: MIT" />
<img src="https://img.shields.io/badge/PRs-Welcome-brightgreen.svg?style=for-the-badge" alt="PRs Welcome" />

</div>

<br />

## Introduction

D Brownies Billing App replaces pen-and-paper order books for small food stalls and similar retail setups. Take an order, edit it while it is pending, mark it served or cancelled, print a receipt, and review how the business is doing, all offline on a single Android device.

<br />

## Features

*   **Order management**: Place orders with a customer name and itemised menu selection, edit pending orders, and mark them Served or Cancelled with confirmation dialogs.
*   **Search and overview**: Search pending orders by customer name or order number, with a live count of Pending, Served, and Cancelled orders.
*   **Order details**: Open any order in a bottom sheet with a full itemised breakdown.
*   **Menu management**: Add, edit, and delete categories and items. Deleting a category moves its items to Uncategorized automatically.
*   **Bluetooth printing**: Print receipts to any ESC/POS 58mm thermal printer, and reprint from the Served or Cancelled tabs at any time.
*   **Remembered printer**: The printer is saved after first selection. If printing fails, the saved printer is cleared and the picker reopens next time.
*   **Business reports**: Filter by Today, Week, Month, or All Time to see revenue, order count, average order value, and cancellations.
*   **Sales insights**: Top 5 best sellers, category leaders, worst performing items, peak and slowest days, peak hour, and the favourite item per weekday.
*   **Offline first**: All data is stored locally in SQLite, with no account or internet connection required.
*   **Danger zone**: Reset all business data, protected by double confirmation.

<br />

## Tech Stack

### App
*   **Flutter (Dart)**: Cross-platform UI framework
*   **Material 3**: Design system with a custom brown colour palette

### Data
*   **sqflite**: Local SQLite storage for orders, categories, and menu items
*   **shared_preferences**: Persists the selected printer address

### Hardware
*   **print_bluetooth_thermal**: ESC/POS Bluetooth thermal printing

<br />

## Project Structure

```text
d_brownie_billing_app/
├── lib/
│   ├── main.dart                  # App entry point, theme, preloads menu data
│   ├── data/
│   │   ├── app_data.dart          # In-memory store for categories and menu items
│   │   └── database_helper.dart   # SQLite helper, all DB operations
│   └── screens/
│       ├── orders_screen.dart     # Orders list, tabs, print, serve/cancel flow
│       ├── billing_screen.dart    # New order and edit order screen
│       ├── menu_screen.dart       # Category and item management
│       └── reports_screen.dart    # Business analytics and reports
├── assets/                        # App logo
└── android/                       # Android platform project
```

<br />

## How It Works

```text
Place Order
     │  Pick items from the menu, enter customer name
     ▼
Pending
     │  Editable, searchable, printable
     ▼
Served or Cancelled
     │  Confirmed via dialog, receipt can be reprinted
     ▼
Reports
     │  SQLite queries aggregate revenue, best sellers,
     │  peak days and hours for the chosen time range
```

> **Note:** Receipts include the shop name, date and time, order number, customer name, itemised list, and total.

<br />

## Getting Started

### Prerequisites
*   Flutter SDK
*   Android device or emulator (Android 6.0+)
*   A 58mm Bluetooth thermal printer (ESC/POS compatible) for printing

### Installation

```bash
git clone https://github.com/Arunan-Kavirajan/D-Brownies-Billing-App.git
cd D-Brownies-Billing-App
flutter pub get
```

### Run the App

```bash
flutter run
```

### Build Release APK

```bash
flutter build apk --release
```

*Output: `build/app/outputs/flutter-apk/app-release.apk`*

<br />

## Android Permissions

Bluetooth printing requires these permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

<br />

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

