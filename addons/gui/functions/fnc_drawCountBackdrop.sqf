#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A dark backdrop for a number that stands over a picture - a stack's count, a magazine's "17/17" (the
 * tiles, fnc_createTile; the slots, fnc_drawSlot). The number is light, so on a light picture - a vial, a
 * bandage - it vanishes, and a colour of its own would vanish on some other item. It gets a small pill
 * instead: the theme's tileCountBg, dark and mostly see-through, with round ends where the theme has round
 * corners and square in a square look. A theme with tileCountBg [] has none, and the number stands on the
 * picture as before.
 *
 * The pill ends at the given corner and is as wide as the text asks for, never wider than the room the
 * caller has - it neither grows the tile nor reaches into the next. The caller draws the number centred in
 * the rectangle it gets back, in the theme's tileCountColor. A label cannot resize its backdrop, so the
 * caller passes the widest text the number can become (a repack of magazines changes the rounds live,
 * einv_magazines_fnc_drawJob).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: The widest text the number can become <STRING>
 * 3: Font <STRING>
 * 4: Font size, as a height <NUMBER>
 * 5: Where the pill's right edge is, screen x <NUMBER>
 * 6: Where the pill's bottom edge is, screen y <NUMBER>
 * 7: The most width it may take <NUMBER>
 * 8: Theme <HASHMAP>
 *
 * Return Value:
 * [Controls, Rectangle [x, y, w, h] for the number] - both empty for a theme without a backdrop <ARRAY>
 *
 * Example:
 * [_display, _parent, "30/30", "PuristaSemibold", 0.012, 0.5, 0.4, 0.05, _theme] call einv_gui_fnc_drawCountBackdrop;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_text", "_font", "_size", "_right", "_bottom", "_maxW", "_theme"];

private _color = _theme getOrDefault ["tileCountBg", []];

if (_color isEqualTo []) exitWith {[[], []]};

private _height = _size * 1.3;
private _width = (((_text getTextWidth [_font, _size]) * TEXT_SLACK + SQUARE(_height * 0.5)) max SQUARE(_height)) min _maxW;
private _rect = [_right - _width, _bottom - _height, _width, _height];

// Round ends only where the theme has round corners; a square look keeps its count box square.
private _radius = [0, _height / 2] select ((_theme getOrDefault ["radius", 0]) > 0);

[[_display, _parent, _rect, _color, _radius] call FUNC(uiPanel), _rect]
