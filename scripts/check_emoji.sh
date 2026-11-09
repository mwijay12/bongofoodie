#!/usr/bin/env bash
# CI guard: fail if any emoji code point appears in mobile/lib UI copy, the
# showcase seed, or Supabase seed inserts. Mirrors check_spinners.sh.
# Allowlist: the sanitizer holds only numeric code points / regex escapes,
# never literal emoji characters.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])

# Unicode scalar ranges. Built from numeric code points so this script itself
# contains no literal emoji characters.
ranges = [
    (0x1F000, 0x1FAFF),  # pictographs, emoticons, food, awards
    (0x1F1E6, 0x1F1FF),  # regional indicators (flag pairs)
    (0x1F3FB, 0x1F3FF),  # skin-tone modifiers
    (0x2600, 0x27BF),    # misc symbols and dingbats
    (0x2B00, 0x2BFF),    # emoji stars / arrows
    (0xFE0F, 0xFE0F),    # variation selector-16
    (0x200D, 0x200D),    # zero width joiner
    (0x20E3, 0x20E3),    # combining enclosing keycap
]
pattern = re.compile(
    '['
    + ''.join(re.escape(chr(a)) + '-' + re.escape(chr(b)) for a, b in ranges)
    + ']'
)

allowlist = {
    'mobile/lib/core/utils/emoji_sanitizer.dart',
}

targets = sorted((root / 'mobile/lib').rglob('*.dart'))
for rel in ('scripts/setup-supabase.js', 'supabase/schema.sql'):
    p = root / rel
    if p.exists():
        targets.append(p)
targets += sorted((root / 'supabase/migrations').glob('*.sql'))

violations = []
for path in targets:
    rel = path.relative_to(root).as_posix()
    if rel in allowlist:
        continue
    for number, line in enumerate(
        path.read_text(encoding='utf-8').splitlines(), 1
    ):
        if pattern.search(line):
            violations.append(f'{rel}:{number}: {line.strip()}')

if violations:
    print('Emoji code points found in UI copy or showcase seed:')
    for violation in violations:
        print(f'  {violation}')
    sys.exit(1)

print('No emoji code points in mobile/lib or the showcase seed.')
PY
