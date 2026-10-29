# -*- coding: utf-8 -*-
"""Tests for the release-notes half of gen_listings.py.

Run from scripts/store:  python -m unittest test_gen_listings
"""
import io
import os
import tempfile
import unittest

import gen_listings as gl


def repo_with_notes(tmp, play_locale, text):
    """A scratch repo holding one Play release-notes file."""
    d = os.path.join(tmp, 'store', 'listings', 'play', play_locale)
    os.makedirs(d)
    with io.open(os.path.join(d, 'release_notes.txt'), 'w', encoding='utf-8',
                 newline='\n') as f:
        f.write(text)
    return tmp


class TestIosReleaseNotes(unittest.TestCase):
    def test_importing_the_module_writes_nothing(self):
        # The generator used to run at import, which made it untestable: a
        # test that imported it rewrote every listing in the real repo.
        self.assertTrue(callable(gl.main))

    def test_ios_notes_are_the_play_notes_for_that_language(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo_with_notes(tmp, 'pl-PL', 'Naprawiono: wykres.\n\nNowość: mapa.\n')
            self.assertEqual(gl.ios_release_notes('pl', 'pl-PL', repo=tmp),
                             'Naprawiono: wykres.\n\nNowość: mapa.')

    def test_refuses_a_platform_name_apple_rejects(self):
        # Guideline 2.3.10 covers "What's New" exactly as it covers the
        # description, and this app has been rejected under it twice.
        for bad in ('Now with Android widgets.', 'Rate us on Google Play!',
                    'Also on the Play Store.'):
            with tempfile.TemporaryDirectory() as tmp:
                repo_with_notes(tmp, 'en-US', 'Fixed: the chart.\n\n' + bad)
                with self.assertRaises(SystemExit) as raised:
                    gl.ios_release_notes('en', 'en-US', repo=tmp)
                self.assertIn('2.3.10', str(raised.exception))

    def test_refuses_a_language_with_no_play_notes(self):
        # Silently skipping would ship a version whose "What's New" is blank,
        # or still describes the previous release, in that language.
        with tempfile.TemporaryDirectory() as tmp:
            repo_with_notes(tmp, 'en-US', 'Fixed: the chart.')
            with self.assertRaises(SystemExit) as raised:
                gl.ios_release_notes('tr', 'tr-TR', repo=tmp)
            self.assertIn('tr-TR', str(raised.exception))

    def test_refuses_empty_notes(self):
        with tempfile.TemporaryDirectory() as tmp:
            repo_with_notes(tmp, 'en-US', '\n  \n')
            with self.assertRaises(SystemExit):
                gl.ios_release_notes('en', 'en-US', repo=tmp)

    def test_reports_notes_over_either_store_limit(self):
        self.assertEqual(gl.release_notes_problems('en', 'x' * 500), [])
        over_play = gl.release_notes_problems('en', 'x' * 501)
        self.assertEqual(len(over_play), 1)
        self.assertIn('500', over_play[0])
        over_both = gl.release_notes_problems('en', 'x' * 4001)
        self.assertEqual(len(over_both), 2)

    def test_every_app_store_language_has_notes_in_this_repo(self):
        # Against the real checkout: the 12 App Store locales each resolve to
        # a Play file that exists, is within limits and is free of the
        # forbidden terms.
        ios = [(k, p) for k, (p, i) in gl.LOCALE_MAP.items() if i]
        self.assertEqual(len(ios), 12)
        for key, play_locale in ios:
            text = gl.ios_release_notes(key, play_locale)
            self.assertTrue(text)
            self.assertEqual(gl.release_notes_problems(key, text), [])


if __name__ == '__main__':
    unittest.main()
