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
 *
 * Return Value:
 * The controls <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.05], [1, 1, 1, 0.07]] call einv_gui_fnc_uiHatch;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_color"];
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

for "_row" from 0 to (_rows - 1) do {
    private _top0 = _y0 + round (_row * _pixelsH / _rows);
    private _top1 = _y0 + round ((_row + 1) * _pixelsH / _rows);

    for "_col" from 0 to (_cols - 1) do {
        private _left0 = _x0 + round (_col * _pixelsW / _cols);
        private _left1 = _x0 + round ((_col + 1) * _pixelsW / _cols);

        // A stretched picture (EINV_PanelCorner): the piece is filled edge to edge, where an icon
        // keeping its aspect would leave thin gaps between nearly square pieces.
        private _ctrl = [_display, "EINV_PanelCorner", _parent, [
            _originX + _left0 * pixelW,
            _originY + _top0 * pixelH,
            (_left1 - _left0) * pixelW,
            (_top1 - _top0) * pixelH
        ]] call FUNC(uiCreate);

        _ctrl ctrlSetText UI_TEX(hatch_ca);
        _ctrl ctrlSetTextColor _color;
        _controls pushBack _ctrl;
    };
};

_controls
