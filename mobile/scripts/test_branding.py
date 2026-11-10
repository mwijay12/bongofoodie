#!/usr/bin/env python3
"""Dependency-free branding checks; also exercise the post-create overlay."""
import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest
import xml.etree.ElementTree as ET

from apply_branding import apply

ROOT = Path(__file__).resolve().parents[1]


def png_size(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    return struct.unpack('>II', data[16:24])


class BrandingTests(unittest.TestCase):
    def test_launcher_sizes(self):
        for density, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                              ('xxhdpi', 144), ('xxxhdpi', 192)]:
            self.assertEqual(png_size(ROOT / f'branding/android/mipmap-{density}/ic_launcher.png'),
                             (size, size))
        for size in [192, 512]:
            self.assertEqual(png_size(ROOT / f'web/icons/Icon-{size}.png'), (size, size))
        catalog = ROOT / 'branding/ios/Assets.xcassets/AppIcon.appiconset'
        entries = json.loads((catalog / 'Contents.json').read_text())['images']
        self.assertTrue(any(e['idiom'] == 'ios-marketing' for e in entries))
        for entry in entries:
            size = round(float(entry['size'].split('x')[0]) * int(entry['scale'][0]))
            self.assertEqual(png_size(catalog / entry['filename']), (size, size))
            # Icons were exported as opaque RGB, not alpha-bearing iOS assets.
            self.assertIn((catalog / entry['filename']).read_bytes()[25], [0, 2, 3])

    def test_xml_and_manifest(self):
        for path in (ROOT / 'branding/android').rglob('*.xml'):
            ET.parse(path)
        manifest = json.loads((ROOT / 'web/manifest.json').read_text())
        for icon in manifest['icons']:
            self.assertTrue((ROOT / 'web' / icon['src']).is_file())
            self.assertIn('maskable', icon['purpose'])

    def test_overlay_survives_regeneration_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            import shutil
            shutil.copytree(ROOT / 'branding', root / 'branding')
            android = root / 'android/app/src/main/res'
            android.mkdir(parents=True)
            storyboard = root / 'ios/Runner/Base.lproj/LaunchScreen.storyboard'
            storyboard.parent.mkdir(parents=True)
            template = '''<document><view><color key="backgroundColor" white="1"/>
                <imageView image="LaunchImage"/></view></document>'''
            for _ in range(2):
                # Model flutter create overwriting a launch template, then apply.
                storyboard.write_text(template)
                apply(root)
                apply(root)
                color = ET.parse(storyboard).find('.//view/color')
                self.assertEqual(color.attrib['red'], str(26/255))
                actual = android / 'mipmap-xxxhdpi/ic_launcher.png'
                expected = ROOT / 'branding/android/mipmap-xxxhdpi/ic_launcher.png'
                self.assertEqual(hashlib.sha256(actual.read_bytes()).digest(),
                                 hashlib.sha256(expected.read_bytes()).digest())
                self.assertTrue((root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').exists())

    def test_real_hydrated_projects_when_available(self):
        android = ROOT / 'android/app/src/main/res'
        if not android.is_dir():
            self.skipTest('Native runners absent; integration check runs after CI hydration.')
        source = ROOT / 'branding/android/mipmap-xxxhdpi/ic_launcher.png'
        self.assertEqual((android / 'mipmap-xxxhdpi/ic_launcher.png').read_bytes(), source.read_bytes())
        color = ET.parse(ROOT / 'ios/Runner/Base.lproj/LaunchScreen.storyboard').find('.//view/color')
        self.assertEqual(color.attrib['red'], str(26/255))


if __name__ == '__main__':
    unittest.main()
