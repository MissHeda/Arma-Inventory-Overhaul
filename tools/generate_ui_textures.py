#!/usr/bin/env python3
"""Draws the textures of Arma Inventory Overhaul's window and converts them to PAA.

Started as a copy of Enhanced First Aid Kits' generator, so both mods share one look: the same
corners, icons, switches and scroll thumb, plus the icons and the glass this window needs.

Everything is drawn in white on transparent at eight times its size and scaled down, so the edges
are smooth; the game tints most of it (colorText). The two switch states are drawn in colour, the
windows' glass (gloss_*) as white of little alpha, each for the shape of its window.

The empty slots' silhouettes (slot_*) are filled shapes rather than strokes: the game draws them
faint, and a solid shape still reads at 40 pixels where thin lines turn to mush. Weapons point their
muzzle to the left, like the game's own item pictures that replace them once the slot is filled.

    python tools/generate_ui_textures.py [path to ImageToPAA.exe]

Writes addons/gui/ui/*.paa. Needs Pillow, and ImageToPAA from Arma 3 Tools (default path below).
"""

import math
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageChops, ImageDraw, ImageFilter

IMAGE_TO_PAA = r"D:\Steam\steamapps\common\Arma 3 Tools\ImageToPAA\ImageToPAA.exe"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "addons", "gui", "ui")
SS = 8  # supersampling

WHITE = (255, 255, 255, 255)
CLEAR = (0, 0, 0, 0)

# The switch colours: ACCENT, ON_ACCENT and TEXT2 from addons/gui/defines.hpp, plus an opaque track.
ACCENT = (245, 165, 36, 255)
TRACK_OFF = (52, 58, 70, 255)
KNOB_ON = (22, 24, 29, 255)
KNOB_OFF = (163, 172, 185, 255)


def canvas(w, h):
    return Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))


def finish(im, w, h):
    return im.resize((w, h), Image.LANCZOS)


def whiten(im):
    """Keeps only the alpha and makes every pixel white, the see-through ones too: the game's filtering
    and the smaller mip levels mix in their colour, and black there would darken thin shapes."""
    return Image.merge("RGBA", (Image.new("L", im.size, 255),) * 3 + (im.getchannel("A"),))


def corner(which, size=64):
    """A quarter of a filled circle, round towards the outside of the panel it sits in."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    s = size * SS
    # The circle's centre is the panel-side corner of the tile.
    cx = {"tl": s, "tr": 0, "bl": s, "br": 0}[which]
    cy = {"tl": s, "tr": s, "bl": 0, "br": 0}[which]
    d.ellipse([cx - s, cy - s, cx + s, cy + s], fill=WHITE)
    return finish(im, size, size)


# How thick the ring corners are, as a share of their size - fnc_uiRing draws its edges to match
# (RING_SHARE in addons/gui/defines.hpp).
RING = 0.2


def ring_corner(which, size=64):
    """A quarter of a ring, the round corner of an outline (fnc_uiRing): outside the circle corner()
    fills, RING of the size thick."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    s = size * SS
    cx = {"tl": s, "tr": 0, "bl": s, "br": 0}[which]
    cy = {"tl": s, "tr": s, "bl": 0, "br": 0}[which]
    inner = s * (1 - RING)
    d.ellipse([cx - s, cy - s, cx + s, cy + s], fill=WHITE)
    d.ellipse([cx - inner, cy - inner, cx + inner, cy + inner], fill=CLEAR)
    return whiten(finish(im, size, size))


# Steps of the search progress ring - SEARCH_FRAMES in addons/gui/defines.hpp.
SEARCH_FRAMES = 32


