#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The outline of an item tile or a free cell of a grid under the mouse: the frame of a selected tile
 * (fnc_drawSelection) without its fill. Square corners, two pixels thick (a frame and another inside it), in
 * the accent colour, snapped to whole pixels. The one place that draws it, so a tile and a free cell look
 * the same as the Ctrl selection. Slots (weapon, worn gear, hotbar) get the round fnc_uiRing instead. Given the grid it
 * lies on, a box that touches a corner of the compartment's panel is round at that corner (fnc_cornerRadii,
 * fnc_uiOutline), as the container is.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: The grid the box lies on, so its corners can follow the panel's - the box in the grid's group <HASHMAP> (default: none)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.05, 0.05]] call aio_gui_fnc_hoverOutline;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_grid", createHashMap, [createHashMap]]];
_rect params ["_left", "_top", "_width", "_height"];

private _accent = GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]];

// At a corner of the panel the outline is round there.
private _corners = if (count _grid > 0) then {[_grid, _rect] call FUNC(cornerRadii)} else {[]};

if (_corners isNotEqualTo []) exitWith {
    [_display, _parent, _rect, _accent, _corners, 2] call FUNC(uiOutline)
};

// In a group the position counts from the group's corner, on the display from the screen's.
private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

[
    [_display, _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0], _accent] call FUNC(uiFrame),
    [_display, _parent, [_x0 + pixelW, _y0 + pixelH, (_x1 - _x0) - pixelW * 2, (_y1 - _y0) - pixelH * 2], _accent] call FUNC(uiFrame)
]
