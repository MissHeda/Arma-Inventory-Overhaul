#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a container's compartments (einv_storage_fnc_getBlocks) lie in a block STORAGE_COLS cells wide:
 * side by side as far as that reaches, then on the next line - and, should anything not fit any of
 * them, a line of its own for that, each such item in a little compartment of its own size. A column's
 * section (fnc_drawSection) and a kit's window (fnc_drawWindow) lay their grids out the same way, and
 * fnc_drawCompartments draws them where this put them.
 *
 * Arguments:
 * 0: Layout, see einv_storage_fnc_getLayout <HASHMAP>
 *
 * Return Value:
 * [places, height] <ARRAY>
 *   places - [x, y] from the block's top left corner per compartment, then per overflowing item; [] for
 *            a compartment with no rows, which takes no place
 *   height - how tall all of it is, 0 for nothing at all
 *
 * Example:
 * ([_layout] call einv_gui_fnc_flowCompartments) params ["_places", "_height"];
 *
 * Public: No
 */

params ["_layout"];

(call FUNC(getCell)) params ["_cellW", "_cellH"];

private _gridW = STORAGE_COLS * _cellW;
private _gap = round (_cellW * 0.22 / pixelW) * pixelW;
private _gapY = round (_cellH * 0.22 / pixelH) * pixelH;
private _places = [];
private _lineX = 0;
private _lineY = 0;
private _lineHeight = 0;

private _fnc_flow = {
    params ["_cols", "_rows"];

    private _blockWidth = _cols * _cellW;

    if (_lineX > 0 && {_lineX + _blockWidth > _gridW + 0.0001}) then {
        _lineX = 0;
        _lineY = _lineY + _lineHeight + _gapY;
        _lineHeight = 0;
    };

    _places pushBack [_lineX, _lineY];
    _lineX = _lineX + _blockWidth + _gap;
    _lineHeight = _lineHeight max (_rows * _cellH);
};

// A compartment with no rows - a container that holds nothing at all - takes no place.
{
    if ((_x select 1) > 0) then {
        _x call _fnc_flow;
    } else {
        _places pushBack [];
    };
} forEach (_layout getOrDefault ["blocks", []]);

// What has no room: on a line of its own, each item in a little compartment of its own size.
private _overflow = _layout getOrDefault ["overflow", []];

if (_overflow isNotEqualTo []) then {
    _lineX = 1e6;

    {
        [_x get "w", _x get "h"] call _fnc_flow;
    } forEach _overflow;
};

[_places, [0, _lineY + _lineHeight] select ((_places findIf {_x isNotEqualTo []}) >= 0)]