def search_ring(k, frames=SEARCH_FRAMES, size=128, thick=0.13):
    """One step of the ring that fills while an item is searched (fnc_animateSearch): an arc from the
    top, clockwise, k / frames of the way round, with round ends. The last one, the whole ring, is
    also drawn faint under the others as their track."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    s = size * SS
    w = s * thick
    c = s / 2
    r = c - w / 2 - SS  # the stroke's centre line, a pixel off the edge
    start, end = -90, -90 + 360 * k / frames
    d.arc([c - r - w / 2, c - r - w / 2, c + r + w / 2, c + r + w / 2], start, end, fill=WHITE, width=round(w))
    if k < frames:
        for a in (start, end):
            x, y = c + r * math.cos(math.radians(a)), c + r * math.sin(math.radians(a))
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=WHITE)
    return whiten(finish(im, size, size))


def stroke_icon(draw_fn, size=128, width=10):
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    draw_fn(d, size * SS, width * SS)
    return finish(im, size, size)


def line(d, pts, w):
    """A polyline with round caps and joins."""
    d.line(pts, fill=WHITE, width=int(w), joint="curve")
    r = w / 2
    for x, y in (pts[0], pts[-1]):
        d.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)


def chevron(d, s, w, direction, offset=0.0):
    k = s * 0.16
    cx = s / 2 + offset * s
    cy = s / 2
    if direction == "right":
        pts = [(cx - k * 0.8, cy - k * 1.6), (cx + k * 0.8, cy), (cx - k * 0.8, cy + k * 1.6)]
    elif direction == "left":
        pts = [(cx + k * 0.8, cy - k * 1.6), (cx - k * 0.8, cy), (cx + k * 0.8, cy + k * 1.6)]
    else:  # down
        pts = [(cx - k * 1.6, cy - k * 0.8), (cx, cy + k * 0.8), (cx + k * 1.6, cy - k * 0.8)]
    line(d, pts, w)


def icon_close(d, s, w):
    a, b = s * 0.3, s * 0.7
    line(d, [(a, a), (b, b)], w)
    line(d, [(b, a), (a, b)], w)


def icon_search(d, s, w):
    r = s * 0.22
    cx, cy = s * 0.44, s * 0.44
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=int(w))
    k = r * 0.72
    line(d, [(cx + k, cy + k), (s * 0.78, s * 0.78)], w)


def icon_sort(d, s, w, ascending):
    # An arrow and three bars that grow or shrink with it.
    x = s * 0.3
    top, bottom = s * 0.24, s * 0.76
    line(d, [(x, top), (x, bottom)], w)
    if ascending:
        line(d, [(x - s * 0.12, top + s * 0.12), (x, top), (x + s * 0.12, top + s * 0.12)], w)
        bars = [0.16, 0.26, 0.36]
    else:
        line(d, [(x - s * 0.12, bottom - s * 0.12), (x, bottom), (x + s * 0.12, bottom - s * 0.12)], w)
        bars = [0.36, 0.26, 0.16]
    for i, length in enumerate(bars):
        y = s * (0.3 + i * 0.2)
        line(d, [(s * 0.5, y), (s * (0.5 + length), y)], w)


def icon_inventory(d, s, w):
    # A backpack: rounded body, carry loop on top, front pocket.
    d.rounded_rectangle([s * 0.24, s * 0.3, s * 0.76, s * 0.84], radius=s * 0.13, outline=WHITE, width=int(w))
    line(d, [(s * 0.39, s * 0.3), (s * 0.39, s * 0.2), (s * 0.61, s * 0.2), (s * 0.61, s * 0.3)], w)
    d.rounded_rectangle([s * 0.35, s * 0.56, s * 0.65, s * 0.84], radius=s * 0.05, outline=WHITE, width=int(w))


def icon_crate(d, s, w):
    # A package seen from a corner: hexagon outline, the front edge and the top faces.
    cx, top, bottom = s * 0.5, s * 0.16, s * 0.84
    left, right, upper, lower = s * 0.2, s * 0.8, s * 0.33, s * 0.67
    mid = s * 0.5
    line(d, [(cx, top), (right, upper), (right, lower), (cx, bottom), (left, lower), (left, upper), (cx, top)], w)
    line(d, [(left, upper), (cx, mid), (right, upper)], w)
    line(d, [(cx, mid), (cx, bottom)], w)


def icon_ground(d, s, w):
    # An arrow down onto a line.
    line(d, [(s * 0.5, s * 0.2), (s * 0.5, s * 0.62)], w)
    line(d, [(s * 0.34, s * 0.47), (s * 0.5, s * 0.63), (s * 0.66, s * 0.47)], w)
    line(d, [(s * 0.24, s * 0.8), (s * 0.76, s * 0.8)], w)


def icon_check(d, s, w):
    # The tick on the chosen row of a drop down menu.
    line(d, [(s * 0.24, s * 0.52), (s * 0.42, s * 0.7), (s * 0.77, s * 0.32)], w)


def icon_auto(d, s, w):
    # Two arrows chasing each other round a circle: "whichever fits".
    r = s * 0.27
    c = s / 2
    box = [c - r, c - r, c + r, c + r]
    d.arc(box, start=195, end=318, fill=WHITE, width=int(w))
    d.arc(box, start=15, end=138, fill=WHITE, width=int(w))
    k = s * 0.1
    for angle in (318, 138):
        a = math.radians(angle)
        x, y = c + r * math.cos(a), c + r * math.sin(a)
        # A solid head at the end of each arc, pointing on round the circle, clockwise.
        tx, ty = -math.sin(a), math.cos(a)
        nx, ny = math.cos(a), math.sin(a)
        d.polygon([
            (x + tx * k * 1.2, y + ty * k * 1.2),
            (x - tx * k * 0.2 + nx * k, y - ty * k * 0.2 + ny * k),
            (x - tx * k * 0.2 - nx * k, y - ty * k * 0.2 - ny * k),
        ], fill=WHITE)


def icon_person(d, s, w):
    # Head and shoulders: what the unit wears, the equipment column.
    r = s * 0.14
    cx, cy = s * 0.5, s * 0.33
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=int(w))
    d.arc([s * 0.22, s * 0.58, s * 0.78, s * 1.06], start=180, end=360, fill=WHITE, width=int(w))
    line(d, [(s * 0.22 + w / 2, s * 0.82), (s * 0.78 - w / 2, s * 0.82)], w)


def icon_swap(d, s, w):
    # Two arrows passing each other: "the other inventory", the vanilla one.
    line(d, [(s * 0.22, s * 0.36), (s * 0.74, s * 0.36)], w)
    line(d, [(s * 0.6, s * 0.22), (s * 0.74, s * 0.36), (s * 0.6, s * 0.5)], w)
    line(d, [(s * 0.78, s * 0.64), (s * 0.26, s * 0.64)], w)
    line(d, [(s * 0.4, s * 0.5), (s * 0.26, s * 0.64), (s * 0.4, s * 0.78)], w)


def icon_camera(d, s, w):
    # A photo camera: the switch for the live view of the soldier.
    d.rounded_rectangle([s * 0.16, s * 0.34, s * 0.84, s * 0.78], radius=s * 0.1, outline=WHITE, width=int(w))
    line(d, [(s * 0.36, s * 0.34), (s * 0.42, s * 0.23), (s * 0.58, s * 0.23), (s * 0.64, s * 0.34)], w)
    r = s * 0.12
    d.ellipse([s * 0.5 - r, s * 0.56 - r, s * 0.5 + r, s * 0.56 + r], outline=WHITE, width=int(w))


def speaker(d, s):
    """A loudspeaker: a small box and the cone opening to the right."""
    d.polygon([(s * 0.16, s * 0.4), (s * 0.3, s * 0.4), (s * 0.48, s * 0.24), (s * 0.48, s * 0.76),
               (s * 0.3, s * 0.6), (s * 0.16, s * 0.6)], fill=WHITE)


def icon_sound_on(d, s, w):
    # The speaker with two waves: sound plays.
    speaker(d, s)
    for r in (0.13, 0.25):
        d.arc([s * (0.52 - r), s * (0.5 - r), s * (0.52 + r), s * (0.5 + r)], -50, 50, fill=WHITE, width=int(w))


def icon_sound_off(d, s, w):
    # The speaker with a cross beside it: muted.
    speaker(d, s)
    line(d, [(s * 0.6, s * 0.38), (s * 0.84, s * 0.62)], w)
    line(d, [(s * 0.84, s * 0.38), (s * 0.6, s * 0.62)], w)


def icon_style(d, s, w):
    # Stacked layers: the Style button, which lays another look over the window.
    line(d, [(s * 0.5, s * 0.18), (s * 0.84, s * 0.36), (s * 0.5, s * 0.54), (s * 0.16, s * 0.36), (s * 0.5, s * 0.18)], w)
    line(d, [(s * 0.16, s * 0.53), (s * 0.5, s * 0.71), (s * 0.84, s * 0.53)], w)
    line(d, [(s * 0.16, s * 0.69), (s * 0.5, s * 0.87), (s * 0.84, s * 0.69)], w)


def icon_palette(d, s, w):
    # A painter's palette: a round board with a bite out of its lower right and four dabs of paint. The colour
    # button in the header, next to the speaker.
    cx, cy, r = s * 0.5, s * 0.5, s * 0.36
    body = arc_points(cx, cy, r, 78, 392, 72)
    bite = [(s * 0.80, s * 0.66), (s * 0.70, s * 0.64), (s * 0.65, s * 0.70), (s * 0.64, s * 0.78)]
    line(d, body + bite + [body[0]], w)
    dab = w * 0.62
    for x, y in ((0.3, 0.46), (0.43, 0.3), (0.6, 0.3), (0.72, 0.44)):
        d.ellipse([s * x - dab, s * y - dab, s * x + dab, s * y + dab], fill=WHITE)


def icon_weight(d, s, w):
    # A kettlebell: a round body with a flat foot, and its handle.
    r = s * 0.23
    cx, cy = s * 0.5, s * 0.6
    foot = s * 0.19  # the foot's depth below the centre
    half = math.sqrt(r * r - foot * foot)
    angle = math.degrees(math.atan2(foot, half))
    d.arc([cx - r, cy - r, cx + r, cy + r], start=180 - angle, end=360 + angle, fill=WHITE, width=int(w))
    line(d, [(cx - half, cy + foot), (cx + half, cy + foot)], w)
    # The handle flares out from the body and is wider than it is tall - drawn narrow and upright it
    # reads as a padlock.
    x = s * 0.15
    y = cy - math.sqrt(r * r - x * x)
    line(d, [(cx - x, y), (s * 0.27, s * 0.29), (s * 0.31, s * 0.2), (s * 0.4, s * 0.17),
             (s * 0.6, s * 0.17), (s * 0.69, s * 0.2), (s * 0.73, s * 0.29), (cx + x, y)], w)


def arc_points(cx, cy, r, start, end, steps=48):
    """Points along a circle from one angle to another, in degrees clockwise from three o'clock as
    Pillow counts them, for a stroke drawn with line() - its round joins keep the curve smooth."""
    return [(cx + r * math.cos(math.radians(start + (end - start) * i / steps)),
             cy + r * math.sin(math.radians(start + (end - start) * i / steps))) for i in range(steps + 1)]


def icon_setup(d, s, w, teeth=8):
    # A cog: the setup wizard. Its outline - the teeth round the wheel, each a little narrower at its tip
    # as on a real gear, the wheel's rim between them - and the hole for the axle.
    c = s / 2
    outer, root = s * 0.37, s * 0.27
    step = 360 / teeth
    pts = []
    for k in range(teeth):
        a = -90 + k * step
        pts += arc_points(c, c, outer, a - step * 0.16, a + step * 0.16, 4)
        pts += arc_points(c, c, root, a + step * 0.29, a + step * 0.71, 6)
    line(d, pts + [pts[0]], w)
    r = s * 0.12
    d.ellipse([c - r, c - r, c + r, c + r], outline=WHITE, width=int(w))


def icon_undo(d, s, w, mirror=False):
    # An arrow that turns back: the head points left, the line goes right and bends round below.
    # Mirrored, the same arrow goes forward again: redo. Laid out on a grid of 24, like the other
    # stroke icons it runs from about a sixth of the size to five sixths.
    u = s / 24

    def p(x, y):
        return ((24 - x) * u if mirror else x * u, y * u)

    line(d, [p(9, 4), p(4, 9), p(9, 14)], w)
    bend = [p(14.5 + 5.5 * math.cos(math.radians(a)), 14.5 + 5.5 * math.sin(math.radians(a))) for a in range(-90, 91, 6)]
    line(d, [p(4, 9)] + bend + [p(11, 20)], w)


def icon_plus(d, s, w):
    # One more: the stepper's up.
    line(d, [(s * 0.24, s * 0.5), (s * 0.76, s * 0.5)], w)
    line(d, [(s * 0.5, s * 0.24), (s * 0.5, s * 0.76)], w)


def icon_minus(d, s, w):
    # One less: the stepper's down.
    line(d, [(s * 0.24, s * 0.5), (s * 0.76, s * 0.5)], w)


def icon_reset(d, s, w):
    # Back to the start, the preset: a circle running round anticlockwise into an arrowhead at its top
    # left. Unlike undo it goes all the way round - not one step, everything. Drawn on a grid of 24 and
    # pulled in towards the middle, so it is no bigger than the other icons.
    u = s / 24
    k = 0.85

    def p(x, y):
        return ((12 + (x - 12) * k) * u, (12 + (y - 12) * k) * u)

    ring = arc_points(12 * u, 12 * u, 9 * k * u, 180, -137, 64)
    line(d, ring + [p(3, 8)], w)
    line(d, [p(3, 3), p(3, 8), p(8, 8)], w)


# ---------------------------------------------------------------------------------------------------------
# The Arsenal's icons, and the locks' (the arsenal and locks addons use them, the gui addon holds them)
# ---------------------------------------------------------------------------------------------------------


def icon_arsenal(d, s, w):
    # A locker, the armoury of the Arsenal: the cabinet, its two doors and a handle on each.
    d.rounded_rectangle([s * 0.2, s * 0.14, s * 0.8, s * 0.86], radius=s * 0.07, outline=WHITE, width=int(w))
    line(d, [(s * 0.5, s * 0.14), (s * 0.5, s * 0.86)], w)
    line(d, [(s * 0.39, s * 0.46), (s * 0.39, s * 0.56)], w)
    line(d, [(s * 0.61, s * 0.46), (s * 0.61, s * 0.56)], w)


def icon_loadouts(d, s, w):
    # A list of saved sets: three rows, each a small square and a line.
    for k in range(3):
        y = s * (0.27 + 0.23 * k)
        d.rounded_rectangle([s * 0.18, y - s * 0.055, s * 0.29, y + s * 0.055], radius=s * 0.02, fill=WHITE)
        line(d, [(s * 0.42, y), (s * 0.82, y)], w)


def star_points(cx, cy, outer, inner, turn=-90):
    """The ten corners of a five pointed star, alternately a point and a notch."""
    pts = []
    for k in range(10):
        r = outer if k % 2 == 0 else inner
        a = math.radians(turn + k * 36)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def icon_star(d, s, w):
    # A favorite: the five pointed star, filled. Its edge is stroked as well, so its points are as round as
    # the ends of the other icons' lines.
    pts = star_points(s * 0.5, s * 0.54, s * 0.34, s * 0.15)
    d.polygon(pts, fill=WHITE)
    line(d, pts + [pts[0]], w * 0.6)


def icon_star_outline(d, s, w):
    # A star that is not a favorite (yet): the same star, only its edge.
    pts = star_points(s * 0.5, s * 0.54, s * 0.36, s * 0.16)
    line(d, pts + [pts[0]], w)


def icon_unique(d, s, w):
    # Something this arsenal does not have, only the soldier does: a diamond with a dot in it.
    c = s * 0.5
    r = s * 0.34
    line(d, [(c, c - r), (c + r, c), (c, c + r), (c - r, c), (c, c - r)], w)
    k = s * 0.07
    d.ellipse([c - k, c - k, c + k, c + k], fill=WHITE)


def eye_outline(d, s, w):
    # The almond of an eye: the upper lid and the lower lid, from corner to corner.
    left, right, y = (s * 0.12, s * 0.5), (s * 0.88, s * 0.5), s * 0.5
    upper = bezier(left, (s * 0.5, y - s * 0.46), right)
    lower = bezier(right, (s * 0.5, y + s * 0.46), left)
    line(d, upper + lower, w)


def icon_eye(d, s, w):
    # Shown: an eye with its pupil.
    eye_outline(d, s, w)
    r = s * 0.12
    d.ellipse([s * 0.5 - r, s * 0.5 - r, s * 0.5 + r, s * 0.5 + r], outline=WHITE, width=int(w))


def icon_eye_off(d, s, w):
    # Hidden: the same eye without its pupil, struck through - the bar would run through the pupil.
    eye_outline(d, s, w)
    line(d, [(s * 0.2, s * 0.82), (s * 0.8, s * 0.18)], w)


def icon_vision(d, s, w):
    # Night vision goggles from the front: the body with its two lenses, the mount on top.
    d.rounded_rectangle([s * 0.1, s * 0.32, s * 0.9, s * 0.78], radius=s * 0.1, outline=WHITE, width=int(w))
    for cx in (s * 0.31, s * 0.69):
        r = s * 0.1
        d.ellipse([cx - r, s * 0.55 - r, cx + r, s * 0.55 + r], fill=WHITE)
    line(d, [(s * 0.5, s * 0.32), (s * 0.5, s * 0.2)], w)
    line(d, [(s * 0.38, s * 0.2), (s * 0.62, s * 0.2)], w)


def tray(d, s, w, y=0.84):
    # What the text of a loadout goes into or comes out of: the floor and its two edges.
    line(d, [(s * 0.2, s * (y - 0.14)), (s * 0.2, s * y), (s * 0.8, s * y), (s * 0.8, s * (y - 0.14))], w)


def icon_import(d, s, w):
    # Into the window: an arrow down into the tray.
    line(d, [(s * 0.5, s * 0.14), (s * 0.5, s * 0.6)], w)
    line(d, [(s * 0.32, s * 0.44), (s * 0.5, s * 0.62), (s * 0.68, s * 0.44)], w)
    tray(d, s, w)


def icon_export(d, s, w):
    # Out of the window: an arrow up out of the tray.
    line(d, [(s * 0.5, s * 0.66), (s * 0.5, s * 0.2)], w)
    line(d, [(s * 0.32, s * 0.38), (s * 0.5, s * 0.2), (s * 0.68, s * 0.38)], w)
    tray(d, s, w)


def icon_share(d, s, w):
    # Three points joined: one is passed on to the others.
    a, b, c = (s * 0.28, s * 0.5), (s * 0.72, s * 0.26), (s * 0.72, s * 0.74)
    line(d, [b, a, c], w)
    r = s * 0.1
    for x, y in (a, b, c):
        d.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)


def icon_giveback(d, s, w):
    # Back into the arsenal: an arrow down into a crate, drawn as icon_crate's but lower and smaller.
    line(d, [(s * 0.5, s * 0.06), (s * 0.5, s * 0.3)], w)
    line(d, [(s * 0.36, s * 0.2), (s * 0.5, s * 0.34), (s * 0.64, s * 0.2)], w)
    cx, top, bottom = s * 0.5, s * 0.42, s * 0.94
    left, right, upper, lower = s * 0.2, s * 0.8, s * 0.56, s * 0.8
    mid = s * 0.68
    line(d, [(cx, top), (right, upper), (right, lower), (cx, bottom), (left, lower), (left, upper), (cx, top)], w)
    line(d, [(left, upper), (cx, mid), (right, upper)], w)
    line(d, [(cx, mid), (cx, bottom)], w)


def icon_blocked(d, s, w):
    # Not allowed: a ring with a bar across it.
    r = s * 0.32
    d.ellipse([s * 0.5 - r, s * 0.5 - r, s * 0.5 + r, s * 0.5 + r], outline=WHITE, width=int(w))
    k = r * 0.7
    line(d, [(s * 0.5 - k, s * 0.5 - k), (s * 0.5 + k, s * 0.5 + k)], w)


def padlock_body(d, s, w):
    # The body of a padlock on the lower half, and the keyhole in it.
    d.rounded_rectangle([s * 0.22, s * 0.46, s * 0.78, s * 0.86], radius=s * 0.08, outline=WHITE, width=int(w))
    k = s * 0.055
    d.ellipse([s * 0.5 - k, s * 0.62 - k, s * 0.5 + k, s * 0.62 + k], fill=WHITE)
    line(d, [(s * 0.5, s * 0.64), (s * 0.5, s * 0.72)], w * 0.7)


def icon_lock(d, s, w):
    # Locked: the shackle is an arch from one side of the body to the other.
    padlock_body(d, s, w)
    line(d, [(s * 0.34, s * 0.46)] + arc_points(s * 0.5, s * 0.32, s * 0.16, 180, 360) + [(s * 0.66, s * 0.46)], w)


def icon_lock_open(d, s, w):
    # Unlocked: the shackle lifted and swung to the right - fixed on the left only.
    padlock_body(d, s, w)
    line(d, [(s * 0.34, s * 0.46)] + arc_points(s * 0.5, s * 0.3, s * 0.16, 180, 330), w)


def icon_unload(d, s, w):
    # Out of its crate: a box, and below it an arrow leaving it downwards.
    d.rounded_rectangle([s * 0.2, s * 0.1, s * 0.8, s * 0.44], radius=s * 0.06, outline=WHITE, width=int(w))
    line(d, [(s * 0.5, s * 0.58), (s * 0.5, s * 0.88)], w)
    line(d, [(s * 0.34, s * 0.72), (s * 0.5, s * 0.88), (s * 0.66, s * 0.72)], w)


class Pen:
    """Draws filled shapes on a supersampled canvas in units of the texture's height: (1, 1) is the
    bottom right corner of a square texture, (2, 1) that of a wide one. erase=True cuts the shape out
    again, which is how the silhouettes get their inner lines."""

    def __init__(self, im, h):
        self.d = ImageDraw.Draw(im)
        self.u = h * SS

    def _pts(self, pts):
        return [(x * self.u, y * self.u) for x, y in pts]

    def poly(self, pts, erase=False):
        self.d.polygon(self._pts(pts), fill=CLEAR if erase else WHITE)

    def rect(self, x0, y0, x1, y1, r=0.0, erase=False):
        box = [v * self.u for v in (x0, y0, x1, y1)]
        if r > 0:
            self.d.rounded_rectangle(box, radius=r * self.u, fill=CLEAR if erase else WHITE)
        else:
            self.d.rectangle(box, fill=CLEAR if erase else WHITE)

    def ellipse(self, cx, cy, rx, ry=None, erase=False):
        ry = rx if ry is None else ry
        self.d.ellipse([(cx - rx) * self.u, (cy - ry) * self.u, (cx + rx) * self.u, (cy + ry) * self.u],
                       fill=CLEAR if erase else WHITE)

    def ring(self, cx, cy, r, w, erase=False):
        self.d.ellipse([(cx - r) * self.u, (cy - r) * self.u, (cx + r) * self.u, (cy + r) * self.u],
                       outline=CLEAR if erase else WHITE, width=round(w * self.u))

    def frame(self, x0, y0, x1, y1, r, w, erase=False):
        """The outline of a rounded rectangle, w wide."""
        self.d.rounded_rectangle([v * self.u for v in (x0, y0, x1, y1)], radius=r * self.u,
                                 outline=CLEAR if erase else WHITE, width=round(w * self.u))

    def line(self, pts, w, erase=False):
        """A polyline with round caps and joins."""
        ink = CLEAR if erase else WHITE
        pts = self._pts(pts)
        w = w * self.u
        self.d.line(pts, fill=ink, width=round(w), joint="curve")
        r = w / 2
        for x, y in (pts[0], pts[-1]):
            self.d.ellipse([x - r, y - r, x + r, y + r], fill=ink)


def bezier(p0, p1, p2, steps=24):
    """The points of a quadratic curve from p0 to p2, pulled towards p1."""
    pts = []
    for i in range(steps + 1):
        t = i / steps
        a, b, c = (1 - t) ** 2, 2 * (1 - t) * t, t * t
        pts.append((a * p0[0] + b * p1[0] + c * p2[0], a * p0[1] + b * p1[1] + c * p2[1]))
    return pts


def slot_icon(draw_fn, w=128, h=128):
    im = canvas(w, h)
    draw_fn(Pen(im, h))
    return whiten(finish(im, w, h))


# The cuts that draw a silhouette's inner lines are about 0.05 of its height wide: two pixels of a
# slot 40 pixels high, the least that still shows once the game scales the texture down.
GAP = 0.05


def slot_headgear(p):
    # A combat helmet from the side, its front to the left: a dome, the rim cut up over the ear and
    # dropping again over the neck.
    top = [(0.5 + 0.38 * math.cos(math.radians(a)), 0.62 - 0.46 * math.sin(math.radians(a))) for a in range(0, 181, 5)]
    rim = [(0.12, 0.66), (0.36, 0.66)] + bezier((0.38, 0.66), (0.52, 0.55), (0.66, 0.74)) + [(0.88, 0.74)]
    p.poly(top + rim)
    # The rail along its side.
    p.line([(0.22, 0.5), (0.8, 0.5)], GAP, erase=True)


def slot_goggles(p):
    # Glasses from the front: two lenses under one brow bar.
    for x0, x1 in ((0.1, 0.47), (0.53, 0.9)):
        p.rect(x0, 0.36, x1, 0.66, r=0.12)
    p.rect(0.08, 0.34, 0.92, 0.44, r=0.04)
    # The nose between the lenses.
    p.ellipse(0.5, 0.64, 0.07, 0.12, erase=True)


def slot_nvg(p):
    # Night vision goggles from the front: two tubes with their lenses, the mount up to the helmet.
    p.rect(0.42, 0.14, 0.58, 0.4)
    p.rect(0.32, 0.12, 0.68, 0.22, r=0.04)
    p.rect(0.2, 0.36, 0.8, 0.58, r=0.06)
    for cx in (0.3, 0.7):
        p.ellipse(cx, 0.6, 0.2)
        p.ellipse(cx, 0.6, 0.13, erase=True)
        p.ellipse(cx, 0.6, 0.075)


def slot_uniform(p):
    # A combat shirt with long sleeves, the zip down its middle.
    p.poly([
        (0.4, 0.14), (0.5, 0.26), (0.6, 0.14),  # the neck
        (0.76, 0.18), (0.86, 0.26), (0.97, 0.7), (0.82, 0.74),  # right sleeve
        (0.75, 0.48), (0.75, 0.88), (0.25, 0.88), (0.25, 0.48),  # the body
        (0.18, 0.74), (0.03, 0.7), (0.14, 0.26), (0.24, 0.18),  # left sleeve
    ])
    p.line([(0.5, 0.32), (0.5, 0.94)], GAP, erase=True)
    # The sleeves' seams, so the arms read as arms.
    p.line([(0.25, 0.48), (0.24, 0.3)], GAP, erase=True)
    p.line([(0.75, 0.48), (0.76, 0.3)], GAP, erase=True)


def slot_vest(p):
    # A plate carrier from the front: shoulder straps, the scoop for the neck, three magazine pouches.
    neck = bezier((0.39, 0.12), (0.42, 0.34), (0.61, 0.12))
    p.poly([(0.26, 0.12)] + neck + [(0.74, 0.12), (0.77, 0.3), (0.85, 0.4), (0.85, 0.88),
                                    (0.15, 0.88), (0.15, 0.4), (0.23, 0.3)])
    p.line([(0.1, 0.58), (0.9, 0.58)], GAP, erase=True)
    for x in (0.385, 0.615):
        p.line([(x, 0.58), (x, 0.95)], GAP, erase=True)


def slot_backpack(p):
    # A backpack: body, carry loop, the lid and a front pocket.
    p.rect(0.2, 0.26, 0.8, 0.9, r=0.14)
    p.line([(0.38, 0.27), (0.38, 0.14), (0.62, 0.14), (0.62, 0.27)], 0.07)
    p.line([(0.16, 0.42), (0.84, 0.42)], GAP, erase=True)
    p.frame(0.32, 0.58, 0.68, 0.96, 0.08, GAP, erase=True)


def slot_binocular(p):
    # Binoculars: two barrels, narrow at the eyepieces and wide at the lenses, joined by the hinge.
    for cx in (0.3, 0.7):
        p.rect(cx - 0.09, 0.14, cx + 0.09, 0.4, r=0.04)
        p.rect(cx - 0.15, 0.34, cx + 0.15, 0.88, r=0.08)
        p.line([(cx - 0.2, 0.74), (cx + 0.2, 0.74)], GAP, erase=True)
    p.rect(0.3, 0.42, 0.7, 0.58)


def slot_map(p):
    # A folded map: three panels, their edges up and down in turn.
    p.poly([(0.08, 0.26), (0.355, 0.18), (0.355, 0.76), (0.08, 0.84)])
    p.poly([(0.405, 0.18), (0.595, 0.24), (0.595, 0.82), (0.405, 0.76)])
    p.poly([(0.645, 0.24), (0.92, 0.16), (0.92, 0.74), (0.645, 0.82)])


def slot_gps(p):
    # A location pin.
    cx, cy, r = 0.5, 0.4, 0.27
    tip = (0.5, 0.92)
    # The pin's sides are the tangents from its tip to the circle.
    a = math.asin(r / (tip[1] - cy))
    p.ellipse(cx, cy, r)
    for side in (-1, 1):
        t = (cx + side * r * math.cos(a), cy + r * math.sin(a))
        p.poly([tip, t, (cx, cy)])
    p.ellipse(cx, cy, 0.11, erase=True)


def slot_radio(p):
    # A handheld radio: antenna, knob, display and speaker.
    p.rect(0.3, 0.06, 0.4, 0.4, r=0.05)
    p.rect(0.54, 0.18, 0.64, 0.3, r=0.02)
    p.rect(0.26, 0.28, 0.74, 0.92, r=0.08)
    p.rect(0.35, 0.37, 0.65, 0.53, r=0.03, erase=True)
    for y in (0.64, 0.72, 0.8):
        p.line([(0.37, y), (0.63, y)], GAP * 0.9, erase=True)


def slot_compass(p):
    # A compass: the case, its ring to hang it from, a needle pointing north-east.
    c = (0.5, 0.56)
    p.ring(c[0], c[1], 0.36, 0.08)
    p.ring(0.5, 0.13, 0.065, 0.045)
    d = math.sqrt(0.5)
    tip, back, wide = 0.25, 0.25, 0.08
    north = (c[0] + d * tip, c[1] - d * tip)
    south = (c[0] - d * back, c[1] + d * back)
    left = (c[0] - d * wide, c[1] - d * wide)
    right = (c[0] + d * wide, c[1] + d * wide)
    p.poly([north, right, south, left])
    # Only the north half is solid, as on a real needle: the south half keeps just its outline.
    half = (right, south, left)
    g = (sum(v[0] for v in half) / 3, sum(v[1] for v in half) / 3)
    p.poly([(g[0] + (v[0] - g[0]) * 0.45, g[1] + (v[1] - g[1]) * 0.45) for v in half], erase=True)


def slot_watch(p):
    # A wristwatch: strap, face, hands and crown.
    p.rect(0.37, 0.06, 0.63, 0.94, r=0.06)
    p.ellipse(0.5, 0.5, 0.29)
    p.ellipse(0.5, 0.5, 0.2, erase=True)
    p.rect(0.77, 0.45, 0.84, 0.55, r=0.02)
    p.line([(0.5, 0.5), (0.5, 0.37)], 0.06)
    p.line([(0.5, 0.5), (0.6, 0.55)], 0.06)


def slot_muzzle(p):
    # A suppressor on the end of a barrel. Without the barrel it reads as a battery.
    p.rect(0.04, 0.38, 0.72, 0.62, r=0.05)
    p.rect(0.7, 0.42, 0.8, 0.58)
    p.rect(0.78, 0.455, 1.0, 0.545)
    p.line([(0.7, 0.3), (0.7, 0.7)], GAP, erase=True)
    for x in (0.15, 0.24):
        p.line([(x, 0.3), (x, 0.7)], GAP, erase=True)


def slot_optic(p):
    # A rifle scope from the side: the lens bell forward (left), turret on top, rings and their base.
    p.rect(0.2, 0.39, 0.8, 0.51)
    p.poly([(0.06, 0.29), (0.16, 0.29), (0.3, 0.38), (0.3, 0.52), (0.16, 0.61), (0.06, 0.61)])
    p.poly([(0.94, 0.32), (0.84, 0.32), (0.72, 0.39), (0.72, 0.51), (0.84, 0.58), (0.94, 0.58)])
    p.rect(0.43, 0.26, 0.57, 0.4, r=0.02)
    for x in (0.33, 0.6):
        p.rect(x, 0.5, x + 0.08, 0.66)
    p.rect(0.26, 0.64, 0.74, 0.74, r=0.02)


def slot_rail(p):
    # A weapon light on its rail clamp, shining to the left.
    p.rect(0.26, 0.32, 0.46, 0.64, r=0.04)
    p.rect(0.44, 0.38, 0.88, 0.58, r=0.05)
    p.rect(0.52, 0.56, 0.8, 0.7, r=0.02)
    p.line([(0.46, 0.32), (0.46, 0.64)], GAP, erase=True)
    for a, b in (((0.18, 0.48), (0.06, 0.48)), ((0.19, 0.36), (0.09, 0.26)), ((0.19, 0.6), (0.09, 0.7))):
        p.line([a, b], 0.06)


def slot_bipod(p):
    # A bipod from the front: the clamp, two legs splayed out, a foot on each.
    p.rect(0.36, 0.12, 0.64, 0.28, r=0.04)
    for side in (-1, 1):
        top = (0.5 + side * 0.07, 0.24)
        knee = (0.5 + side * 0.2, 0.55)
        foot = (0.5 + side * 0.32, 0.84)
        p.line([top, knee], 0.11)
        p.line([knee, foot], 0.07)
        p.rect(foot[0] - 0.09, 0.82, foot[0] + 0.09, 0.9, r=0.04)


def slot_magazine(p):
    # A curved rifle magazine, the top round lying on it pointing forward (left).
    front = bezier((0.38, 0.27), (0.37, 0.56), (0.27, 0.8))
    rear = bezier((0.64, 0.27), (0.63, 0.58), (0.51, 0.9))
    p.poly(front + rear[::-1])
    # The base plate sits square across the curve's end, a little wider than the body; the rib along
    # the side is what tells a magazine from a plain bent bar.
    p.line([(0.24, 0.785), (0.54, 0.91)], 0.09)
    p.line(bezier((0.475, 0.34), (0.47, 0.56), (0.4, 0.72), 12), GAP, erase=True)
    # The round: brass case, then the bullet's point.
    p.rect(0.44, 0.12, 0.66, 0.21, r=0.015)
    p.poly(bezier((0.43, 0.12), (0.3, 0.12), (0.23, 0.165)) + bezier((0.23, 0.165), (0.3, 0.21), (0.43, 0.21)))
    p.line([(0.435, 0.08), (0.435, 0.25)], 0.03, erase=True)


def slot_grenade(p):
    # A fragmentation grenade: body, fuse, spoon and pin ring.
    p.ellipse(0.46, 0.62, 0.25, 0.28)
    p.rect(0.36, 0.2, 0.56, 0.38, r=0.03)
    # The spoon stands off the body by a gap, so it reads as its own part.
    p.line([(0.5, 0.22), (0.7, 0.24), (0.78, 0.38), (0.77, 0.6)], 0.06 + 2 * GAP, erase=True)
    p.line([(0.5, 0.22), (0.7, 0.24), (0.78, 0.38), (0.77, 0.6)], 0.06)
    p.ring(0.25, 0.22, 0.09, 0.045)


def slot_handgun(p):
    # A pistol from the side, its muzzle to the left.
    p.rect(0.08, 0.26, 0.86, 0.44, r=0.03)
    p.rect(0.12, 0.42, 0.84, 0.52)
    p.poly([(0.6, 0.5), (0.84, 0.48), (0.92, 0.86), (0.68, 0.88)])
    p.line([(0.6, 0.5), (0.58, 0.64), (0.42, 0.64), (0.4, 0.5)], 0.05)
    # The slide's edge, and its grip serrations.
    p.line([(0.04, 0.44), (0.9, 0.44)], GAP * 0.8, erase=True)
    for x in (0.7, 0.77):
        p.line([(x, 0.3), (x, 0.39)], GAP * 0.8, erase=True)


def slot_rifle(p):
    # An assault rifle from the side, its muzzle to the left (a 2:1 texture, so x runs to 2).
    p.rect(0.04, 0.4, 0.16, 0.5, r=0.02)  # muzzle device
    p.rect(0.1, 0.42, 0.5, 0.48)  # barrel
    p.rect(0.44, 0.35, 0.94, 0.53, r=0.03)  # handguard
    p.rect(0.9, 0.33, 1.38, 0.54, r=0.02)  # receiver
    p.rect(0.5, 0.31, 1.34, 0.36)  # top rail
    p.rect(1.02, 0.19, 1.24, 0.29, r=0.04)  # sight
    p.rect(1.08, 0.27, 1.18, 0.33)
    p.poly([(1.0, 0.52), (1.14, 0.52), (1.08, 0.88), (0.92, 0.85)])  # magazine
    p.poly([(1.27, 0.52), (1.38, 0.52), (1.46, 0.86), (1.34, 0.88)])  # grip
    p.line([(1.15, 0.56), (1.17, 0.66), (1.29, 0.66)], 0.04)  # trigger guard
    p.rect(1.34, 0.37, 1.62, 0.47)  # buffer tube
    p.poly([(1.52, 0.35), (1.94, 0.35), (1.96, 0.39), (1.96, 0.74), (1.86, 0.74), (1.58, 0.52), (1.52, 0.52)])  # stock
    p.line([(0.9, 0.3), (0.9, 0.6)], GAP, erase=True)


def slot_launcher(p):
    # A rocket launcher from the side, the warhead to the left (a 2:1 texture, so x runs to 2).
    p.poly([(0.04, 0.5), (0.14, 0.39), (0.3, 0.32), (0.4, 0.33), (0.48, 0.42),
            (0.48, 0.58), (0.4, 0.67), (0.3, 0.68), (0.14, 0.61)])
    p.rect(0.46, 0.42, 1.84, 0.58)  # tube
    p.poly([(1.76, 0.42), (1.96, 0.33), (1.96, 0.67), (1.76, 0.58)])  # blast cone
    p.rect(0.86, 0.38, 1.34, 0.62, r=0.03)  # heat shield
    p.rect(1.02, 0.24, 1.16, 0.38, r=0.02)  # sight
    p.line([(1.0, 0.6), (0.97, 0.84)], 0.08)  # front grip
    p.line([(1.38, 0.6), (1.45, 0.86)], 0.09)  # rear grip
    p.line([(0.48, 0.3), (0.48, 0.7)], GAP, erase=True)


def toggle(on, w=128, h=64):
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = w * SS, h * SS
    pad = H * 0.08
    d.rounded_rectangle([pad, pad, W - pad, H - pad], radius=(H - 2 * pad) / 2, fill=ACCENT if on else TRACK_OFF)
    r = (H - 2 * pad) / 2 - H * 0.1
    cy = H / 2
    cx = W - pad - (H - 2 * pad) / 2 if on else pad + (H - 2 * pad) / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=KNOB_ON if on else KNOB_OFF)
    return finish(im, w, h)


def toggle_track(w=128, h=64):
    """The on state's track alone, white, so the game tints it with the player's accent."""
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = w * SS, h * SS
    pad = H * 0.08
    d.rounded_rectangle([pad, pad, W - pad, H - pad], radius=(H - 2 * pad) / 2, fill=WHITE)
    return whiten(finish(im, w, h))


def toggle_knob(w=128, h=64):
    """The on state's knob alone, white, at the right end - drawn over the tinted track."""
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    W, H = w * SS, h * SS
    pad = H * 0.08
    r = (H - 2 * pad) / 2 - H * 0.1
    cy = H / 2
    cx = W - pad - (H - 2 * pad) / 2
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    return whiten(finish(im, w, h))


