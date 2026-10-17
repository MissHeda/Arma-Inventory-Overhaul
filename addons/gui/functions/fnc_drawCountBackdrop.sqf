#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A backdrop for a number that stands over a picture (the tiles, fnc_createTile; the slots, fnc_drawSlot).
 * The number is light, so on a light picture - a vial, a bandage - it vanishes, and a colour of its own
 * would vanish on some other item. It gets a box of its own instead, of one of two kinds:
 *   a pill - a magazine's "17/30": the theme's tileCountBg, dark and mostly see-through, with round ends
 *            where the theme has round corners and square in a square look
 *   flat   - a stack's "3/10" and a hotbar slot's count: a small square box in the theme's raised colour,
 *            the grey box Arma's inventory mods put in a tile's corner, so a stack reads at a glance
 * A theme with that colour [] has none, and the number stands on the picture as before.
 *
 * The box ends at the given corner - the bottom right one, or the bottom left one when asked - and is as
 * wide as the text asks for, never wider than the room the caller has - it neither grows the tile nor
 * reaches into the next. The caller draws the number centred in the rectangle it gets back, in the theme's
 * tileCountColor. A label cannot resize its backdrop, so the caller passes the widest text the number can
 * become (a repack of magazines changes the rounds live, einv_magazines_fnc_drawJob).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The widest text the number can become <STRING>
 * 3: Font <STRING>
 * 4: Font size, as a height <NUMBER>
 * 5: Where the box's right edge is - its left edge when it starts from the left -, screen x <NUMBER>
 * 6: Where the box's bottom edge is, screen y <NUMBER>
 * 7: The most width it may take <NUMBER>
 * 8: Theme <HASHMAP>
 * 9: Flat - a stack's box, not a pill <BOOL> (default: false)
 * 10: From the left - argument 5 is its left edge <BOOL> (default: false)
 * 11: Only measure - no control is made: the caller's label, which lies on exactly the box's rectangle, takes
 *     the colour as its own background. Only for a flat box, which is square in every look; one control
 *     instead of two per stack on the window <BOOL> (default: false)
 *
 * Return Value:
 * [Controls, Rectangle [x, y, w, h] for the number, the box's colour] - all empty for a theme without a
 * backdrop; no controls when only measured <ARRAY>
 *
 * Example:
 * [_display, _parent, "30/30", "PuristaSemibold", 0.012, 0.5, 0.4, 0.05, _theme] call einv_gui_fnc_drawCountBackdrop;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_text", "_font", "_size", "_right", "_bottom", "_maxW", "_theme", ["_flat", false], ["_fromLeft", false], ["_measure", false]];

private _color = if (_flat) then {
    _theme getOrDefault ["raised", _theme getOrDefault ["tileCountBg", []]]
} else {
    _theme getOrDefault ["tileCountBg", []]
};

if (_color isEqualTo []) exitWith {[[], [], []]};

// The flat box hugs its text: small, so it covers little of the picture.
private _height = _size * ([1.3, 1.15] select _flat);
private _pad = _height * ([0.5, 0.35] select _flat);
private _width = (((_text getTextWidth [_font, _size]) * TEXT_SLACK + SQUARE(_pad)) max SQUARE(_height)) min _maxW;
private _rect = [[_right - _width, _right] select _fromLeft, _bottom - _height, _width, _height];

// Round ends only on a pill where the theme has round corners; a square look keeps its count box square,
// and the flat box is square in every look.
private _radius = [0, _height / 2] select (!_flat && {(_theme getOrDefault ["radius", 0]) > 0});

// A square box measured only: the label made on the same rectangle is snapped to the same pixels
// (fnc_uiCreate, as fnc_uiPanel snaps it) and draws the colour behind its text itself.
if (_measure && {_radius == 0}) exitWith {[[], _rect, _color]};

[[_display, _parent, _rect, _color, _radius] call FUNC(uiPanel), _rect, _color]
