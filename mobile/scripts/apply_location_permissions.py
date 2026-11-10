#!/usr/bin/env python3
"""Foreground-only configuration applied after Flutter regenerates native runners."""
from pathlib import Path
import plistlib
import xml.etree.ElementTree as ET

ANDROID = 'http://schemas.android.com/apk/res/android'

def apply(root: Path) -> None:
    manifest = root / 'android/app/src/main/AndroidManifest.xml'
    if manifest.exists():
        ET.register_namespace('android', ANDROID)
        tree = ET.parse(manifest)
        node = tree.getroot()
        for permission in ('ACCESS_COARSE_LOCATION', 'ACCESS_FINE_LOCATION'):
            name = f'android.permission.{permission}'
            if not any(p.get(f'{{{ANDROID}}}name') == name for p in node.findall('uses-permission')):
                ET.SubElement(node, 'uses-permission', {f'{{{ANDROID}}}name': name})
        tree.write(manifest, encoding='utf-8', xml_declaration=True)
    info = root / 'ios/Runner/Info.plist'
    if info.exists():
        data = plistlib.loads(info.read_bytes())
        data['NSLocationWhenInUseUsageDescription'] = (
            'Only when you tap Use current location, show your device location to help you enter a delivery address. Delivery coverage is not confirmed.')
        info.write_bytes(plistlib.dumps(data))
    podfile = root / 'ios/Podfile'
    if podfile.exists():
        text = podfile.read_text()
        marker = 'flutter_additional_ios_build_settings(target)'
        if 'BYPASS_PERMISSION_LOCATION_ALWAYS=1' not in text:
            if marker not in text:
                raise RuntimeError('Unexpected Podfile template: inspect foreground permission configuration')
            text = text.replace(marker, marker + "\n    target.build_configurations.each do |config|\n      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)', 'BYPASS_PERMISSION_LOCATION_ALWAYS=1']\n    end")
            podfile.write_text(text)

if __name__ == '__main__':
    apply(Path(__file__).resolve().parents[1])