def scroll_thumb(w=32, h=256):
    """A scroll bar's thumb: a slim bar with round ends in the middle of the bar's width. The game
    stretches it to the thumb's length, so its ends are drawn a little flat to come out round."""
    im = canvas(w, h)
    d = ImageDraw.Draw(im)
    bar = w * SS * 0.4
    x0 = (w * SS - bar) / 2
    d.rounded_rectangle([x0, SS * 3, x0 + bar, h * SS - SS * 3], radius=bar / 2, fill=WHITE)
    return finish(im, w, h)


def circle(size=128):
    """A filled circle from edge to edge, so the badge is exactly the control's rectangle."""
    im = canvas(size, size)
    ImageDraw.Draw(im).ellipse([0, 0, size * SS - 1, size * SS - 1], fill=WHITE)
    return whiten(finish(im, size, size))


def cursor_ring(size=128):
    """The cursor of the palette picker's colour square and hue strip (fnc_openPaletteMenu): a white ring with a dark rim inside and out,
    so it reads on every colour from white to black, and the colour under it shows through the hole. Drawn in colour - the game
    does not tint it."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    s = size * SS
    mid = s / 2
    rim = (0, 0, 0, 200)
    # Outside in: dark rim, the white band, dark rim, the hole. Each ellipse replaces what lies under it.
    for r, fill in ((0.50, rim), (0.44, WHITE), (0.34, rim), (0.28, CLEAR)):
        d.ellipse([mid - r * s, mid - r * s, mid + r * s - 1, mid + r * s - 1], fill=fill)
    return finish(im, size, size)


def hue_vstrip(w=16, h=256):
    """Every hue from red round to red, top to bottom, fully lit: the strip beside the colour square of the palette's
    picker (fnc_openPaletteMenu). The last row is one step short of red again, as the picker's hue goes from 0 to
    359/360 so the end of the strip is not a jump. Drawn in colour - the game stretches it over the strip and does not tint it."""
    import colorsys
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for y in range(h):
        r, g, b = colorsys.hsv_to_rgb(y / h, 1.0, 1.0)
        for x in range(w):
            px[x, y] = (round(r * 255), round(g * 255), round(b * 255), 255)
    return im


def fade_strip(w=256, h=16):
    """White that fades out from left to right. Laid over a panel of a pure hue and stretched over it, it makes the
    saturation across the palette picker's colour square: white at the left, the full colour at the right
    (fnc_openPaletteMenu); the shade strip below does the value."""
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for x in range(w):
        for y in range(h):
            px[x, y] = (255, 255, 255, round(255 * (1 - x / (w - 1))))
    return im


def shade_strip(w=16, h=256):
    """Black that fades in from top to bottom: nothing at the top, solid at the bottom. Laid over the white fade above, it makes the
    value down the palette picker's colour square: the colour at the top, black at the bottom (fnc_openPaletteMenu)."""
    im = Image.new("RGBA", (w, h))
    px = im.load()
    for y in range(h):
        for x in range(w):
            px[x, y] = (0, 0, 0, round(255 * y / (h - 1)))
    return im


