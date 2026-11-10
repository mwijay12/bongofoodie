#!/usr/bin/env python3
"""Apply checked-in branding AFTER flutter create; no Flutter dependency needed."""
from pathlib import Path
import argparse
from apply_location_permissions import apply as apply_location_permissions
import shutil
import xml.etree.ElementTree as ET


def apply(root: Path) -> None:
    android = root / 'android/app/src/main/res'
    ios = root / 'ios/Runner'
    if not android.is_dir() or not ios.is_dir():
        raise SystemExit('Run flutter create --platforms=android,ios,web first.')
    shutil.copytree(root / 'branding/android', android, dirs_exist_ok=True)
    shutil.copytree(root / 'branding/ios/Assets.xcassets',
                    ios / 'Assets.xcassets', dirs_exist_ok=True)
    storyboard = ios / 'Base.lproj/LaunchScreen.storyboard'
    tree = ET.parse(storyboard)
    backgrounds = tree.findall('.//view/color[@key="backgroundColor"]')
    if not backgrounds or not tree.findall('.//imageView[@image="LaunchImage"]'):
        raise SystemExit('Unexpected Flutter launch storyboard; inspect template before branding.')
    for color in backgrounds:
        color.attrib.clear()
        color.attrib.update(key='backgroundColor', red=str(26/255),
                            green=str(16/255), blue=str(11/255), alpha='1',
                            colorSpace='custom', customColorSpace='sRGB')
    tree.write(storyboard, encoding='utf-8', xml_declaration=True)
    apply_location_permissions(root)
    print('Applied BongoFoodie Android/iOS launcher and launch-screen branding.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    apply(parser.parse_args().root)
