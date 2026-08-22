# -*- coding: utf-8 -*-
"""Capture store screenshots of the live app in all 13 locales.

Per locale:
  phone light : home, why-sheet, report-sheet  (430x932 @3x = 1290x2796)
  phone dark  : home
  tablet light: home                            (1024x1366 @2x = 2048x2732)
Geolocation is stubbed to Manila (a genuine Prime day at capture time).
Taps go through Flutter's semantics tree (locale-aware aria-labels from the ARBs).
"""
import json, io, os, sys, re, traceback
from playwright.sync_api import sync_playwright

REPO = r"C:\Users\Brad\StudioProjects\nuptialflight\.claude\worktrees\app-review-overhaul-dbc88c"
OUT = os.path.join(REPO, 'store', 'raw')
URL = 'https://nuptialflight.app/'

LOCALES = {  # arb key -> browser locale tag
    'en': 'en-US', 'tr': 'tr-TR', 'fil': 'fil-PH', 'es': 'es-ES',
    'fr': 'fr-FR', 'de': 'de-DE', 'pl': 'pl-PL', 'cs': 'cs-CZ',
    'el': 'el-GR', 'pt': 'pt-BR', 'nl': 'nl-NL', 'id': 'id-ID', 'ms': 'ms-MY',
}

INIT = """
const fakePos = {coords: {latitude: 14.60, longitude: 120.98, accuracy: 10,
  altitude: null, altitudeAccuracy: null, heading: null, speed: null}, timestamp: Date.now()};
navigator.geolocation.getCurrentPosition = (s, e, o) => setTimeout(() => s(fakePos), 50);
navigator.geolocation.watchPosition = (s, e, o) => { setTimeout(() => s(fakePos), 50); return 1; };
navigator.geolocation.clearWatch = () => {};
const q = navigator.permissions.query.bind(navigator.permissions);
navigator.permissions.query = (d) => d && d.name === 'geolocation'
  ? Promise.resolve({state: 'granted', onchange: null, addEventListener(){}, removeEventListener(){}})
  : q(d);
"""

def arb(key):
    return json.load(io.open(os.path.join(REPO, 'lib', 'l10n', f'app_{key}.arb'), encoding='utf-8'))

def wait_loaded(page):
    """Wait until the app logs that weather is scored, then let it paint."""
    try:
        with page.expect_console_message(
                lambda m: '_updateWeather' in m.text, timeout=60000):
            pass
    except Exception:
        pass  # fall through; the fixed wait below still applies
    page.wait_for_timeout(4000)

def enable_a11y(page):
    ph = page.locator('flt-semantics-placeholder')
    if ph.count():
        ph.first.dispatch_event('click')
    else:
        page.get_by_label('Enable accessibility').first.dispatch_event('click')
    page.wait_for_timeout(2000)

def run():
    os.makedirs(OUT, exist_ok=True)
    report = []
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='chrome', headless=True)
        for key, tag in LOCALES.items():
            strings = arb(key)
            why_title = strings['whyTitle']
            fab_label = strings['reportFlightButton']
            d = os.path.join(OUT, key)
            os.makedirs(d, exist_ok=True)

            # --- phone light: home + why + report ------------------------
            try:
                ctx = browser.new_context(locale=tag,
                    viewport={'width': 430, 'height': 932}, device_scale_factor=3,
                    is_mobile=True, has_touch=True)
                ctx.add_init_script(INIT)
                page = ctx.new_page()
                page.goto(URL, wait_until='load', timeout=90000)
                wait_loaded(page)
                pass  # home kept from first pass

                enable_a11y(page)
                page.locator(f'[aria-label^="{why_title}"]').first.click(timeout=8000)
                page.wait_for_timeout(2500)
                page.screenshot(path=os.path.join(d, 'phone_why.png'))
                page.keyboard.press('Escape')
                page.wait_for_timeout(400)
                page.mouse.click(215, 60)  # barrier, in case Escape was ignored
                page.wait_for_timeout(1200)

                page.locator(f'[aria-label*="{fab_label}"]').first.click(timeout=8000)
                page.wait_for_timeout(2000)
                page.screenshot(path=os.path.join(d, 'phone_report.png'))
                ctx.close()
                report.append(f'{key}: phone light OK')
            except Exception as e:
                report.append(f'{key}: phone light FAIL {e}')
                try: ctx.close()
                except Exception: pass

            continue_dark = False
        browser.close()
    print('\n'.join(report))

if __name__ == '__main__':
    run()