def hatch(size=256, stripes=8, duty=0.32):
    """Diagonal stripes, bottom left to top right, for Tarkov's empty slots and hidden tiles. A
    whole number of stripes fits across, so the texture tiles without a seam."""
    im = canvas(size, size)
    d = ImageDraw.Draw(im)
    s = size * SS
    period = s / stripes
    band = period * duty  # the stripe's width, measured along a row
    # Each stripe is the band x + y = c .. c + band, drawn on past the texture's sides: the edges cut
    # it, and the next tile carries it on.
    for k in range(-1, 2 * stripes + 2):
        c = k * period
        d.polygon([(c - s, s), (c - s + band, s), (c + band, 0), (c, 0)], fill=WHITE)
    return whiten(finish(im, size, size))


def soldier(w=512, h=1024):
    """A soldier standing, seen from the front, filled - Tarkov draws one faintly behind the gear
    slots. Built from round limbs, then blurred and cut at half so the joints melt into one body."""
    ss = 4  # the blur makes the edges smooth already, and 8 times this size would be slow
    W, H = w * ss, h * ss
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)

    def pt(x, y):
        return x * H, y * H  # in units of the height, the centre line at x = 0.25

    def limb(a, ra, b, rb):
        """A tapered limb: two round ends and the band between them."""
        (ax, ay), (bx, by) = pt(*a), pt(*b)
        ra, rb = ra * H, rb * H
        d.ellipse([ax - ra, ay - ra, ax + ra, ay + ra], fill=255)
        d.ellipse([bx - rb, by - rb, bx + rb, by + rb], fill=255)
        length = math.hypot(bx - ax, by - ay)
        nx, ny = -(by - ay) / length, (bx - ax) / length
        d.polygon([(ax + nx * ra, ay + ny * ra), (bx + nx * rb, by + ny * rb),
                   (bx - nx * rb, by - ny * rb), (ax - nx * ra, ay - ny * ra)], fill=255)

    c = 0.25
    # Head under a helmet that comes down over the ears, neck.
    d.ellipse([*pt(c - 0.04, 0.07), *pt(c + 0.04, 0.165)], fill=255)
    d.ellipse([*pt(c - 0.06, 0.028), *pt(c + 0.06, 0.142)], fill=255)
    limb((c, 0.15), 0.024, (c, 0.19), 0.028)
    # The torso in a vest: sloping shoulders, chest, the waist with its belt, hips.
    right = [(0.05, 0.178), (0.1, 0.192), (0.115, 0.215), (0.106, 0.3), (0.092, 0.44), (0.1, 0.53)]
    d.polygon([pt(c + x, y) for x, y in right] + [pt(c - x, y) for x, y in right[::-1]], fill=255)
    for side in (-1, 1):
        # The arms hang a little away from the body, so they read as arms down to the armpit.
        limb((c + side * 0.108, 0.228), 0.036, (c + side * 0.158, 0.385), 0.029)  # upper arm
        limb((c + side * 0.158, 0.385), 0.027, (c + side * 0.172, 0.52), 0.02)  # forearm
        d.ellipse([*pt(c + side * 0.173 - 0.021, 0.515), *pt(c + side * 0.173 + 0.021, 0.6)], fill=255)  # hand
        limb((c + side * 0.055, 0.53), 0.05, (c + side * 0.06, 0.71), 0.034)  # thigh
        limb((c + side * 0.06, 0.71), 0.033, (c + side * 0.064, 0.92), 0.024)  # shin
        # The boot, its toe a little out to the side.
        d.polygon([pt(c + side * 0.04, 0.91), pt(c + side * 0.088, 0.91), pt(c + side * 0.1, 0.975),
                   pt(c + side * 0.036, 0.975)], fill=255)

    # Melt the pieces together; the cut at half keeps the outline where it was drawn.
    mask = mask.filter(ImageFilter.GaussianBlur(H * 0.004))
    mask = mask.point(lambda v: 255 if v >= 128 else 0)
    im = Image.merge("RGBA", (Image.new("L", (W, H), 255),) * 3 + (mask,))
    return im.resize((w, h), Image.LANCZOS)


