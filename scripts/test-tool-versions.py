#!/usr/bin/env python3
"""Offline regression tests for the version audit"""
import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('versions', Path(__file__).with_name('check-tool-versions.py'))
versions = importlib.util.module_from_spec(spec)
spec.loader.exec_module(versions)


class VersionTests(unittest.TestCase):
    def test_numeric_order(self):
        self.assertGreater(versions.version_key('10.2.1'), versions.version_key('9.10.0'))
        self.assertEqual(versions.version_key('2.6'), versions.version_key('2.6.0'))

    def test_tags_ignore_prereleases_and_sort_numerically(self):
        tags = [{'name': name} for name in ['v9.9.0', 'v11.0.0-rc1', 'v10.2.1', 'nightly']]
        with patch.object(versions, 'fetch', return_value=json.dumps(tags)):
            self.assertEqual(versions.github_latest('example/tool')[0], '10.2.1')

    def test_missing_tags_are_an_error(self):
        with patch.object(versions, 'fetch', return_value='[]'):
            result = versions.inspect(('tool', lambda: '1.0', 'example/tool', None))
        self.assertEqual(result['status'], 'error')

    def test_network_failure_is_not_reported_as_current(self):
        with patch.object(versions, 'fetch', side_effect=subprocess.CalledProcessError(22, 'curl', stderr='HTTP 403')):
            result = versions.inspect(('tool', lambda: '1.0', 'example/tool', None))
        self.assertEqual(result['status'], 'error')
        self.assertIn('403', result['error'])

    def test_outdated_and_development_versions(self):
        for current, expected in [('1.0', 'outdated'), ('2.0', 'current base'), ('2.1', 'ahead / development')]:
            with self.subTest(current=current), patch.object(versions, 'github_latest', return_value=('2.0', 'url')):
                self.assertEqual(versions.inspect(('tool', lambda: current, 'example/tool', None))['status'], expected)


if __name__ == '__main__':
    unittest.main()
