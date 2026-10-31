#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates an outline with round corners - a round card's border and the hover ring of a slot (an item tile's hover outline is square, fnc_hoverOutline): four
 * edges and four quarter rings (ring_*_ca), laid out as fnc_uiPanel lays out a round panel, so the
 * outline follows the corners of what it surrounds. The edges are as thick as the rings are drawn
 * (RING_SHARE of the corner). Square corners get a plain one pixel frame. A mask round only some of the corners: an
 * unrounded one is a plain square joint of the two edges (a tile, a cell or a selection at one corner of its compartment's
 * panel, fnc_cornerRadii, fnc_uiOutline).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour <ARRAY>
 * 4: Corner radius, as a height, 0 for square corners <NUMBER> (default: 0)
 * 5: Which corners are round, [top left, top right, bottom left, bottom right] <ARRAY> (default: all four)
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.3, 0.2], [1, 0.65, 0.14, 1], 0.01] call einv_gui_fnc_uiRing;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color", ["_radius", 0], ["_mask", [true, true, true, true], [[]]]];
_mask params ["_topLeft", "_topRight", "_bottomLeft", "_bottomRight"];
_rect params ["_left", "_top", "_width", "_height"];

private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = _originX + round ((_left - _originX) / pixelW) * pixelW;
private _y0 = _originY + round ((_top - _originY) / pixelH) * pixelH;
private _x1 = _originX + round ((_left + _width - _originX) / pixelW) * pixelW;
private _y1 = _originY + round ((_top + _height - _originY) / pixelH) * pixelH;

private _corner = floor (_radius / pixelH + 0.001) min floor (round ((_x1 - _x0) / pixelW) / 2) min floor (round ((_y1 - _y0) / pixelH) / 2);

if (_corner < 2) exitWith {
    [[_display, _parent, [_x0, _y0, _x1 - _x0, _y1 - _y0], _color] call FUNC(uiFrame)]
};

private _cap = _corner * pixelW;
private _rise = _corner * pixelH;
private _thick = (round (_corner * RING_SHARE)) max 1;
private _lineW = _thick * pixelW;
private _lineH = _thick * pixelH;
private _controls = [];

{
    // A pill has no straight edge left between its corners.
    if ((_x select 2) <= 0 || {(_x select 3) <= 0}) then {continue};

    private _ctrl = [_display, "EINV_PanelRect", _parent, _x] call FUNC(uiCreate);
    _ctrl ctrlSetBackgroundColor _color;
    _controls pushBack _ctrl;
} forEach [
    [_x0 + ([0, _cap] select _topLeft), _y0, _x1 - _x0 - ([0, _cap] select _topLeft) - ([0, _cap] select _topRight), _lineH],
    [_x0 + ([0, _cap] select _bottomLeft), _y1 - _lineH, _x1 - _x0 - ([0, _cap] select _bottomLeft) - ([0, _cap] select _bottomRight), _lineH],
    [_x0, _y0 + ([_lineH, _rise] select _topLeft), _lineW, _y1 - _y0 - ([_lineH, _rise] select _topLeft) - ([_lineH, _rise] select _bottomLeft)],
    [_x1 - _lineW, _y0 + ([_lineH, _rise] select _topRight), _lineW, _y1 - _y0 - ([_lineH, _rise] select _topRight) - ([_lineH, _rise] select _bottomRight)]
];

{
    _x params ["_on", "_texture", "_cornerRect"];

    if (!_on) then {continue};

    private _ctrl = [_display, "EINV_PanelCorner", _parent, _cornerRect] call FUNC(uiCreate);
    _ctrl ctrlSetText _texture;
    _ctrl ctrlSetTextColor _color;
    _controls pushBack _ctrl;
} forEach [
    [_topLeft, UI_TEX(ring_tl_ca), [_x0, _y0, _cap, _rise]],
    [_topRight, UI_TEX(ring_tr_ca), [_x1 - _cap, _y0, _cap, _rise]],
    [_bottomLeft, UI_TEX(ring_bl_ca), [_x0, _y1 - _rise, _cap, _rise]],
    [_bottomRight, UI_TEX(ring_br_ca), [_x1 - _cap, _y1 - _rise, _cap, _rise]]
];

_controls
