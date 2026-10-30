#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Runs a surface - a bar's fill, a button, a header button's line - from the gradient's start into its end, left to right, where
 * the colour panel switched that part on (the Text row's parts, GRADIENT_BARS, GRADIENT_CHIPS, GRADIENT_LINES): the surface
 * takes the end colour, and a fade in the start colour lies over it, strong at the left and gone at the right. Its colours are the
 * part's own where it has them, else the main gradient's (the Titles row: its colour, else the accent, into its end), as for the
 * texts (fnc_uiLabel). The fade keeps a corner's width in from the left and right edges, where a round surface has straight top
 * and bottom edges, so no square corner shows. Only on the inventory's window, never in a layer that asks for plain controls
 * (the colour and sound panels, QGVAR(plain)).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group, or controlNull for the display <CONTROL>
 * 2: The surface's place [x, y, w, h] <ARRAY>
 * 3: The part, a GRADIENT_* <NUMBER>
 * 4: The surface's controls (fnc_uiPanel) <ARRAY>
 * 5: Its alpha <NUMBER>
 * 6: Its corner radius, as a height <NUMBER> (default: 0)
 *
 * Return Value:
 * The fade, or controlNull where the part runs plain <CONTROL>
 *
 * Example:
 * [_display, _parent, _rect, GRADIENT_BARS, _fillParts, 1, _radius] call einv_gui_fnc_gradientSurface;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_bit", 0, [0]], ["_surface", [], [[]]], ["_alpha", 1, [0]], ["_radius", 0, [0]]];

if (_bit <= 0 || {_display isNotEqualTo (uiNamespace getVariable [QGVAR(display), displayNull])}) exitWith {controlNull};
if (!isNull _parent && {_parent getVariable [QGVAR(plain), false]}) exitWith {controlNull};

private _theme = missionNamespace getVariable [QGVAR(theme), createHashMap];

if (((floor ((_theme getOrDefault ["gradientParts", GRADIENT_PARTS_DEFAULT]) / _bit)) mod 2) == 0) exitWith {controlNull};

// The part's own start and end, else the main gradient's.
private _own = (_theme getOrDefault ["gradientOwn", []]) param [round (log _bit / log 2), [[], []]];
private _end = (_own param [1, []]) select [0, 3];

if (count _end < 3) then {
    _end = (_theme getOrDefault ["titleGradient", []]) select [0, 3];
};

if (count _end < 3) exitWith {controlNull};

private _start = (_own param [0, []]) select [0, 3];

if (count _start < 3) then {
    _start = (_theme getOrDefault ["titleColor", []]) select [0, 3];
};

if (count _start < 3) then {
    _start = (_theme getOrDefault ["accent", [1, 1, 1, 1]]) select [0, 3];
};

[_surface, _end + [_alpha]] call FUNC(paintSurface);

_rect params ["_left", "_top", "_width", "_height"];

private _inset = SQUARE(_radius min (_height / 2));

if (_width - _inset * 2 < pixelW) exitWith {controlNull};

private _fade = [_display, "EINV_PanelCorner", _parent, [_left + _inset, _top, _width - _inset * 2, _height]] call FUNC(uiCreate);

_fade ctrlSetText UI_TEX(fade_strip_ca);
_fade ctrlSetTextColor (_start + [_alpha]);

_fade
