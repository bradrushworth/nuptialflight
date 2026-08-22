# -*- coding: utf-8 -*-
"""Compose captioned store screenshots from raw captures.

Outputs:
  store/screenshots/ios/<loc>/{01_home,02_why,03_report,04_dark}.png  1290x2796
  store/screenshots/ios/<loc>/ipad_01_home.png                        2048x2732
  store/screenshots/play/<loc>/{01..04}.png                           1080x1920
  store/screenshots/play/<loc>/feature_graphic.png                    1024x500
"""
import io, os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

REPO = r"C:\Users\Brad\StudioProjects\nuptialflight\.claude\worktrees\app-review-overhaul-dbc88c"
RAW = os.path.join(REPO, 'store', 'raw')
OUT = os.path.join(REPO, 'store', 'screenshots')

LOCALE_MAP = {
    'en': ('en-US', 'en-US'), 'tr': ('tr-TR', 'tr'), 'fil': ('fil', None),
    'es': ('es-ES', 'es-ES'), 'fr': ('fr-FR', 'fr-FR'), 'de': ('de-DE', 'de-DE'),
    'pl': ('pl-PL', 'pl'), 'cs': ('cs-CZ', 'cs'), 'el': ('el-GR', 'el'),
    'pt': ('pt-BR', 'pt-BR'), 'nl': ('nl-NL', 'nl-NL'), 'id': ('id', 'id'),
    'ms': ('ms', 'ms'),
}

CAPTIONS = {
 'en': ["Should you go looking today?", "See exactly why", "Your sightings train the forecast", "Beautiful in dark mode"],
 'tr': ["Bugün bakmaya değer mi?", "Nedenini tam olarak görün", "Gözlemleriniz tahmini eğitir", "Karanlık modda da şık"],
 'fil': ["Dapat ka bang maghanap ngayon?", "Tingnan kung bakit", "Ang ulat mo ang nagpapatalino rito", "Maganda sa dark mode"],
 'es': ["¿Salir a buscar hoy?", "Ve exactamente por qué", "Tus avistamientos entrenan la IA", "Precioso en modo oscuro"],
 'fr': ["Sortir chercher aujourd'hui ?", "Voyez exactement pourquoi", "Vos observations entraînent l'IA", "Superbe en mode sombre"],
 'de': ["Heute rausgehen und suchen?", "Sieh genau, warum", "Deine Sichtungen trainieren die KI", "Schön im Dunkelmodus"],
 'pl': ["Czy dziś warto szukać?", "Zobacz dokładnie dlaczego", "Twoje obserwacje uczą model", "Piękna w trybie ciemnym"],
 'cs': ["Vyrazit dnes hledat?", "Podívejte se přesně proč", "Vaše pozorování učí model", "Krásná v tmavém režimu"],
 'el': ["Να βγεις να ψάξεις σήμερα;", "Δες ακριβώς γιατί", "Οι αναφορές σου εκπαιδεύουν το μοντέλο", "Όμορφη στη σκοτεινή λειτουργία"],
 'pt': ["Vale a pena procurar hoje?", "Veja exatamente por quê", "Seus relatos treinam a IA", "Linda no modo escuro"],
 'nl': ["Vandaag gaan zoeken?", "Zie precies waarom", "Jouw meldingen trainen het model", "Prachtig in donkere modus"],
 'id': ["Perlu mencari hari ini?", "Lihat persis alasannya", "Laporan Anda melatih model", "Indah dalam mode gelap"],
 'ms': ["Patut keluar mencari hari ini?", "Lihat sebabnya dengan tepat", "Laporan anda melatih model", "Cantik dalam mod gelap"],
}

FEATURE_TAG = {  # one-liner for the Play feature graphic
 'en': "Know when queen ants will fly",
 'tr': "Kraliçeler ne zaman uçacak?",
 'fil': "Kailan lilipad ang mga reyna?",
 'es': "¿Cuándo volarán las reinas?",
 'fr': "Quand les reines voleront-elles ?",
 'de': "Wann fliegen die Königinnen?",
 'pl': "Kiedy polecą królowe?",
 'cs': "Kdy poletí královny?",
 'el': "Πότε θα πετάξουν οι βασίλισσες;",
 'pt': "Quando as rainhas vão voar?",
 'nl': "Wanneer vliegen de koninginnen?",
 'id': "Kapan ratu semut terbang?",
 'ms': "Bila permaisuri akan terbang?",
}

FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
FONT_REG = r"C:\Windows\Fonts\segoeui.ttf"

LIGHT_BG = ((225, 236, 226), (244, 247, 244))   # top -> bottom gradient
DARK_BG = ((18, 28, 22), (28, 40, 32))
LIGHT_TXT = (30, 51, 39)
DARK_TXT = (233, 240, 233)

SHOTS = [('phone_home.png', 0, False), ('phone_why.png', 1, False),
         ('phone_report.png', 2, False), ('phone_dark.png', 3, True)]


def gradient(size, top, bottom):
    w, h = size
    img = Image.new('RGB', (w, h))
    px = img.load()
    for y in range(h):
        f = y / max(1, h - 1)
        c = tuple(int(t + (b - t) * f) for t, b in zip(top, bottom))
        for x in range(w):
            px[x, y] = c
    return img


