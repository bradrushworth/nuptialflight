# -*- coding: utf-8 -*-
"""Myrmecia (Australian bull ant) - lateral habitus, drawn with shaded volume.

Not flat clip-art this time: every part is rendered as a mask and lit
(dorsal-to-ventral ramp + rim shading + specular sheen), the legs are
articulated coxa->femur->tibia->tarsus with knees held high, the antennae
are geniculate, and the mandibles are the long serrated blades that make a
bull ant a bull ant. Head faces right; classic field-guide stance.
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

S = 3                       # supersample
N = 1024
C = N * S
U = C / 1200.0              # design space is 1200 x 1200

# ------------------------------------------------------------------ paths
def bez(p0, p1, p2, p3, n=42):
    o = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        o.append((u*u*u*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t*t*t*p3[0],
                  u*u*u*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t*t*t*p3[1]))
    return o


def catmull(pts, n=14):
    if len(pts) < 3:
        return list(pts)
    P = [pts[0]] + list(pts) + [pts[-1]]
    out = []
    for i in range(len(P) - 3):
        p0, p1, p2, p3 = P[i], P[i+1], P[i+2], P[i+3]
        for j in range(n):
            t = j / n
            t2, t3 = t*t, t*t*t
            out.append((0.5*((2*p1[0]) + (-p0[0]+p2[0])*t + (2*p0[0]-5*p1[0]+4*p2[0]-p3[0])*t2 + (-p0[0]+3*p1[0]-3*p2[0]+p3[0])*t3),
                        0.5*((2*p1[1]) + (-p0[1]+p2[1])*t + (2*p0[1]-5*p1[1]+4*p2[1]-p3[1])*t2 + (-p0[1]+3*p1[1]-3*p2[1]+p3[1])*t3)))
    out.append(tuple(pts[-1]))
    return out


def stroke(centre, widths, n=14):
    """Tapered stroke through joint points; widths given at each joint."""
    pts = catmull(centre, n)
    # width interpolated over the whole polyline
    total = len(pts)
    seg = (len(centre) - 1)
    L, R = [], []
    for i, (x, y) in enumerate(pts):
        f = i / max(1, total - 1) * seg
        j = min(int(f), seg - 1)
        w = (widths[j] + (widths[j+1] - widths[j]) * (f - j)) / 2.0
        if i == 0:
            dx, dy = pts[1][0]-x, pts[1][1]-y
        elif i == total - 1:
            dx, dy = x-pts[-2][0], y-pts[-2][1]
        else:
            dx, dy = pts[i+1][0]-pts[i-1][0], pts[i+1][1]-pts[i-1][1]
        m = math.hypot(dx, dy) or 1.0
        L.append((x - dy/m*w, y + dx/m*w))
        R.append((x + dy/m*w, y - dx/m*w))
    return L + R[::-1]


def ellipse_pts(cx, cy, rx, ry, rot=0.0, n=96):
    o = []
    for i in range(n):
        a = 2*math.pi*i/n
        x, y = rx*math.cos(a), ry*math.sin(a)
        o.append((cx + x*math.cos(rot) - y*math.sin(rot),
                  cy + x*math.sin(rot) + y*math.cos(rot)))
    return o


# ------------------------------------------------------------------ anatomy
GROUND = 586

def geometry():
    G = {}

    # --- gaster: elongated, tapering to a soft point with the sting -----
    # (not a plain ellipse - this species carries a longer gaster that
    #  narrows to a slight point at the rear rather than ending round)
    top   = bez((450, 382), (434, 310), (312, 294), (224, 338))
    tipT  = bez((224, 338), (198, 354), (178, 374), (164, 398))   # -> the point
    tipB  = bez((164, 398), (178, 422), (202, 444), (234, 460))   # <- off the point
    bot   = bez((234, 460), (322, 490), (412, 468), (448, 422))
    close = bez((448, 422), (456, 408), (456, 394), (450, 382))
    G['gaster'] = top + tipT + tipB + bot + close
    # the sting leaves that point, angled slightly down and back; the gaster
    # is painted after it, so only the last third of it is ever visible
    G['sting'] = stroke([(184, 398), (168, 401), (150, 404)], [9, 3.0, 1.0])

    # --- waist: petiole (conical) + postpetiole (round) - Myrmecia has 2
    G['postpetiole'] = ellipse_pts(468, 390, 31, 36)
    G['petiole'] = ellipse_pts(521, 382, 24, 33, math.radians(-6))

    # --- mesosoma: high pronotum, saddle, sloping propodeum -------------
    meso = bez((556, 404), (544, 376), (550, 348), (566, 334))       # rear rise
    meso += bez((566, 334), (586, 318), (604, 320), (618, 326))      # propodeum->saddle
    meso += bez((618, 326), (634, 318), (658, 312), (676, 318))      # mesonotum
    meso += bez((676, 318), (696, 322), (708, 332), (712, 346))      # pronotum dome
    meso += bez((712, 346), (714, 360), (712, 372), (706, 380))      # neck front
    meso += bez((706, 380), (692, 406), (654, 416), (616, 418))      # ventral front
    meso += bez((616, 418), (588, 419), (566, 414), (556, 404))      # ventral rear
    G['mesosoma'] = meso

    # --- head: elongate, big eye, vertex rounded ------------------------
    G['head'] = ellipse_pts(762, 352, 66, 48, math.radians(7))
    G['eye'] = ellipse_pts(776, 336, 15, 20, math.radians(-14))

    # --- mandibles: long serrated blades, the signature -----------------
    def blade(bx, by, tx, ty, w0, teeth_n, tooth):
        outer = bez((bx, by), (bx + (tx-bx)*0.4, by + (ty-by)*0.28 - 6),
                    (tx - 30, ty - 10), (tx, ty))
        inner_line = bez((tx, ty), (tx - 36, ty + 5),
                         (bx + (tx-bx)*0.35, by + w0), (bx, by + w0))
        inner = []
        m = len(inner_line)
        for i, (x, y) in enumerate(inner_line):
            f = i / (m - 1)
            if 0.08 < f < 0.70:
                z = abs(math.sin(f * teeth_n * math.pi))
                y += tooth * z
            inner.append((x, y))
        return outer + inner
    G['mand_near'] = blade(820, 352, 944, 392, 14, 4, 4)
    G['mand_far'] = blade(816, 362, 906, 390, 8, 4, 4)

    # --- antennae: geniculate (long scape, elbow, arcing funiculus) -----
    G['ant_near'] = (stroke([(796, 330), (766, 282), (738, 240),
                             (758, 210), (804, 194), (856, 192), (890, 202)],
                            [10, 9, 8, 7, 6, 5, 4]),)
    G['ant_far'] = ()

    # --- legs: coxa -> knee(high) -> ankle -> tarsus(flat) -> claw ------
    def leg(cx, cy, kx, ky, ax, ay, fx, fy, ex, ey, w):
        return stroke([(cx, cy), (kx, ky), (ax, ay), (fx, fy), (ex, ey)],
                      [w, w*0.82, w*0.55, w*0.42, w*0.22])
    G['legs_near'] = [
        leg(640, 408, 724, 346, 780, 520, 828, 570, 892, 580, 19),   # fore
        leg(610, 412, 640, 326, 618, 520, 636, 570, 696, 582, 20),   # mid
        leg(568, 410, 472, 316, 436, 516, 396, 566, 322, 578, 21)]   # hind
    G['legs_far'] = [
        leg(614, 398, 692, 342, 734, 508, 772, 552, 826, 560, 17),
        leg(586, 400, 574, 316, 548, 506, 556, 552, 604, 562, 18),
        leg(548, 398, 452, 322, 420, 504, 386, 548, 320, 558, 19)]

    # --- wings (queen variant): swept back over the gaster --------------
    def wing_shape(bx, by, tipx, tipy, w):
        # leading edge is nearly straight and taut; trailing edge billows,
        # then both converge on a rounded tip - a real hymenopteran wing.
        L = math.hypot(tipx-bx, tipy-by)
        lead = bez((bx, by),
                   (bx - L*0.34, by - w*0.42),
                   (tipx + L*0.30, tipy - w*0.30),
                   (tipx, tipy))
        trail = bez((tipx, tipy),
                    (tipx + L*0.26, tipy + w*0.52),
                    (bx - L*0.30, by + w*0.86),
                    (bx, by))
        return lead + trail
    G['wing_fore'] = wing_shape(654, 326, 132, 250, 78)
    G['wing_hind'] = wing_shape(628, 344, 286, 318, 54)
    return G


# ------------------------------------------------------------------ shading
YY, XX = np.mgrid[0:C, 0:C].astype(np.float32)

def part_mask(polys):
    im = Image.new('L', (C, C), 0)
    d = ImageDraw.Draw(im)
    for p in polys:
        d.polygon([(x*U, y*U) for x, y in p], fill=255)
    return im


def shade(mask_im, base, ramp=(1.24, 0.66), rim=0.36, rim_w=8.0,
          specs=(), band_lines=None):
    m = np.asarray(mask_im, dtype=np.float32) / 255.0
    if m.max() < 0.01:
        return np.zeros((C, C, 4), np.float32)
    ys, xs = np.nonzero(m > 0.05)
    top, bot = ys.min(), ys.max()
    f = np.clip((YY - top) / max(1.0, bot - top), 0, 1)
    bright = ramp[0] + (ramp[1] - ramp[0]) * f
    dist = ndimage.distance_transform_edt(m > 0.5).astype(np.float32)
    bright *= (1 - rim) + rim * np.clip(dist / (rim_w * U), 0, 1)
    col = np.zeros((C, C, 3), np.float32)
    for i in range(3):
        col[..., i] = base[i] * bright
    for (sx, sy, srx, sry, ang, amt, scol) in specs:
        ca, sa = math.cos(ang), math.sin(ang)
        dx, dy = XX - sx*U, YY - sy*U
        xr = (dx*ca + dy*sa) / (srx*U)
        yr = (-dx*sa + dy*ca) / (sry*U)
        g = np.exp(-(xr*xr + yr*yr))
        for i in range(3):
            col[..., i] += amt * g * (scol[i] - col[..., i])
    if band_lines is not None:
        col *= (1 - band_lines[..., None] * 0.45)
    rgba = np.zeros((C, C, 4), np.float32)
    rgba[..., :3] = np.clip(col, 0, 255)
    rgba[..., 3] = m * 255
    return rgba


def over(dst, src):
    a = src[..., 3:4] / 255.0
    dst[..., :3] = src[..., :3] * a + dst[..., :3] * (1 - a)
    dst[..., 3:4] = np.maximum(dst[..., 3:4], src[..., 3:4])


def gaster_bands(gaster_poly):
    """Transverse tergite boundaries, traced off the actual gaster mask."""
    gm = np.asarray(part_mask([gaster_poly]), np.float32) / 255.0
    cols = np.nonzero(gm.max(axis=0) > 0.5)[0]
    if not len(cols):
        return np.zeros((C, C), np.float32)
    x0, x1 = cols.min(), cols.max()
    im = Image.new('L', (C, C), 0)
    d = ImageDraw.Draw(im)
    for frac in (0.30, 0.46, 0.62):      # measured from the pointed rear
        xc = int(x0 + (x1 - x0) * frac)
        pts = []
        for t in np.linspace(0.10, 0.90, 26):
            col = gm[:, xc]
            ys = np.nonzero(col > 0.5)[0]
            if len(ys) < 4:
                continue
            ytop, ybot = ys.min(), ys.max()
            y = ytop + (ybot - ytop) * t
            bow = -22 * U * math.sin(t * math.pi)   # bow toward the rear
            pts.append((xc + bow, y))
        if len(pts) > 2:
            d.line(pts, fill=205, width=int(2.3 * U))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(1.0)),
                      np.float32) / 255.0


# ------------------------------------------------------------------ render
RUST = (150, 60, 27)
RUST_LIT = (172, 82, 38)
HONEY = (198, 124, 56)
GASTER = (46, 35, 28)
DARK_F = 0.55

def render(winged=False):
    G = geometry()
    art = np.zeros((C, C, 4), np.float32)

    # far side first, darkened
    far_dark = tuple(c * DARK_F for c in RUST)
    over(art, shade(part_mask(G['legs_far'] + list(G['ant_far'])),
                    far_dark, ramp=(1.08, 0.82), rim=0.2, rim_w=4))

    # sting first so the gaster's rim overlaps its base
    over(art, shade(part_mask([G['sting']]), (52, 40, 31),
                    ramp=(1.1, 0.85), rim=0.25, rim_w=3))
    # gaster with bands and sheen
    over(art, shade(part_mask([G['gaster']]), GASTER, ramp=(1.5, 0.55),
                    rim=0.4, rim_w=16,
                    specs=[(310, 346, 112, 22, math.radians(-11), 0.48, (226, 232, 235)),
                           (276, 338, 40, 10, math.radians(-13), 0.34, (245, 248, 250))],
                    band_lines=gaster_bands(G['gaster'])))

    # waist + mesosoma
    over(art, shade(part_mask([G['postpetiole'], G['petiole']]), RUST,
                    ramp=(1.3, 0.62), rim=0.35, rim_w=6))
    over(art, shade(part_mask([G['mesosoma']]), RUST, ramp=(1.32, 0.6),
                    rim=0.35, rim_w=10,
                    specs=[(664, 330, 34, 14, math.radians(8), 0.30, (235, 210, 180))]))

    # wings (queen) - translucent amber over the gaster
    if winged:
        for shp, alpha in ((G['wing_hind'], 88), (G['wing_fore'], 108)):
            wim = Image.new('L', (C, C), 0)
            ImageDraw.Draw(wim).polygon([(x*U, y*U) for x, y in shp], fill=alpha)
            wm = np.asarray(wim, np.float32)
            wing = np.zeros((C, C, 4), np.float32)
            wing[..., 0], wing[..., 1], wing[..., 2] = 224, 196, 148
            wing[..., 3] = wm
            over(art, wing)
            # edge + a couple of veins
            eim = Image.new('L', (C, C), 0)
            de = ImageDraw.Draw(eim)
            de.line([(x*U, y*U) for x, y in shp] + [(shp[0][0]*U, shp[0][1]*U)],
                    fill=190, width=int(2.2*U))
            em = np.asarray(eim, np.float32)
            edge = np.zeros((C, C, 4), np.float32)
            edge[..., 0], edge[..., 1], edge[..., 2] = 214, 182, 128
            edge[..., 3] = em * (alpha / 255.0 + 0.35) * 255 / 255
            edge[..., 3] = np.clip(em * 0.8, 0, 255)
            over(art, edge)

    # head, then face gear
    over(art, shade(part_mask([G['head']]), RUST, ramp=(1.34, 0.62),
                    rim=0.36, rim_w=9,
                    specs=[(742, 336, 26, 13, math.radians(12), 0.28, (235, 208, 178))]))
    over(art, shade(part_mask([G['mand_far']]),
                    tuple(c * 0.5 for c in HONEY), ramp=(1.0, 0.9),
                    rim=0.2, rim_w=3))
    over(art, shade(part_mask([G['mand_near']]), HONEY, ramp=(1.18, 0.74),
                    rim=0.3, rim_w=4))
    over(art, shade(part_mask(list(G['ant_near'])), HONEY, ramp=(1.15, 0.8),
                    rim=0.25, rim_w=3))
    over(art, shade(part_mask([G['eye']]), (26, 22, 19), ramp=(1.15, 0.8),
                    rim=0.3, rim_w=4,
                    specs=[(760, 338, 6, 4, 0.0, 0.75, (255, 255, 255))]))

    # near legs last
    over(art, shade(part_mask(G['legs_near']), RUST_LIT, ramp=(1.2, 0.68),
                    rim=0.3, rim_w=5))
    return art


def bg_grad(top, bot):
    g = np.zeros((C, C, 3), np.float32)
    f = (YY / (C - 1))[..., None]
    g[:] = np.array(top, np.float32) * (1 - f) + np.array(bot, np.float32) * f
    return g


def compose(art, top, bot, frac=0.90, shadow=True):
    a = art[..., 3]
    ys, xs = np.nonzero(a > 8)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    w, h = x1 - x0, y1 - y0
    k = frac * C / max(w, h)
    im = Image.fromarray(np.clip(art, 0, 255).astype(np.uint8))
    im = im.crop((x0, y0, x1 + 1, y1 + 1))
    im = im.resize((max(1, int(w * k)), max(1, int(h * k))), Image.LANCZOS)

    bg = Image.fromarray(bg_grad(top, bot).astype(np.uint8)).convert('RGBA')
    px = (C - im.size[0]) // 2
    py = (C - im.size[1]) // 2 - int(0.02 * C)
    if shadow:
        sh = Image.new('L', (C, C), 0)
        ImageDraw.Draw(sh).ellipse([px + im.size[0]*0.06, py + im.size[1]*0.94,
                                    px + im.size[0]*0.94, py + im.size[1]*1.06],
                                   fill=52)
        sh = sh.filter(ImageFilter.GaussianBlur(0.02 * C))
        bg.alpha_composite(Image.merge('RGBA', [Image.new('L', (C, C), 0)]*3 + [sh]))
    bg.alpha_composite(im, (px, py))
    return bg.convert('RGB').resize((N, N), Image.LANCZOS)


def art_layer(art, frac):
    """Ant alone on transparency, scaled and centred - no ground, no shadow."""
    a = art[..., 3]
    ys, xs = np.nonzero(a > 8)
    x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
    w, h = x1 - x0, y1 - y0
    k = frac * C / max(w, h)
    im = Image.fromarray(np.clip(art, 0, 255).astype(np.uint8))
    im = im.crop((x0, y0, x1 + 1, y1 + 1))
    im = im.resize((max(1, int(w * k)), max(1, int(h * k))), Image.LANCZOS)
    out = Image.new('RGBA', (C, C), (0, 0, 0, 0))
    out.alpha_composite(im, ((C - im.size[0]) // 2, (C - im.size[1]) // 2))
    return out.resize((N, N), Image.LANCZOS)


def mono_layer(art, frac):
    """Flat white mask for Android 13+ themed icons; the OS supplies the tint."""
    layer = art_layer(art, frac)
    a = np.asarray(layer).astype(np.float32)
    out = np.zeros_like(a)
    out[..., 0:3] = 255.0
    out[..., 3] = np.clip(a[..., 3] * 1.15, 0, 255)
    return Image.fromarray(out.astype(np.uint8))


def glyph(art, width_px):
    """Flat white silhouette of the ant for the home-screen widget.

    Tinted at runtime with the band colour, so one asset serves every band
    and both light and night themes. Wings are forced fully opaque: at
    ~12dp the translucent wings of the icon would vanish, and the whole
    point of the glyph is that a winged queen is distinguishable at a
    glance from a wingless worker.
    """
    a = np.asarray(Image.fromarray(np.clip(art, 0, 255).astype(np.uint8)))
    alpha = a[..., 3].astype(np.float32)
    alpha = np.clip(alpha * 3.0, 0, 255)          # solidify the wings
    ys, xs = np.nonzero(alpha > 8)
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    out = np.zeros(a.shape, np.uint8)
    out[..., 0:3] = 255
    out[..., 3] = alpha.astype(np.uint8)
    im = Image.fromarray(out).crop(box)
    h = max(1, round(width_px * im.size[1] / im.size[0]))
    return im.resize((width_px, h), Image.LANCZOS)


def write_widget_glyphs(repo, worker, queen):
    """Emit widget_ant_worker / widget_ant_queen at every Android density."""
    dens = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}
    BASE_DP = 40
    shapes = {}
    for name, art in (('worker', worker), ('queen', queen)):
        for d, k in dens.items():
            g = glyph(art, int(round(BASE_DP * k)))
            path = os.path.join(repo, 'android', 'app', 'src', 'main', 'res',
                                'drawable-%s' % d)
            os.makedirs(path, exist_ok=True)
            g.save(os.path.join(path, 'widget_ant_%s.png' % name))
            shapes[name] = g.size
    return shapes, BASE_DP


def tile_icon(art, size_px):
    """Square monochrome icon for the Quick Settings tile.

    The widget glyph is 2:1; a Quick Settings slot is square and only ~24dp,
    so the ant is fitted into a square with breathing room rather than
    letterboxed into a sliver.
    """
    a = np.asarray(Image.fromarray(np.clip(art, 0, 255).astype(np.uint8)))
    alpha = np.clip(a[..., 3].astype(np.float32) * 3.0, 0, 255)
    ys, xs = np.nonzero(alpha > 8)
    out = np.zeros(a.shape, np.uint8)
    out[..., 0:3] = 255
    out[..., 3] = alpha.astype(np.uint8)
    im = Image.fromarray(out).crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    inner = int(size_px * 0.88)
    w = inner
    h = max(1, round(inner * im.size[1] / im.size[0]))
    im = im.resize((w, h), Image.LANCZOS)
    square = Image.new('RGBA', (size_px, size_px), (0, 0, 0, 0))
    square.alpha_composite(im, ((size_px - w) // 2, (size_px - h) // 2))
    return square


def write_tile_icons(repo, worker, queen):
    dens = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96}
    for name, art in (('worker', worker), ('queen', queen)):
        for d, px in dens.items():
            path = os.path.join(repo, 'android', 'app', 'src', 'main', 'res',
                                'drawable-%s' % d)
            os.makedirs(path, exist_ok=True)
            tile_icon(art, px).save(os.path.join(path, 'ic_qs_ant_%s.png' % name))


def reach_pct(im):
    a = np.asarray(im.split()[3])
    ys, xs = np.nonzero(a > 8)
    c = a.shape[0] / 2.0
    return 100.0 * float(np.hypot(xs - c, ys - c).max()) / c


if __name__ == '__main__':
    here = os.path.dirname(os.path.abspath(__file__))
    repo = os.path.abspath(os.path.join(here, '..', '..'))
    out = os.path.join(repo, 'assets', 'icon')
    os.makedirs(out, exist_ok=True)

    BONE = ((242, 234, 218), (212, 200, 180))
    queen = render(winged=True)

    # 1. iOS / legacy / web: opaque, ant filling the tile as approved.
    #    Opaque by construction, so remove_alpha_ios can no longer flatten
    #    transparency onto black - that was the old black-tile bug.
    compose(queen, *BONE, frac=0.90).save(os.path.join(out, 'icon.png'))

    # 2. Android adaptive. flutter_launcher_icons wraps the foreground in a
    #    16% inset. The ant is a wide shape, so its corner radius exceeds its
    #    half-width; fitting to 86% keeps the RADIUS inside the 66% safe circle.
    fg = art_layer(queen, 0.86)
    fg.save(os.path.join(out, 'foreground.png'))

    bg = Image.fromarray(bg_grad(*BONE).astype(np.uint8)).resize((N, N), Image.LANCZOS)
    bg.convert('RGBA').save(os.path.join(out, 'background.png'))

    mono_layer(queen, 0.86).save(os.path.join(out, 'monochrome.png'))

    # Widget glyphs: the same animal, wingless on quiet days and winged when
    # a flight is likely, so the widget says which one you might actually see.
    worker = render(winged=False)
    shapes, base_dp = write_widget_glyphs(repo, worker, queen)
    for k, v in shapes.items():
        print('widget glyph %-6s mdpi-equivalent %ddp wide, aspect %.2f'
              % (k, base_dp, v[0] / v[1]))

    # Quick Settings tile icons: square, monochrome, tinted by the system.
    write_tile_icons(repo, worker, queen)
    print('quick-settings tile icons written (24/36/48/72/96 px)')

    print('foreground reach %.1f%% of layer -> %.1f%% of icon (safe <= 66%%)'
          % (reach_pct(fg), reach_pct(fg) * 0.68))
    print('wrote icon.png, foreground.png, background.png, monochrome.png')
