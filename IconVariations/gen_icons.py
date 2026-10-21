#!/usr/bin/env python3
"""Generate 10 ImageOptim app-icon variations as macOS-style squircle SVGs."""
import os, sys, subprocess

OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

# macOS icon grid: 1024 canvas, 824 body, ~185 corner radius
BX, BS, BR = 100, 824, 185


def lg(id, x1, y1, x2, y2, stops):
    s = "".join(f'<stop offset="{o}" stop-color="{c}"{f" stop-opacity=\"{a}\"" if a is not None else ""}/>'
                for o, c, *rest in stops for a in [rest[0] if rest else None])
    return f'<linearGradient id="{id}" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{s}</linearGradient>'


def shell(p, bg_stops, inner, extra_defs="", angle=(0, 0, 0, 1)):
    """Squircle body with gradient, soft drop shadow, top sheen, and clipped artwork."""
    defs = (
        f'<filter id="{p}sh" x="-20%" y="-20%" width="140%" height="150%">'
        f'<feGaussianBlur in="SourceAlpha" stdDeviation="16"/><feOffset dy="14"/>'
        f'<feComponentTransfer><feFuncA type="linear" slope="0.35"/></feComponentTransfer>'
        f'<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
        f'<filter id="{p}ds" x="-30%" y="-30%" width="160%" height="170%">'
        f'<feGaussianBlur in="SourceAlpha" stdDeviation="10"/><feOffset dy="10"/>'
        f'<feComponentTransfer><feFuncA type="linear" slope="0.30"/></feComponentTransfer>'
        f'<feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
        f'<clipPath id="{p}clip"><rect x="{BX}" y="{BX}" width="{BS}" height="{BS}" rx="{BR}"/></clipPath>'
        + lg(f"{p}bg", *angle, bg_stops)
        + lg(f"{p}sheen", 0, 0, 0, 1, [(0, "#fff", 0.28), (0.45, "#fff", 0)])
        + extra_defs
    )
    return (
        f'<defs>{defs}</defs>'
        f'<g filter="url(#{p}sh)"><rect x="{BX}" y="{BX}" width="{BS}" height="{BS}" rx="{BR}" fill="url(#{p}bg)"/></g>'
        f'<g clip-path="url(#{p}clip)">{inner}'
        f'<rect x="{BX}" y="{BX}" width="{BS}" height="{BS}" fill="url(#{p}sheen)"/></g>'
        f'<rect x="{BX + 1}" y="{BX + 1}" width="{BS - 2}" height="{BS - 2}" rx="{BR - 1}" fill="none" stroke="#fff" stroke-opacity="0.25" stroke-width="2"/>'
    )


def scene_defs(p):
    return (lg(f"{p}sky", 0, 0, 0, 1, [(0, "#3b1a6b"), (0.45, "#c2408a"), (0.8, "#ff9a3c"), (1, "#ffd36b")])
            + lg(f"{p}mtn", 0, 0, 0, 1, [(0, "#5a2a4a"), (1, "#22102a")])
            + lg(f"{p}mtn2", 0, 0, 0, 1, [(0, "#8a3f5c"), (1, "#40203c")]))


def scene(p, x, y, w, h):
    """Sunset landscape (nod to the original icon) filling the given box."""
    sx, sy = w / 100, h / 100
    pt = lambda pts: " ".join(f"{x + a * sx:.1f},{y + b * sy:.1f}" for a, b in pts)
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#{p}sky)"/>'
        f'<circle cx="{x + 68 * sx}" cy="{y + 50 * sy}" r="{13 * min(sx, sy) * 1.1:.1f}" fill="#fff4c8"/>'
        f'<polygon points="{pt([(0, 100), (0, 62), (18, 44), (32, 58), (50, 36), (72, 66), (86, 54), (100, 70), (100, 100)])}" fill="url(#{p}mtn2)"/>'
        f'<polygon points="{pt([(0, 100), (0, 80), (22, 62), (40, 78), (60, 60), (80, 82), (100, 74), (100, 100)])}" fill="url(#{p}mtn)"/>'
    )