def rounded(img, radius):
    mask = Image.new('L', img.size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius=radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def fit_text(draw, text, max_w, start_size):
    size = start_size
    while size > 28:
        font = ImageFont.truetype(FONT_BOLD, size)
        if draw.textlength(text, font=font) <= max_w:
            return font
        size -= 4
    return ImageFont.truetype(FONT_BOLD, 28)


def compose_panel(shot_path, caption, canvas_size, dark):
    W, H = canvas_size
    top, bottom = DARK_BG if dark else LIGHT_BG
    canvas = gradient((W, H), top, bottom)
    draw = ImageDraw.Draw(canvas)

    # Caption band ~ top 9% of canvas
    cap_y = int(H * 0.045)
    font = fit_text(draw, caption, int(W * 0.88), int(H * 0.032))
    tw = draw.textlength(caption, font=font)
    draw.text(((W - tw) / 2, cap_y), caption,
              font=font, fill=DARK_TXT if dark else LIGHT_TXT)

    # Device shot below, bottom-bleed
    shot = Image.open(shot_path).convert('RGB')
    dev_w = int(W * 0.80)
    scale = dev_w / shot.width
    dev_h = int(shot.height * scale)
    shot = shot.resize((dev_w, dev_h), Image.LANCZOS)
    radius = int(dev_w * 0.10)
    dev_y = int(H * 0.135)
    dev_x = (W - dev_w) // 2

    # soft shadow
    sh_pad = int(dev_w * 0.06)
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([dev_x - 6, dev_y + 10, dev_x + dev_w + 6, dev_y + dev_h + 10],
                         radius=radius, fill=(0, 0, 0, 90 if not dark else 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(sh_pad // 2))
    canvas = Image.alpha_composite(canvas.convert('RGBA'), shadow)

    dev = rounded(shot, radius)
    # thin bezel ring
    ring = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.rounded_rectangle([dev_x - 4, dev_y - 4, dev_x + dev_w + 4, dev_y + dev_h + 4],
                         radius=radius + 4,
                         fill=(20, 26, 22, 255) if not dark else (60, 74, 64, 255))
    canvas = Image.alpha_composite(canvas, ring)
    canvas.paste(dev, (dev_x, dev_y), dev)
    return canvas.convert('RGB')


def feature_graphic(loc_key, title, home_path):
    W, H = 1024, 500
    canvas = gradient((W, H), (40, 74, 55), (24, 44, 33))  # deep eucalypt
    draw = ImageDraw.Draw(canvas)
    # right: cropped hero region of the home shot
    shot = Image.open(home_path).convert('RGB')
    crop = shot.crop((int(shot.width * 0.037), int(shot.height * 0.062),
                      int(shot.width * 0.963), int(shot.height * 0.335)))
    scale = 430 / crop.height
    crop = crop.resize((int(crop.width * scale), 430), Image.LANCZOS)
    crop = rounded(crop, 28)
    cx = W - crop.width + 30
    canvas_rgba = canvas.convert('RGBA')
    canvas_rgba.paste(crop, (max(cx, 480), 35), crop)
    canvas = canvas_rgba.convert('RGB')
    draw = ImageDraw.Draw(canvas)
    # left: title + tagline
    tf = fit_text(draw, title, 430, 52)
    draw.text((40, 150), title, font=tf, fill=(240, 246, 240))
    tag = FEATURE_TAG[loc_key]
    gf_size = 30
    gf = ImageFont.truetype(FONT_REG, gf_size)
    while draw.textlength(tag, font=gf) > 430 and gf_size > 18:
        gf_size -= 2
        gf = ImageFont.truetype(FONT_REG, gf_size)
    draw.text((40, 150 + tf.size + 18), tag, font=gf, fill=(196, 214, 199))
    return canvas


def title_for(loc_key):
    play_loc = LOCALE_MAP[loc_key][0]
    p = os.path.join(REPO, 'store', 'listings', 'play', play_loc, 'title.txt')
    return io.open(p, encoding='utf-8').read().strip()


def run():
    done, missing = [], []
    for key, (play_loc, ios_loc) in LOCALE_MAP.items():
        raw = os.path.join(RAW, key)
        ios_dir = os.path.join(OUT, 'ios', ios_loc or key)
        play_dir = os.path.join(OUT, 'play', play_loc)
        os.makedirs(ios_dir, exist_ok=True)
        os.makedirs(play_dir, exist_ok=True)
        names = ['01_home', '02_why', '03_report', '04_dark']
        for (fname, ci, dark), name in zip(SHOTS, names):
            src = os.path.join(raw, fname)
            if not os.path.exists(src):
                missing.append(f'{key}/{fname}')
                continue
            cap = CAPTIONS[key][ci]
            if ios_loc:
                compose_panel(src, cap, (1290, 2796), dark).save(
                    os.path.join(ios_dir, name + '.png'))
            compose_panel(src, cap, (1080, 1920), dark).save(
                os.path.join(play_dir, name + '.png'))
        tab = os.path.join(raw, 'tablet_home.png')
        if os.path.exists(tab) and ios_loc:
            compose_panel(tab, CAPTIONS[key][0], (2048, 2732), False).save(
                os.path.join(ios_dir, 'ipad_01_home.png'))
        elif not os.path.exists(tab):
            missing.append(f'{key}/tablet_home.png')
        home = os.path.join(raw, 'phone_home.png')
        if os.path.exists(home):
            feature_graphic(key, title_for(key), home).save(
                os.path.join(play_dir, 'feature_graphic.png'))
        done.append(key)
    print('composed:', ' '.join(done))
    if missing:
        print('MISSING RAW:', missing)


if __name__ == '__main__':
    run()
