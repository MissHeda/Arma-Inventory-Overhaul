#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Covers a box with Tarkov's diagonal hatching - the look of an empty slot or of an item not searched
 * yet.
 *
 * A picture is stretched over its whole box, which would flatten the stripes on a wide box. So the box
 * is laid with pieces of hatch_ca about a grid cell big, as many across as keep each piece nearly
 * square: the stripes stay at their angle and as dense on a slot as on a tile. The pieces meet on
 * whole pixels, neither overlapping nor leaving a gap.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Colour <ARRAY>
 * 4: Boxes to show it in, [] for all of it <ARRAY> (default: [])
 *    A round block (the unsearched seal, fnc_drawSection) is hatched to its edges but not in its corners: the stripes are laid
 *    over the whole box as always, and each of these boxes - the block without its corner squares - shows its part of them in
 *    a group that cuts them off, so the stripes run on unbroken from one box to the next.
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.05], [1, 1, 1, 0.07]] call aio_gui_fnc_uiHatch;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color", ["_clips", [], [[]]]];
_rect params ["_left", "_top", "_width", "_height"];

// Counted in whole pixels from the display's or the group's corner.
private _originX = [safezoneX, 0] select !isNull _parent;
private _originY = [safezoneY, 0] select !isNull _parent;
private _x0 = round ((_left - _originX) / pixelW);
private _y0 = round ((_top - _originY) / pixelH);
private _pixelsW = round ((_left + _width - _originX) / pixelW) - _x0;
private _pixelsH = round ((_top + _height - _originY) / pixelH) - _y0;

if (_pixelsW < 1 || {_pixelsH < 1}) exitWith {[]};

private _side = round (((call FUNC(getCell)) select 1) / pixelH);
private _rows = 1 max round (_pixelsH / _side);
private _cols = 1 max round (_pixelsW * _rows / _pixelsH);
private _controls = [];

// The pieces, in whole pixels from the display's or the group's corner: [left, top, right, bottom].
private _pieces = [];

for "_row" from 0 to (_rows - 1) do {
    private _top0 = _y0 + round (_row * _pixelsH / _rows);
    private _top1 = _y0 + round ((_row + 1) * _pixelsH / _rows);

    for "_col" from 0 to (_cols - 1) do {
        _pieces pushBack [_x0 + round (_col * _pixelsW / _cols), _top0, _x0 + round ((_col + 1) * _pixelsW / _cols), _top1];
    };
};

// A stretched picture (AIO_PanelCorner): the piece is filled edge to edge, where an icon
// keeping its aspect would leave thin gaps between nearly square pieces.
private _fnc_piece = {
    params ["_in", "_left", "_top", "_width", "_height"];

    private _ctrl = [_display, "AIO_PanelCorner", _in, [_left, _top, _width, _height]] call FUNC(uiCreate);

    _ctrl ctrlSetText UI_TEX(hatch_ca);
    _ctrl ctrlSetTextColor _color;
    _controls pushBack _ctrl;
};

if (_clips isEqualTo []) exitWith {
    {
        _x params ["_left0", "_top0", "_left1", "_top1"];

        [_parent, _originX + _left0 * pixelW, _originY + _top0 * pixelH, (_left1 - _left0) * pixelW, (_top1 - _top0) * pixelH] call _fnc_piece;
    } forEach _pieces;

    _controls
};

{
    _x params ["_clipLeft", "_clipTop", "_clipWidth", "_clipHeight"];

    private _cx0 = round ((_clipLeft - _originX) / pixelW);
    private _cy0 = round ((_clipTop - _originY) / pixelH);
    private _cx1 = round ((_clipLeft + _clipWidth - _originX) / pixelW);
    private _cy1 = round ((_clipTop + _clipHeight - _originY) / pixelH);

    if (_cx1 <= _cx0 || {_cy1 <= _cy0}) then {continue};

    // A group that cuts the pieces off at its edges. It hands the wheel and the clicks on, as a picture's clip group does
    // (fnc_uiItemPicture), so the column scrolls and the box takes a drop over it as over the rest of the block.
    private _group = [_display, "AIO_Group", _parent, [
        _originX + _cx0 * pixelW, _originY + _cy0 * pixelH, (_cx1 - _cx0) * pixelW, (_cy1 - _cy0) * pixelH
    ]] call FUNC(uiCreate);

    _group setVariable [QGVAR(clip), true];
    _group setVariable [QGVAR(hooked), true];
    _group ctrlAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
    _group ctrlAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
    _group ctrlAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];
    _controls pushBack _group;

    {
        _x params ["_left0", "_top0", "_left1", "_top1"];

        if (_left1 > _cx0 && {_left0 < _cx1} && {_top1 > _cy0} && {_top0 < _cy1}) then {
            [_group, (_left0 - _cx0) * pixelW, (_top0 - _cy0) * pixelH, (_left1 - _left0) * pixelW, (_top1 - _top0) * pixelH] call _fnc_piece;
        };
    } forEach _pieces;
} forEach _clips;

_controls