def gloss(tex_w, tex_h, width, height, radius, screen_h):
    """The sheen on a window's glass: light along the top that fades out, and a thin light edge.

    width, height and radius are the window's size in its own rows (see defines.hpp), screen_h its
    height in pixels at 1080p. Drawn at the window's true shape, then squeezed into a power-of-two
    texture - the game stretches it back over the window, so the corners come out round.
    """
    scale = 4096 / max(width, height)
    w, h = round(width * scale), round(height * scale)
    r = radius * scale
    px = h / screen_h  # one screen pixel, in drawing pixels

    shape = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shape).rounded_rectangle([0, 0, w - 1, h - 1], radius=r, fill=255)
    inner = Image.new("L", (w, h), 0)
    edge = 1.2 * px
    ImageDraw.Draw(inner).rounded_rectangle([edge, edge, w - 1 - edge, h - 1 - edge], radius=max(r - edge, 0), fill=255)

    # The sheen over the top of the window, and the edge brighter at the top than at the bottom - each
    # a column of alpha, spread over the width.
    sheen_h = min(h * 0.5, 7.5 * scale)
    sheen = Image.new("L", (1, h))
    rim = Image.new("L", (1, h))
    for y in range(h):
        sheen.putpixel((0, y), round(255 * 0.055 * max(0.0, 1 - y / sheen_h) ** 1.6))
        rim.putpixel((0, y), round(255 * (0.16 - 0.1 * y / h)))
    sheen = sheen.resize((w, h), Image.NEAREST)
    rim = rim.resize((w, h), Image.NEAREST)

    ring = ImageChops.subtract(shape, inner)
    alpha = ImageChops.add(ImageChops.multiply(sheen, inner), ImageChops.multiply(rim, ring))

    im = Image.merge("RGBA", (Image.new("L", (w, h), 255),) * 3 + (alpha,))
    return im.resize((tex_w, tex_h), Image.LANCZOS)


