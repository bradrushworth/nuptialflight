# -*- coding: utf-8 -*-
"""Capture the why-sheet and report-sheet shots by coordinate taps.

Why row Y is detected per locale from its own phone_home.png: the first
neutral-toned full-width band between the hourly chart and the week list.
The FAB is anchored bottom-right at a fixed position.
"""
import sys, os, json, io
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image
from playwright.sync_api import sync_playwright

REPO = r"C:\Users\Brad\StudioProjects\nuptialflight\.claude\worktrees\app-review-overhaul-dbc88c"
RAW = os.path.join(REPO, 'store', 'raw')
URL = 'https://nuptialflight.app/'

LOCALES = {
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
"""


def why_row_y(home_png):
    """1x-scale Y of the Why row centre, from the 3x home screenshot."""
    im = Image.open(home_png).convert('RGB').resize((430, 932), Image.LANCZOS)
    surface = im.getpixel((5, 500))

    def is_band(y):
        p = im.getpixel((30, y))
        d = sum(abs(a - b) for a, b in zip(p, surface))
        neutral = abs(p[1] - p[0]) < 30  # not a saturated green chart bar
        return d > 30 and neutral

    run_start, best = None, None
    for y in range(400, 800):
        if is_band(y):
            if run_start is None:
                run_start = y
        else:
            if run_start is not None and y - run_start >= 36:
                best = (run_start + y) // 2
                break
            run_start = None
    return best


def wait_loaded(page):
    try:
        with page.expect_console_message(
                lambda m: '_updateWeather' in m.text, timeout=60000):
            pass
    except Exception:
        pass
    page.wait_for_timeout(4000)


def shot_after_tap(browser, tag, x, y, out_path):
    ctx = browser.new_context(locale=tag,
        viewport={'width': 430, 'height': 932}, device_scale_factor=3,
        is_mobile=True, has_touch=True)
    ctx.add_init_script(INIT)
    page = ctx.new_page()
    page.goto(URL, wait_until='load', timeout=90000)
    wait_loaded(page)
    page.mouse.click(x, y)
    page.wait_for_timeout(2500)
    page.screenshot(path=out_path)
    ctx.close()


def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(channel='chrome', headless=True)
        for key, tag in LOCALES.items():
            d = os.path.join(RAW, key)
            home = os.path.join(d, 'phone_home.png')
            try:
                wy = why_row_y(home)
                if wy is None:
                    print(f'{key}: why row NOT FOUND')
                else:
                    shot_after_tap(browser, tag, 215, wy,
                                   os.path.join(d, 'phone_why.png'))
                    print(f'{key}: why OK (y={wy})')
            except Exception as e:
                print(f'{key}: why FAIL {e}')
            try:
                shot_after_tap(browser, tag, 390, 888,
                               os.path.join(d, 'phone_report.png'))
                print(f'{key}: report OK')
            except Exception as e:
                print(f'{key}: report FAIL {e}')
        browser.close()


if __name__ == '__main__':
    run()
