# 🟢 Suku — MVP Bookkeeping for SMEs

**A simple bookkeeping app for small businesses and personal accounts in East Africa.**
Built with Flutter, local persistence, and a clean theme that stays close to the original Suku flow.

---

## What this app does

Suku gives users a minimal, functional bookkeeping experience with:

- Dashboard-style financial overview for income, expenses, and transaction history
- Transaction scanning / receipt capture flow
- Monthly report generation with PDF export and share support
- Business / personal profile setup with account type toggle
- Subscription plan selection for Free, Pro, and Business tiers
- Language toggle between English and Kiswahili for UI copy
- M-Pesa settings screen, notification preferences, and help/support links

This MVP is designed to preserve the app's current brand, visual flow, and layout while adding functional settings and profile persistence.

---

## Key features

- **Business & Personal account mode**
  - Users can choose either a business profile or a personal profile
  - Business flow stores business name, location, and category
  - Personal flow stores full name, location, and occupation
- **Language support**
  - App text switches between English and Kiswahili
  - Language selection persists across sessions
  - Confirmation popups appear after changing language or plan
- **Subscription plan selector**
  - Free, Pro, and Business plan cards
  - Monthly pricing shown clearly in the UI
  - Local plan persistence with selection feedback popup
- **Reports**
  - Monthly summary and profit/loss view
  - PDF generation and share action
- **Settings hub**
  - Business info, M-Pesa connections, notification preferences, language, and support
  - Consistent theme, button styles, and navigation flow

---

## Project structure

```
suku/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── supabase_config.dart
│   ├── models/
│   │   └── models.dart
│   ├── screens/
│   │   ├── add_transaction_screen.dart
│   │   ├── business_info_screen.dart
│   │   ├── help_support_screen.dart
│   │   ├── home_screen.dart
│   │   ├── language_screen.dart
│   │   ├── login_screen.dart
│   │   ├── mpesa_settings_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── otp_screen.dart
│   │   ├── pin_lock_screen.dart
│   │   ├── reports_screen.dart
│   │   ├── scan_screen.dart
│   │   └── splash_screen.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── language_service.dart
│   │   ├── pdf_service.dart
│   │   ├── sms_service.dart
│   │   ├── transaction_service.dart
│   │   └── pin_service.dart
│   ├── theme/
│   │   └── suku_theme.dart
│   └── widgets/
│       ├── keypad.dart
│       └── shared_widgets.dart
├── assets/
│   └── images/
├── android/
├── ios/
└── pubspec.yaml
```

---

## Setup & run

### 1. Install Flutter and dependencies

```bash
flutter --version
cd e:/projects/flutter/suku
flutter pub get
```

### 2. Run the app

```bash
flutter run
```

### 3. Run on Android

```bash
flutter run -d android
```

---

## Screens and experience

### Home / Dashboard

- Balance summary, recent transactions, and account overview
- Settings tab with easy navigation to subscription, profile, language, and support

### Business Info

- Toggle between Business and Personal account mode
- Save profile fields locally and use them across the app
- Keeps the original theme and layout intact

### Language selection

- Toggle English / Kiswahili
- App copy updates where language service text is used
- Popup confirms language switch

### Subscription plans

- Free / Pro / Business options
- Monthly prices are shown clearly for each plan
- Toast or dialog appears when a plan is selected

### Reports

- Monthly financial summary
- Shareable PDF export
- Net profit / expense breakdown and tax estimate card

---

## Notes for MVP

- The app uses local persistence for settings, language, and subscription state
- Supabase is initialized for backend auth/data support, but current screens focus on local flow
- Theme and navigation were kept consistent with the original app style
- New language and profile options were added without changing the app's visual identity

---

## Next improvements

- Connect live Supabase auth and profile sync
- Hook actual receipt scanning to an OCR/AI backend
- Add offline transactions storage and sync
- Implement real M-Pesa payment integration
- Add unit tests for services and screen flows

---

## Why Suku?

Suku is built to help East African micro-businesses track cash flow, save receipts, and make quick financial decisions with a clean mobile experience.

**Biashara kwa urahisi. Hesabu kwa haraka.**