def slot_cat_all(p):
    # "All": four tiles of a grid, the way the loot strip's first button says "no filter".
    for x0, y0 in ((0.14, 0.14), (0.54, 0.14), (0.14, 0.54), (0.54, 0.54)):
        p.rect(x0, y0, x0 + 0.32, y0 + 0.32, r=0.06)


def slot_cat_medical(p):
    # A thick cross.
    p.rect(0.38, 0.12, 0.62, 0.88, r=0.05)
    p.rect(0.12, 0.38, 0.88, 0.62, r=0.05)


def slot_cat_food(p):
    # A fork and a knife side by side: the fork's tines are cut into its head.
    p.rect(0.13, 0.1, 0.43, 0.42, r=0.04)
    p.rect(0.2, 0.4, 0.36, 0.9, r=0.05)
    for x in (0.2, 0.28, 0.36):
        p.line([(x, 0.06), (x, 0.3)], 0.03, erase=True)
    p.poly([(0.58, 0.08), (0.8, 0.24), (0.8, 0.54), (0.58, 0.54)])
    p.rect(0.6, 0.5, 0.78, 0.9, r=0.05)


def slot_cat_misc(p):
    # Three dots: "everything else".
    for x in (0.2, 0.5, 0.8):
        p.ellipse(x, 0.5, 0.11)


