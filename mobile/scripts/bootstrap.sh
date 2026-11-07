#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "🍲 Bongo Foodie Flutter Setup"

if [ ! -d "android" ] || [ ! -d "ios" ]; then
  echo "📦 Generating Flutter native runners (android, ios, web)..."
  flutter create --platforms=android,ios,web --org tz.co.bongofoodie --project-name bongo_foodie .
fi

echo "📥 Fetching pub dependencies..."
flutter pub get

echo "🧪 Running unit tests..."
flutter test

echo "✅ Ready! Launch with: flutter run"
