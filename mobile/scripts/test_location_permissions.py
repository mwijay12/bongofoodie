#!/usr/bin/env python3
import plistlib
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET
from apply_location_permissions import apply, ANDROID

class PermissionsTests(unittest.TestCase):
    def test_idempotent_foreground_only_overlay(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = root / 'android/app/src/main/AndroidManifest.xml'
            manifest.parent.mkdir(parents=True)
            manifest.write_text('<manifest><application /></manifest>')
            info = root / 'ios/Runner/Info.plist'
            info.parent.mkdir(parents=True)
            info.write_bytes(plistlib.dumps({'CFBundleName': 'Bongo Foodie'}))
            podfile = root / 'ios/Podfile'
            podfile.write_text('post_install do |installer|\n  installer.pods_project.targets.each do |target|\n    flutter_additional_ios_build_settings(target)\n  end\nend\n')
            apply(root)
            snapshot = [p.read_bytes() for p in [manifest, info, podfile]]
            apply(root)
            self.assertEqual(snapshot, [p.read_bytes() for p in [manifest, info, podfile]])
            names = [p.get(f'{{{ANDROID}}}name') for p in ET.parse(manifest).getroot().findall('uses-permission')]
            self.assertEqual(set(names), {'android.permission.INTERNET', 'android.permission.ACCESS_COARSE_LOCATION', 'android.permission.ACCESS_FINE_LOCATION'})
            data = plistlib.loads(info.read_bytes())
            self.assertIn('NSLocationWhenInUseUsageDescription', data)
            self.assertNotIn('NSLocationAlwaysAndWhenInUseUsageDescription', data)
            self.assertNotIn('UIBackgroundModes', data)
            self.assertIn('BYPASS_PERMISSION_LOCATION_ALWAYS=1', podfile.read_text())

if __name__ == '__main__':
    unittest.main()