def build_images():
    """Every texture by its file name, as Pillow images."""
    images = {"search_ring_%02d_ca" % k: search_ring(k) for k in range(1, SEARCH_FRAMES + 1)}
    images.update({
        "corner_tl_ca": corner("tl"),
        "corner_tr_ca": corner("tr"),
        "corner_bl_ca": corner("bl"),
        "corner_br_ca": corner("br"),
        "ring_tl_ca": ring_corner("tl"),
        "ring_tr_ca": ring_corner("tr"),
        "ring_bl_ca": ring_corner("bl"),
        "ring_br_ca": ring_corner("br"),
        "icon_close_ca": stroke_icon(icon_close),
        "icon_search_ca": stroke_icon(icon_search),
        "icon_sort_asc_ca": stroke_icon(lambda d, s, w: icon_sort(d, s, w, True)),
        "icon_sort_desc_ca": stroke_icon(lambda d, s, w: icon_sort(d, s, w, False)),
        "icon_chevron_right_ca": stroke_icon(lambda d, s, w: chevron(d, s, w, "right")),
        "icon_chevron_left_ca": stroke_icon(lambda d, s, w: chevron(d, s, w, "left")),
        "icon_chevron_down_ca": stroke_icon(lambda d, s, w: chevron(d, s, w, "down")),
        "icon_chevrons_right_ca": stroke_icon(lambda d, s, w: (chevron(d, s, w, "right", -0.1), chevron(d, s, w, "right", 0.1))),
        "icon_chevrons_left_ca": stroke_icon(lambda d, s, w: (chevron(d, s, w, "left", -0.1), chevron(d, s, w, "left", 0.1))),
        "icon_inventory_ca": stroke_icon(icon_inventory),
        "icon_crate_ca": stroke_icon(icon_crate),
        "icon_ground_ca": stroke_icon(icon_ground),
        "icon_check_ca": stroke_icon(icon_check),
        "icon_auto_ca": stroke_icon(icon_auto),
        "icon_person_ca": stroke_icon(icon_person),
        "icon_swap_ca": stroke_icon(icon_swap),
        "icon_camera_ca": stroke_icon(icon_camera),
        "icon_sound_on_ca": stroke_icon(icon_sound_on),
        "icon_sound_off_ca": stroke_icon(icon_sound_off),
        "icon_style_ca": stroke_icon(icon_style),
        "icon_palette_ca": stroke_icon(icon_palette),
        "icon_weight_ca": stroke_icon(icon_weight),
        # The setup wizard: its cog in the inventory's header and in Eden's Tools menu, and its controls.
        "icon_setup_ca": stroke_icon(icon_setup),
        "icon_undo_ca": stroke_icon(icon_undo),
        "icon_redo_ca": stroke_icon(lambda d, s, w: icon_undo(d, s, w, mirror=True)),
        "icon_plus_ca": stroke_icon(icon_plus),
        "icon_minus_ca": stroke_icon(icon_minus),
        "icon_reset_ca": stroke_icon(icon_reset),
        # The Arsenal's icons and the locks'.
        "icon_arsenal_ca": stroke_icon(icon_arsenal),
        "icon_loadouts_ca": stroke_icon(icon_loadouts),
        "icon_star_ca": stroke_icon(icon_star),
        "icon_star_outline_ca": stroke_icon(icon_star_outline),
        "icon_unique_ca": stroke_icon(icon_unique),
        "icon_eye_ca": stroke_icon(icon_eye),
        "icon_eye_off_ca": stroke_icon(icon_eye_off),
        "icon_vision_ca": stroke_icon(icon_vision),
        "icon_import_ca": stroke_icon(icon_import),
        "icon_export_ca": stroke_icon(icon_export),
        "icon_share_ca": stroke_icon(icon_share),
        "icon_giveback_ca": stroke_icon(icon_giveback),
        "icon_blocked_ca": stroke_icon(icon_blocked),
        "icon_lock_ca": stroke_icon(icon_lock),
        "icon_lock_open_ca": stroke_icon(icon_lock_open),
        "icon_unload_ca": stroke_icon(icon_unload),
        "toggle_on_ca": toggle(True),
        "toggle_off_ca": toggle(False),
        "toggle_track_ca": toggle_track(),
        "toggle_knob_ca": toggle_knob(),
        "scroll_thumb_ca": scroll_thumb(),
        "circle_ca": circle(),
        "cursor_ring_ca": cursor_ring(),
        "hue_vstrip_ca": hue_vstrip(),
        "fade_strip_ca": fade_strip(),
        "shade_strip_ca": shade_strip(),
        "hatch_ca": hatch(),
        "silhouette_ca": soldier(),
        "slot_headgear_ca": slot_icon(slot_headgear),
        "slot_goggles_ca": slot_icon(slot_goggles),
        "slot_nvg_ca": slot_icon(slot_nvg),
        "slot_uniform_ca": slot_icon(slot_uniform),
        "slot_vest_ca": slot_icon(slot_vest),
        "slot_backpack_ca": slot_icon(slot_backpack),
        "slot_binocular_ca": slot_icon(slot_binocular),
        "slot_map_ca": slot_icon(slot_map),
        "slot_gps_ca": slot_icon(slot_gps),
        "slot_radio_ca": slot_icon(slot_radio),
        "slot_compass_ca": slot_icon(slot_compass),
        "slot_watch_ca": slot_icon(slot_watch),
        "slot_muzzle_ca": slot_icon(slot_muzzle),
        "slot_optic_ca": slot_icon(slot_optic),
        "slot_rail_ca": slot_icon(slot_rail),
        "slot_bipod_ca": slot_icon(slot_bipod),
        "slot_magazine_ca": slot_icon(slot_magazine),
        "slot_grenade_ca": slot_icon(slot_grenade),
        "slot_handgun_ca": slot_icon(slot_handgun),
        "slot_rifle_ca": slot_icon(slot_rifle, 256, 128),
        "slot_launcher_ca": slot_icon(slot_launcher, 256, 128),
        # The strip of categories at the side of a loot box (fnc_drawGroupStrip); the weapon, magazine, vest and radio
        # pictures above stand for weapons, ammunition, gear and tools.
        "slot_cat_all_ca": slot_icon(slot_cat_all),
        "slot_cat_medical_ca": slot_icon(slot_cat_medical),
        "slot_cat_food_ca": slot_icon(slot_cat_food),
        "slot_cat_misc_ca": slot_icon(slot_cat_misc),
        # The window's glass, for its shape on a wide screen: INV_W x INV_VISIBLE_H in rows of
        # INV_H / 37, where INV_W is 33 cells of 1.5 rows (addons/gui/defines.hpp).
        "gloss_inventory_ca": gloss(1024, 1024, 33 * 1.5, 36, 0.6, 36 * 0.95 * 1080 / 37),
    })
    return images


