#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The outline of an item tile or a free cell of a grid under the mouse: the frame of a selected tile
 * (fnc_drawSelection) without its fill. Square corners, two pixels thick (a frame and another inside it), in
 * the accent colour, snapped to whole pixels. The one place that draws it, so a tile and a free cell look
 * the same as the Ctrl selection. Slots (weapon, worn gear, hotbar) get the round fnc_uiRing instead.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.05, 0.05]] call einv_gui_fnc_hoverOutline;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect"];
_rect params ["_left", "_top", "_width", "_height"];

private _accent = GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]];

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
