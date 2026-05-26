# Tech Stack

## Framework & Language
- **Flutter** (Dart, SDK ^3.11.5) — primary target is **web (Chrome)**
- **Material 3** (`useMaterial3: true`)

## State Management
- **Provider** (`^6.1.2`) — single `AppProvider` (ChangeNotifier) holds all app state
- All data lists, auth state, dark mode, and Chronos settings live in `AppProvider`

## Backend
- **Supabase** (`supabase_flutter ^2.12.4`) — auth + database
- Credentials loaded from `.env` via `flutter_dotenv` (`^6.0.1`)
- `.env` is declared as a Flutter asset in `pubspec.yaml`

## Key Libraries

| Package | Version | Purpose |
|---|---|---|
| `google_fonts` | ^6.2.1 | Inter font family |
| `lucide_icons_flutter` | ^1.1.0 | All icons (use `LucideIcons.*`) |
| `intl` | ^0.19.0 | Date/number formatting |
| `excel` | 2.1.0 | Excel import/export |
| `pdf` | ^3.11.3 | PDF export |
| `file_saver` | ^0.2.14 | Save files to browser/disk |
| `file_picker` | ^8.1.7 | Pick files for import |
| `provider` | ^6.1.2 | State management |
| `flutter_dotenv` | ^6.0.1 | Environment variables |
| `supabase_flutter` | ^2.12.4 | Backend/auth |

## Linting
- `flutter_lints ^6.0.0` with default rules (`package:flutter_lints/flutter.yaml`)
- Run: `flutter analyze`

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run on Chrome (primary target)
flutter run -d chrome

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for web
flutter build web
```

## Environment Setup
Copy `.env.example` to `.env` and fill in Supabase credentials:
```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```