def photo(p, x, y, w, h, border=18, r=14, uid=""):
    """White-bordered photo card with the landscape inside."""
    cid = f"{p}pc{uid}"
    ix, iy, iw, ih = x + border, y + border, w - 2 * border, h - 2 * border
    return (
        f'<g filter="url(#{p}ds)"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="#fdfdfd"/></g>'
        f'<clipPath id="{cid}"><rect x="{ix}" y="{iy}" width="{iw}" height="{ih}" rx="{max(r - border / 2, 4)}"/></clipPath>'
        f'<g clip-path="url(#{cid})">{scene(p, ix, iy, iw, ih)}</g>'
    )


icons = []

# 1 — Modern Press: flat redesign of the original press squeezing a photo
p = "a"
metal = lg(f"{p}metal", 0, 0, 0, 1, [(0, "#f4f6f9"), (0.5, "#c9cfd8"), (1, "#9aa3b0")])
inner = (
    f'<rect x="250" y="235" width="524" height="62" rx="31" fill="url(#{p}metal)"/>'
    f'<circle cx="250" cy="266" r="40" fill="#46c6ff"/><circle cx="774" cy="266" r="40" fill="#46c6ff"/>'
    f'<circle cx="238" cy="252" r="12" fill="#fff" opacity=".7"/><circle cx="762" cy="252" r="12" fill="#fff" opacity=".7"/>'
    f'<rect x="472" y="290" width="80" height="120" fill="url(#{p}metal)"/>'
    + "".join(f'<rect x="472" y="{305 + i * 22}" width="80" height="8" fill="#7d8796" opacity=".6"/>' for i in range(5))
    + f'<g filter="url(#{p}ds)"><rect x="230" y="405" width="564" height="78" rx="18" fill="url(#{p}metal)"/></g>'
    + "".join(f'<circle cx="{300 + i * 70}" cy="444" r="11" fill="#46c6ff"/>' for i in range(7))
    + photo(p, 262, 500, 500, 250, border=16)
    + f'<rect x="262" y="755" width="500" height="10" rx="5" fill="#fff" opacity=".55"/>'
    + f'<rect x="276" y="772" width="472" height="10" rx="5" fill="#fff" opacity=".35"/>'
)
icons.append(("01-modern-press", shell(p, [(0, "#2b3a67"), (1, "#121a33")], inner, metal + scene_defs(p))))

