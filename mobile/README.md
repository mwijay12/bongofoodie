# 📱 Bongo Foodie — Flutter Mobile App (`mobile/`)

Flagship cross-platform **Flutter** client (Android, iOS & Web) for **Bongo Foodie**, built with Clean Feature-First Architecture, **Riverpod**, **GoRouter**, and **Supabase Realtime**.

## ✨ Key Highlights

- **Dual-Mode Resilience (Live Supabase + Instant Showcase Mode):** Works out-of-the-box for portfolio reviewers even with zero `.env` configuration, and switches seamlessly to live Supabase Auth, PostgreSQL, Storage & Realtime when `--dart-define` credentials are provided.
- **Bilingual Experience (`EN` / `SW`):** Instant toggle between **English** and **Kiswahili** across navigation, greetings, and actions.
- **Chef AI Atelier:** Conversational Swahili gastronomy advisor + Custom Dish Dream Kitchen with dynamic nutritional macros and photography—backed by Supabase Edge Functions / Next.js API routes so zero AI keys are exposed in the APK.
- **Delivery address entry:** Deliberate region/district/ward selection from a partial reviewed Dar reference in demo, or the configured live catalog; manual entry is always available. Optional foreground device location requires an explicit tap and does not establish ward or delivery coverage. No claim of complete national geography. See `docs/polish-series/10-dar-location.md`.
- **Built-In Staff & Admin Console:** Test real-time 4-step order status transitions (*Placed ➔ Kitchen ➔ Delivery ➔ Arrived*) directly inside the app!

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
cd mobile
.\scripts\bootstrap.ps1
flutter run
```

### macOS / Linux
```bash
cd mobile
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
flutter run
```

### Connecting Your Live Supabase Project
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=WEB_API_BASE_URL=https://your-bongofoodie.vercel.app
```

## Native location configuration

Bootstrap requires Python 3 as well as Flutter. After manually regenerating native
runners with `flutter create`, run `python3 scripts/apply_branding.py` (Windows:
`python scripts/apply_branding.py`) before building. This reapplies approved
branding and foreground-only location permission configuration. CI does this too.
Do not add background location permission. Physical-device permission and iOS
release validation are still required; a successful Android/web build is not
runtime GPS/serviceability verification.