def main():
    # Usage: generate_ui_textures.py [path to ImageToPAA] [--only name,name] - with --only just those textures are
    # made again, so a new picture does not rewrite every other file (a texture is a binary: each would show as changed).
    args = sys.argv[1:]
    only = None

    if "--only" in args:
        at = args.index("--only")
        only = set(args[at + 1].split(","))
        del args[at:at + 2]

    tool = args[0] if args else IMAGE_TO_PAA
    if not os.path.isfile(tool):
        raise SystemExit("ImageToPAA not found: %s" % tool)

    images = build_images()
    if only is not None:
        missing = only - set(images)
        if missing:
            raise SystemExit("Unknown textures: %s" % ", ".join(sorted(missing)))
        images = {name: im for name, im in images.items() if name in only}
    os.makedirs(OUT, exist_ok=True)
    tmp = tempfile.mkdtemp()
    for name, im in images.items():
        png = os.path.join(tmp, name + ".png")
        im.save(png)
        paa = os.path.join(OUT, name + ".paa")
        subprocess.run([tool, png, paa], check=True, capture_output=True)
        if not os.path.isfile(paa):
            raise SystemExit("ImageToPAA made nothing for " + name)
    print("%d textures written to %s" % (len(images), os.path.normpath(OUT)))


if __name__ == "__main__":
    main()
