#!/usr/bin/env bash
# Detect palette literals outside the design system; data hex strings are not
# included because remote promotional data remains part of the existing model.
set -euo pipefail
cd "$(dirname "$0")/.."
violations=$(grep -rnE 'Color\(0x|Colors\.(red|blue|green|orange|grey)' lib --exclude-dir=theme || true)
if [ -n "$violations" ]; then
  printf '%s\n' "$violations"
  exit 1
fi
printf 'No hardcoded Color(0x...) or checked Material palette colors outside core/theme.\n'
