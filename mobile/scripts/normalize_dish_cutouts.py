#!/usr/bin/env python3
"""Normalise dish cutouts so every plate reads at the same visual size.

The canonical art is already transparent, but each file puts a different
amount of empty margin around the food:

    chipsi mayai   1433x1225 of 1600
    mishkaki       1436x1153 of 1600
    nyama choma    1026x1027 of 1600   <- nearly half the visual weight
    pilau          1436x1121 of 1600
    samaki         1425x1436 of 1600

Drawn into a fixed box the small one looks like a side dish. This crops each
image to its own alpha bounds, then rescales the *food* to a consistent share
of the canvas, so a plate fills the same optical area everywhere.

Run:  python3 mobile/scripts/normalize_dish_cutouts.py
      python3 mobile/scripts/normalize_dish_cutouts.py --check   # verify only
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

CANVAS = 1600  # keep the canonical canvas the asset tests assert
# Share of the canvas the longest food edge should occupy. Plates are wider
# than tall, so using the longest edge keeps tall and wide dishes comparable.
# 0.92 of 1600 keeps the food large while leaving a little breathing room.
FILL = 0.92
V_PADDING = 0.06  # keeps a hair of transparent margin so edges never clip

DISHES_DIR = Path(__file__).resolve().parents[1] / 'assets' / 'dishes'


def alpha_bounds(path: Path) -> tuple[int, int, int, int, int, int]:
    out = subprocess.run(
        ['convert', str(path), '-alpha', 'extract', '-threshold', '10%',
         '-format', '%@', 'info:'],
        capture_output=True, text=True, check=True).stdout.strip()
    # e.g. "1433x1225+84+188"
    size, x, y = out.split('+')
    w, h = size.split('x')
    total_w = int(subprocess.run(
        ['identify', '-format', '%w', str(path)],
        capture_output=True, text=True, check=True).stdout)
    total_h = int(subprocess.run(
        ['identify', '-format', '%h', str(path)],
        capture_output=True, text=True, check=True).stdout)
    return int(w), int(h), int(x), int(y), total_w, total_h


def normalized_geometry(path: Path) -> tuple[int, int, int, int]:
    w, h, _x, _y, _tw, _th = alpha_bounds(path)
    target = int(CANVAS * FILL)
    scale = target / max(w, h)
    return (int(round(w * scale)), int(round(h * scale)),
            (CANVAS - int(round(w * scale))) // 2,
            (CANVAS - int(round(h * scale))) // 2)


def process(path: Path, check: bool) -> bool:
    w, h, x, y, total_w, total_h = alpha_bounds(path)
    new_w, new_h, off_x, off_y = normalized_geometry(path)

    if check:
        longest = max(w, h)
        target = CANVAS * FILL
        ok = abs(longest - target) / target < 0.02 and total_w == CANVAS
        status = 'OK  ' if ok else 'FAIL'
        print(f'{status} {path.name}: food {w}x{h} canvas {total_w}x{total_h} '
              f'-> expected canvas {CANVAS}, longest edge {target:.0f}')
        return ok

    # 1. crop to the food, 2. resize so the longest edge hits the target,
    # 3. centre it on a transparent canvas of fixed size.
    cmd = [
        'convert', str(path),
        '-crop', f'{w}x{h}+{x}+{y}', '+repage',
        '-resize', f'{new_w}x{new_h}',
        '-background', 'none',
        '-gravity', 'center',
        '-extent', f'{CANVAS}x{CANVAS}',
        '-strip',
        str(path),
    ]
    subprocess.run(cmd, check=True)
    print(f'     {path.name}: food {w}x{h} -> {new_w}x{new_h} '
          f'on {CANVAS}x{CANVAS} (offset {off_x},{off_y})')
    return True


def main() -> int:
    check = '--check' in sys.argv
    files = sorted(DISHES_DIR.glob('*.png'))
    if not files:
        print(f'No PNGs found in {DISHES_DIR}')
        return 1
    results = [process(f, check) for f in files]
    if check and not all(results):
        print('\nSome cutouts are not normalised yet.')
        return 1
    print(f'\n{len(files)} cutout(s) {"verified" if check else "normalised"}.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
