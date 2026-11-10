# Bongo Foodie Flutter Bootstrap Script (Windows PowerShell)
# Generates native Android/iOS/Web runners if not yet initialized, installs packages, and launches the app!

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "🍲 Bongo Foodie Flutter Setup (Windows)" -ForegroundColor Yellow

if (-not (Test-Path ".\android") -or -not (Test-Path ".\ios")) {
    Write-Host "📦 Generating Flutter native runners (android, ios, web)..." -ForegroundColor Cyan
    flutter create --platforms=android,ios,web --org tz.co.bongofoodie --project-name bongo_foodie .
}

# Foreground-only location permissions and approved branding survive regeneration.
python scripts/apply_branding.py
if ($LASTEXITCODE -ne 0) { throw "Native configuration failed" }

Write-Host "📥 Fetching pub dependencies..." -ForegroundColor Cyan
flutter pub get

Write-Host "🧪 Running unit tests..." -ForegroundColor Cyan
flutter test

Write-Host "✅ Ready! Run the app with:" -ForegroundColor Green
Write-Host "   flutter run" -ForegroundColor White
Write-Host "Or connect live Supabase with:" -ForegroundColor Green
Write-Host "   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ..." -ForegroundColor White
