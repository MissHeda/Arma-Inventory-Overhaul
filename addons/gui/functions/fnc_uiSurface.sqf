#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a flat surface that is square except at the corners it is told to round: a tile, an empty cell, a selection's
 * fill or a drag footprint that touches a corner of its compartment's panel (fnc_cornerRadii) follows the panel's round
 * corner there and nowhere else. Laid out as fnc_uiPanel lays out a round panel - a middle rectangle, a strip on each side
 * that has a round corner, and a quarter circle (corner_*_ca) for each round corner; the corners that stay square are part
 * of the middle and the strips. Every edge on a screen pixel, pieces that meet without overlapping, so a see-through
 * surface shows no seams. Without corners it is the one rectangle it always was. fnc_paintSurface colours the pieces.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour <ARRAY>
 * 4: The corners to round, as fnc_cornerRadii answers - [radius in pixels, [top left, top right, bottom left, bottom right]],
 *    [] for none <ARRAY> (default: [])
 *
 * Return Value:
 * The controls, the middle rectangle first, then the strips, then the quarter circles <ARRAY>
 *
 * Example:
 * [_display, _group, _rect, _color, [_grid, _rect] call aio_gui_fnc_cornerRadii] call aio_gui_fnc_uiSurface;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color", ["_corners", []]];
_rect params ["_left", "_top", "_width", "_height"];

if (_corners isEqualTo []) exitWith {
    private _ctrl = [_display, "AIO_PanelRect", _parent, _rect] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;

    [_ctrl]
};

_corners params ["_radius", "_mask"];
_mask params ["_topLeft", "_topRight", "_bottomLeft", "_bottomRight"];

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

// A corner is as many pixels across as down and never more than half the box.
private _corner = (floor _radius) min floor (round ((_x1 - _x0) / pixelW) / 2) min floor (round ((_y1 - _y0) / pixelH) / 2);

if (_corner < 1) exitWith {
    private _ctrl = [_display, "AIO_PanelRect", _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0]] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;

    [_ctrl]
};

private _cap = _corner * pixelW;
private _rise = _corner * pixelH;
private _capLeft = [0, _cap] select (_topLeft || _bottomLeft);
private _capRight = [0, _cap] select (_topRight || _bottomRight);
private _controls = [];

{
    // Nothing is left of a strip between two corners of a short box.
    if ((_x select 2) <= 0 || {(_x select 3) <= 0}) then {continue};

    private _ctrl = [_display, "AIO_PanelRect", _parent, _x] call FUNC(uiCreate);

    _ctrl ctrlSetBackgroundColor _color;
    _controls pushBack _ctrl;
} forEach [
    [_x0 + _capLeft, _y0, _x1 - _x0 - _capLeft - _capRight, _y1 - _y0],
    [_x0, _y0 + ([0, _rise] select _topLeft), _capLeft, _y1 - _y0 - ([0, _rise] select _topLeft) - ([0, _rise] select _bottomLeft)],
    [_x1 - _capRight, _y0 + ([0, _rise] select _topRight), _capRight, _y1 - _y0 - ([0, _rise] select _topRight) - ([0, _rise] select _bottomRight)]
];

{
    _x params ["_on", "_texture", "_cornerRect"];

    if (!_on) then {continue};

    private _ctrl = [_display, "AIO_PanelCorner", _parent, _cornerRect] call FUNC(uiCreate);

    _ctrl ctrlSetText _texture;
    _ctrl ctrlSetTextColor _color;
    _controls pushBack _ctrl;
} forEach [
    [_topLeft, UI_TEX(corner_tl_ca), [_x0, _y0, _cap, _rise]],
    [_topRight, UI_TEX(corner_tr_ca), [_x1 - _cap, _y0, _cap, _rise]],
    [_bottomLeft, UI_TEX(corner_bl_ca), [_x0, _y1 - _rise, _cap, _rise]],
    [_bottomRight, UI_TEX(corner_br_ca), [_x1 - _cap, _y1 - _rise, _cap, _rise]]
];

_controls
