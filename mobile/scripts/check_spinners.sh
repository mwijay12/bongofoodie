#!/usr/bin/env bash
# CI check: fail if any spinner type appears under mobile/lib outside the allowlist.
# Allowlist: sign_in_screen, sign_up_screen, chef_ai_screen, staff_dispatch_screen,
# tanzania_location_sheet
set -euo pipefail
cd "$(dirname "$0")/.."

spinner_patterns=(
  "CircularProgressIndicator"
  "CupertinoActivityIndicator"
  "RefreshProgressIndicator"
  "LinearProgressIndicator"
  "class.*Spinner"
  "class.*Loader"
)

allowlist=(
  "sign_in_screen"
  "sign_up_screen"
  "chef_ai_screen"
  "staff_dispatch_screen"
  "tanzania_location_sheet"
)

violations=()
for pattern in "${spinner_patterns[@]}"; do
  while IFS=: read -r file line rest; do
    [ -z "$file" ] && continue
    in_allowlist=false
    for allowed in "${allowlist[@]}"; do
      if [[ "$file" == *"$allowed"* ]]; then
        in_allowlist=true
        break
      fi
    done
    if [ "$in_allowlist" = false ]; then
      violations+=("$file:$line: $rest")
    fi
  done < <(grep -rnE "$pattern" lib --include="*.dart" || true)
done

if [ ${#violations[@]} -gt 0 ]; then
  echo "Spinner violations found outside allowlist:"
  for v in "${violations[@]}"; do
    echo "  $v"
  done
  exit 1
fi

echo "No spinner violations outside the allowlist."