# 2 — Inward arrows: photo with four corner arrows squeezing in
p = "b"
arrow = lambda x1, y1, x2, y2, hx, hy: (
    f'<path d="M{x1} {y1} L{x2} {y2}" stroke="#fff" stroke-width="40" stroke-linecap="round"/>'
    f'<path d="M{x2 + hx} {y2} L{x2} {y2} L{x2} {y2 + hy}" stroke="#fff" stroke-width="40" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
inner = (
    photo(p, 352, 382, 320, 260, border=16)
    + arrow(200, 200, 315, 315, -80, -80) + arrow(824, 200, 709, 315, 80, -80)
    + arrow(200, 824, 315, 709, -80, 80) + arrow(824, 824, 709, 709, 80, 80)
)
icons.append(("02-squeeze-arrows", shell(p, [(0, "#1fd1c1"), (1, "#1a6fe0")], inner, scene_defs(p), (0, 0, 1, 1))))

# 3 — Vise: two jaws clamping a photo from the sides
p = "c"
steel = lg(f"{p}steel", 0, 0, 1, 0, [(0, "#5b6474"), (0.5, "#8d97a8"), (1, "#4a5260")])
inner = (
    photo(p, 372, 300, 280, 380, border=16)
    + f'<g filter="url(#{p}ds)">'
    f'<rect x="170" y="270" width="200" height="440" rx="28" fill="url(#{p}steel)"/>'
    f'<rect x="654" y="270" width="200" height="440" rx="28" fill="url(#{p}steel)"/>'
    f'<rect x="340" y="290" width="34" height="400" rx="8" fill="#2f3540"/>'
    f'<rect x="650" y="290" width="34" height="400" rx="8" fill="#2f3540"/></g>'
    + "".join(f'<rect x="{y}" y="310" width="8" height="360" fill="#3a414d" opacity=".5"/>' for y in (220, 260, 300, 704, 744, 784))
    + f'<rect x="150" y="745" width="724" height="36" rx="18" fill="#2f3540"/>'
    + f'<circle cx="160" cy="763" r="42" fill="#ff7a2f"/><circle cx="864" cy="763" r="42" fill="#ff7a2f"/>'
)
icons.append(("03-vise", shell(p, [(0, "#ffd56b"), (1, "#ff8a3d")], inner, steel + scene_defs(p))))

# 4 — Shrinking frames: large outlines collapsing into a small solid photo
p = "d"
inner = (
    f'<rect x="190" y="210" width="644" height="520" rx="40" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="16" stroke-dasharray="40 26"/>'
    f'<rect x="300" y="300" width="470" height="380" rx="32" fill="#fff" fill-opacity=".14" stroke="#fff" stroke-opacity=".6" stroke-width="14"/>'
    + photo(p, 470, 470, 320, 260, border=16)
    + f'<path d="M230 250 L410 400" stroke="#fff" stroke-width="30" stroke-linecap="round"/>'
    f'<path d="M400 320 L420 410 L330 418" stroke="#fff" stroke-width="30" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
)
icons.append(("04-shrinking-frames", shell(p, [(0, "#b45cff"), (1, "#ff4f8b")], inner, scene_defs(p), (0, 0, 1, 1))))

# 5 — Photo + badge: bold photo glyph with a green "smaller" down-arrow badge
p = "e"
inner = (
    photo(p, 200, 230, 560, 470, border=24, r=36)
    + f'<g filter="url(#{p}ds)"><circle cx="700" cy="680" r="140" fill="#22c55e"/></g>'
    f'<circle cx="700" cy="680" r="140" fill="none" stroke="#fff" stroke-width="16"/>'
    f'<path d="M700 600 L700 750 M640 695 L700 755 L760 695" stroke="#fff" stroke-width="34" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
)
icons.append(("05-photo-badge", shell(p, [(0, "#ffffff"), (1, "#dfe5ee")], inner, scene_defs(p))))

# 6 — Pixels: sunset rendered as pixels shrinking left→right
p = "f"
rows = ["#3b1a6b", "#6a2380", "#a8358a", "#e0567a", "#ff8a4a", "#ffb84d", "#5a2a4a", "#2a1530"]
cells = []
sizes = [72, 66, 60, 54, 48, 42, 36, 30]
x = 512 - (sum(sizes) + 8 * (len(sizes) - 1)) / 2
for ci, s in enumerate(sizes):
    gap = 8
    for ri, c in enumerate(rows):
        cy = 512 - (len(rows) * (s + gap) - gap) / 2 + ri * (s + gap)
        if ri >= 6 and (ci + ri) % 3 == 0:
            c = "#8a3f5c"
        if ri == 3 and ci == 5 or ri == 4 and ci in (4, 5):
            c = "#fff4c8"
        cells.append(f'<rect x="{x:.1f}" y="{cy:.1f}" width="{s}" height="{s}" rx="{s * 0.22:.1f}" fill="{c}"/>')
    x += s + 8
inner = "".join(cells)
icons.append(("06-pixels", shell(p, [(0, "#1c1f2b"), (1, "#0b0d14")], inner, "")))

# 7 — Feather: lightweight images, a feather filled with the sunset
p = "g"
fd = lg(f"{p}fth", 0, 0, 1, 1, [(0, "#3b1a6b"), (0.4, "#c2408a"), (0.75, "#ff9a3c"), (1, "#ffd36b")])
inner = (
    f'<g filter="url(#{p}ds)" transform="rotate(38 512 512)">'
    f'<path d="M512 170 C640 260 660 470 600 640 C570 720 540 790 512 850 C484 790 454 720 424 640 C364 470 384 260 512 170 Z" fill="url(#{p}fth)"/>'
    f'<path d="M512 200 L512 900" stroke="#fff" stroke-width="12" stroke-linecap="round"/>'
    + "".join(f'<path d="M512 {y} L{512 + s * w} {y - 46}" stroke="#fff" stroke-opacity=".45" stroke-width="7" stroke-linecap="round"/>'
              for y, w in [(330, 70), (420, 105), (510, 115), (600, 100), (690, 70)] for s in (-1, 1))
    + '</g>'
)
icons.append(("07-feather", shell(p, [(0, "#fdf6ec"), (1, "#f3e3cc")], inner, fd)))

# 8 — Gem: faceted crystal — "polished" images
p = "h"
facets = [
    ("#ffd36b", "330,330 430,250 512,330"), ("#ff9a3c", "430,250 594,250 512,330"),
    ("#ffd36b", "512,330 594,250 694,330"), ("#ffbf5a", "250,400 330,330 412,400"),
    ("#ff8a4a", "330,330 512,330 412,400"), ("#e0567a", "512,330 612,400 412,400"),
    ("#ff9a3c", "512,330 694,330 612,400"), ("#c2408a", "694,330 774,400 612,400"),
    ("#a8358a", "250,400 412,400 512,810"), ("#6a2380", "412,400 612,400 512,810"),
    ("#3b1a6b", "612,400 774,400 512,810"),
]
inner = (
    f'<circle cx="512" cy="500" r="330" fill="#7a5cff" opacity=".18"/>'
    f'<g filter="url(#{p}ds)">' + "".join(f'<polygon points="{pts}" fill="{c}"/>' for c, pts in facets) + "</g>"
    + f'<polyline points="250,400 330,330 430,250 594,250 694,330 774,400 512,810 250,400" fill="none" stroke="#fff" stroke-opacity=".5" stroke-width="5" stroke-linejoin="round"/>'
    f'<path d="M250 400 H774" stroke="#fff" stroke-opacity=".5" stroke-width="5"/>'
    f'<path d="M455 285 L480 270" stroke="#fff" stroke-width="12" stroke-linecap="round" opacity=".9"/>'
    + "".join(f'<path d="M{cx} {cy - r} L{cx + r * .3} {cy - r * .3} L{cx + r} {cy} L{cx + r * .3} {cy + r * .3} L{cx} {cy + r} L{cx - r * .3} {cy + r * .3} L{cx - r} {cy} L{cx - r * .3} {cy - r * .3} Z" fill="#fff"/>'
              for cx, cy, r in [(760, 240, 34), (250, 690, 24), (800, 640, 18)])
)
icons.append(("08-gem", shell(p, [(0, "#232a5c"), (1, "#0d1030")], inner, "")))

# 9 — Funnel: a big photo goes in, a small one comes out
p = "i"
fn = lg(f"{p}fn", 0, 0, 1, 0, [(0, "#e8ecf2"), (0.5, "#ffffff"), (1, "#c9d0db")])
inner = (
    photo(p, 330, 170, 364, 250, border=14, uid="1")
    + f'<g filter="url(#{p}ds)"><path d="M230 360 H794 L580 610 V680 H444 V610 Z" fill="url(#{p}fn)"/></g>'
    f'<ellipse cx="512" cy="360" rx="282" ry="30" fill="#b7c0cd"/>'
    f'<ellipse cx="512" cy="360" rx="262" ry="20" fill="#7d8796"/>'
    + photo(p, 437, 700, 150, 112, border=9, r=10, uid="2")
    + "".join(f'<circle cx="{x}" cy="756" r="{r}" fill="#fff" opacity=".7"/>' for x, r in [(620, 9), (655, 7), (684, 5)])
)
icons.append(("09-funnel", shell(p, [(0, "#3ee08f"), (1, "#0f9f8f")], inner, fn + scene_defs(p), (0, 0, 1, 1))))

# 10 — Accordion: photo folded into a zig-zag, squeezed from both sides
p = "j"
n, x0, x1, top, bot, d = 5, 290, 734, 330, 694, 44
w = (x1 - x0) / n
panels = []
for i in range(n):
    a, b = x0 + i * w, x0 + (i + 1) * w
    ya, yb = (top, top + d) if i % 2 == 0 else (top + d, top)
    pts = f"{a:.1f},{ya} {b:.1f},{yb} {b:.1f},{yb + bot - top - d} {a:.1f},{ya + bot - top - d}"
    panels.append(
        f'<clipPath id="{p}k{i}"><polygon points="{pts}"/></clipPath>'
        f'<g clip-path="url(#{p}k{i})">{scene(p, x0, top, x1 - x0, bot - top)}'
        f'<rect x="{x0}" y="{top}" width="{x1 - x0}" height="{bot - top}" fill="{"#fff" if i % 2 == 0 else "#000"}" opacity="{0.12 if i % 2 == 0 else 0.28}"/></g>'
        f'<polygon points="{pts}" fill="none" stroke="#fff" stroke-width="10" stroke-linejoin="round"/>')
side_arrow = lambda x, dx: (
    f'<path d="M{x} 512 h{dx}" stroke="#7a3b00" stroke-width="34" stroke-linecap="round"/>'
    f'<path d="M{x + dx - (-40 if dx > 0 else 40)} 462 L{x + dx} 512 L{x + dx - (-40 if dx > 0 else 40)} 562" stroke="#7a3b00" stroke-width="34" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
inner = f'<g filter="url(#{p}ds)">{"".join(panels)}</g>' + side_arrow(160, 80) + side_arrow(864, -80)
icons.append(("10-accordion", shell(p, [(0, "#ffe066"), (1, "#ffb020")], inner, scene_defs(p))))

# Write individual SVGs + PNGs
wrap = lambda body, vb="0 0 1024 1024", wh=1024: f'<svg xmlns="http://www.w3.org/2000/svg" width="{wh}" height="{wh}" viewBox="{vb}">{body}</svg>'
for name, body in icons:
    path = os.path.join(OUT, f"{name}.svg")
    open(path, "w").write(wrap(body))
    subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", path, "-o", path[:-4] + ".png"], check=True)

# Contact sheet: 5×2 grid with labels
cell, pad, lab = 400, 30, 50
W, H = 5 * cell + 6 * pad, 2 * (cell + lab) + 3 * pad
parts = [f'<rect width="{W}" height="{H}" fill="#eceef2"/>']
for k, (name, body) in enumerate(icons):
    cx, cy = pad + (k % 5) * (cell + pad), pad + (k // 5) * (cell + lab + pad)
    parts.append(f'<svg x="{cx}" y="{cy}" width="{cell}" height="{cell}" viewBox="0 0 1024 1024">{body}</svg>')
    parts.append(f'<text x="{cx + cell / 2}" y="{cy + cell + 30}" font-family="Helvetica Neue, Helvetica" font-size="24" fill="#3a3f4b" text-anchor="middle">{name}</text>')
sheet = os.path.join(OUT, "contact-sheet.svg")
open(sheet, "w").write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{"".join(parts)}</svg>')
subprocess.run(["rsvg-convert", sheet, "-o", sheet[:-4] + ".png"], check=True)
os.remove(sheet)
print("ok", len(icons))
