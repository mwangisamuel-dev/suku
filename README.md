# 🟢 Suku — Your Pocket Accountant

**SME Bookkeeping App for East Africa**  
Built with Flutter · Powered by Claude AI · Designed for Nairobi

---

## Project Structure

```
suku/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── theme/
│   │   └── suku_theme.dart          # Brand colors, typography, component themes
│   ├── models/
│   │   └── models.dart              # Transaction, Category, SampleData
│   ├── widgets/
│   │   └── shared_widgets.dart      # Reusable UI components
│   └── screens/
│       ├── splash_screen.dart       # Animated launch screen
│       ├── onboarding_screen.dart   # 3-slide intro (English + Swahili)
│       ├── home_screen.dart         # Dashboard + all tabs
│       └── scan_screen.dart         # Camera UI + AI receipt scanner
├── assets/
│   └── images/
│       ├── icon.png                 # App icon (sukufavicon.png)
│       └── logo.png                 # Full logo (sukunobglogo.png)
└── pubspec.yaml
```

---

## 🚀 Setup & Run

### 1. Prerequisites
```bash
flutter --version   # Needs Flutter 3.x+
```

### 2. Install dependencies
```bash
cd suku
flutter pub get
```

### 3. Generate launcher icons (custom Suku icon)
```bash
flutter pub run flutter_launcher_icons
```
This replaces the default Flutter icon on your phone with the Suku icon.  
✅ Both Android (adaptive) and iOS icons are generated automatically.

### 4. Run the app
```bash
flutter run                    # Default device
flutter run -d android         # Android
flutter run -d ios             # iOS (Mac only)
```

---

## 🎨 Brand System

| Token | Value | Usage |
|-------|-------|-------|
| `SukuColors.green` | `#00A859` | Primary actions, income, success |
| `SukuColors.navy` | `#102A43` | Background, cards, headers |
| `SukuColors.orange` | `#FF6B35` | FAB, scan CTA, accent |
| Font | Plus Jakarta Sans | All text |

---

## 📱 Screens

1. **Splash** — Animated logo reveal with navy background + green glow
2. **Onboarding** — 3 slides with English copy + Swahili/Sheng tag  
3. **Dashboard** — Balance card, weekly chart, category breakdown, recent transactions
4. **Transactions** — Full list with filter chips (Yote / Money In / Money Out)
5. **Scanner** — Camera viewfinder with corner accents, AI scan animation, results sheet
6. **Reports** — KRA PDF generator + monthly summary
7. **Profile/Settings** — Business info, subscription, M-Pesa config

---

## 🤖 Integrating Claude API (Receipt Scanning)

In `scan_screen.dart`, replace the `_simulateScan()` function:

```dart
Future<void> _scanWithClaude(File imageFile) async {
  setState(() => _state = ScanState.scanning);
  
  final bytes = await imageFile.readAsBytes();
  final base64Image = base64Encode(bytes);

  final response = await http.post(
    Uri.parse('https://api.anthropic.com/v1/messages'),
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': 'YOUR_API_KEY',
      'anthropic-version': '2023-06-01',
    },
    body: jsonEncode({
      'model': 'claude-opus-4-6',
      'max_tokens': 1024,
      'messages': [{
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/jpeg',
              'data': base64Image,
            },
          },
          {
            'type': 'text',
            'text': '''Extract from this receipt:
            Return ONLY valid JSON: 
            {"vendor":"","amount":0,"date":"","items":[],"category":"stock|rent|salary|transport|utilities|other"}
            No preamble. No markdown. JSON only.''',
          },
        ],
      }],
    }),
  );

  final data = jsonDecode(response.body);
  final text = data['content'][0]['text'];
  final extracted = jsonDecode(text);
  
  // Update state with extracted data
  setState(() {
    _state = ScanState.result;
    // populate _extracted map from extracted
  });
}
```

---

## 💳 M-Pesa SMS Parser

Parse Safaricom SMS messages automatically:

```dart
Map<String, dynamic>? parseMpesaSms(String sms) {
  // Pattern: "TXN confirmed. Ksh1,200 sent to NAIVAS on 3/6/26..."
  final amountRegex = RegExp(r'Ksh([\d,]+)');
  final vendorRegex = RegExp(r'sent to ([A-Z\s]+) on');
  final dateRegex = RegExp(r'on (\d+/\d+/\d+)');
  
  final amount = amountRegex.firstMatch(sms)?.group(1)?.replaceAll(',', '');
  final vendor = vendorRegex.firstMatch(sms)?.group(1)?.trim();
  final date = dateRegex.firstMatch(sms)?.group(1);
  
  if (amount == null) return null;
  return {
    'amount': double.parse(amount),
    'vendor': vendor ?? 'M-Pesa Payment',
    'date': date,
    'isMpesa': true,
  };
}
```

---

## 📦 Next Steps

- [ ] Connect Supabase (auth + database)
- [ ] Wire Claude API vision for real receipt scanning
- [ ] Implement M-Pesa Daraja STK Push for subscriptions
- [ ] Add PDF report generation with `pdf` package
- [ ] Offline-first with SQLite (`sqflite`)
- [ ] Push notifications for daily summary

---

**Biashara safi. Hesabu bila stress.** 🇰🇪
