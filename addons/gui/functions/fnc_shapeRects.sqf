#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a shaped item's tile (size=xx/x-, einv_items_fnc_footprintAs) is drawn: the rectangles of its
 * surface, or of the one-pixel border around it, on its cells only - so whatever lies in the corner an L
 * leaves open shows, and so does an empty cell there. fnc_uiShape makes controls of them; a drag's
 * footprint moves controls it made beforehand onto them (fnc_updateDrag), as it does for a rectangle.
 *
 * As a cell ends a pixel before the next one, so does a tile: the surface is one rectangle per run of
 * cells in a row, and between two rows a one-pixel bridge where both have cells, so the cells of one
 * tile read as one surface with no line through it, and nothing overlaps (a see-through colour is as
 * strong everywhere). The border follows the outer edge of that surface: a line along each run of cell
 * sides with no cell of the tile beyond them, drawn on the surface's outermost pixels as a rectangle's
 * frame is - every pixel of the surface that touches the outside, corners too, and each of them once:
 * a corner pixel belongs to the line along the row, so the line along the column stops a pixel short of
 * it, and at an inner corner, where the tile goes on, the lines reach over the gap to meet. A frame set
 * in by some pixels (a selection's second line) moves each line inward by that much: shorter by it at an
 * outer corner, longer by it at an inner one, so the two lines together have no gap.
 *
 * On a canvas's compartment the box may be drawn in on a side where it borders another compartment
 * (fnc_spanInsets): the cells along that side of the box shrink by it, as a rectangle's tile does, and the
 * lines follow the edge they are drawn in to.
 *
 * Arguments:
 * 0: Top left corner of its box [x, y] - the one drawn in, as fnc_spanRect gives it <ARRAY>
 * 1: A cell's width, the gap to the next one included <NUMBER>
 * 2: A cell's height, the same way <NUMBER>
 * 3: Footprint as it lies, [w, h, holes] - holes the indices row * w + col <ARRAY>
 * 4: What: "surface" or "frame" <STRING> (default: "surface")
 * 5: A frame set in by this many pixels <NUMBER> (default: 0)
 * 6: How far the box is drawn in on each side, [left, top, right, bottom] (fnc_spanInsets) <ARRAY>
 *    (default: [0, 0, 0, 0])
 *
 * Return Value:
 * Rectangles [x, y, w, h]; for a surface the first is the top row's first run <ARRAY>
 *
 * Example:
 * [[_left, _top], _cellW, _cellH, [2, 2, [3]]] call einv_gui_fnc_shapeRects;
 *
 * Public: No
 */

params ["_origin", "_cellW", "_cellH", "_footprint", ["_part", "surface"], ["_inset", 0], ["_insets", [0, 0, 0, 0]]];
_footprint params ["_w", "_h", ["_holes", []]];
_insets params [["_inL", 0], ["_inT", 0], ["_inR", 0], ["_inB", 0]];

// The corner given is the one drawn in: the box's own lies that much up and to the left of it.
private _left = (_origin select 0) - _inL;
private _top = (_origin select 1) - _inT;

// Where a column's (row's) cell starts and where it ends, a pixel before the next one (_this the index):
// a pitch on per cell, the first and the last drawn in on the box's sides that are.
private _fnc_x = {_left + _this * _cellW + ([0, _inL] select (_this == 0))};
private _fnc_right = {_left + (_this + 1) * _cellW - pixelW - ([0, _inR] select (_this == _w - 1))};
private _fnc_y = {_top + _this * _cellH + ([0, _inT] select (_this == 0))};
private _fnc_bottom = {_top + (_this + 1) * _cellH - pixelH - ([0, _inB] select (_this == _h - 1))};

private _fnc_in = {
    params ["_col", "_row"];

    _col >= 0 && {_row >= 0} && {_col < _w} && {_row < _h} && {!((_row * _w + _col) in _holes)}
};

// The runs [first, last] of the indices 0 to count - 1 for which the condition holds (_i is the index).
private _fnc_runs = {
    params ["_count", "_condition"];

    private _runs = [];
    private _start = -1;

    for "_i" from 0 to _count do {
        if (_i < _count && {call _condition}) then {
            if (_start < 0) then {_start = _i};
        } else {
            if (_start >= 0) then {
                _runs pushBack [_start, _i - 1];
                _start = -1;
            };
        };
    };

    _runs
};

private _rects = [];

if (_part isEqualTo "surface") then {
    for "_row" from 0 to (_h - 1) do {
        {
            _x params ["_first", "_last"];

            _rects pushBack [_first call _fnc_x, _row call _fnc_y, (_last call _fnc_right) - (_first call _fnc_x), (_row call _fnc_bottom) - (_row call _fnc_y)];
        } forEach ([_w, {[_i, _row] call _fnc_in}] call _fnc_runs);

        // The gap to the next row, where both rows have cells.
        if (_row < _h - 1) then {
            {
                _x params ["_first", "_last"];

                _rects pushBack [_first call _fnc_x, _row call _fnc_bottom, (_last call _fnc_right) - (_first call _fnc_x), pixelH];
            } forEach ([_w, {[_i, _row] call _fnc_in && {[_i, _row + 1] call _fnc_in}}] call _fnc_runs);
        };
    };
} else {
    // Along the rows: the top sides with no cell above, the bottom sides with none below.
    for "_row" from 0 to (_h - 1) do {
        {
            _x params ["_side", "_runs"];

            {
                _x params ["_first", "_last"];

                // To the line along the column it turns into, on the cell beyond where the tile goes on.
                private _from = if ([_first - 1, _row] call _fnc_in) then {
                    ((_first - 1) call _fnc_right) - (1 + _inset) * pixelW
                } else {
                    (_first call _fnc_x) + _inset * pixelW
                };
                private _to = if ([_last + 1, _row] call _fnc_in) then {
                    ((_last + 1) call _fnc_x) + (1 + _inset) * pixelW
                } else {
                    (_last call _fnc_right) - _inset * pixelW
                };
                private _lineY = [(_row call _fnc_y) + _inset * pixelH, (_row call _fnc_bottom) - (1 + _inset) * pixelH] select (_side > 0);

                _rects pushBack [_from, _lineY, _to - _from, pixelH];
            } forEach _runs;
        } forEach [
            [-1, [_w, {[_i, _row] call _fnc_in && {!([_i, _row - 1] call _fnc_in)}}] call _fnc_runs],
            [1, [_w, {[_i, _row] call _fnc_in && {!([_i, _row + 1] call _fnc_in)}}] call _fnc_runs]
        ];
    };

    // Along the columns: the left sides with no cell to their left, the right sides with none to their
    // right.
    for "_col" from 0 to (_w - 1) do {
        {
            _x params ["_side", "_runs"];

            {
                _x params ["_first", "_last"];

                private _from = if ([_col, _first - 1] call _fnc_in) then {
                    ((_first - 1) call _fnc_bottom) - _inset * pixelH
                } else {
                    (_first call _fnc_y) + (1 + _inset) * pixelH
                };
                private _to = if ([_col, _last + 1] call _fnc_in) then {
                    ((_last + 1) call _fnc_y) + _inset * pixelH
                } else {
                    (_last call _fnc_bottom) - (1 + _inset) * pixelH
                };
                private _lineX = [(_col call _fnc_x) + _inset * pixelW, (_col call _fnc_right) - (1 + _inset) * pixelW] select (_side > 0);

                if (_to > _from) then {
                    _rects pushBack [_lineX, _from, pixelW, _to - _from];
                };
            } forEach _runs;
        } forEach [
            [-1, [_h, {[_col, _i] call _fnc_in && {!([_col - 1, _i] call _fnc_in)}}] call _fnc_runs],
            [1, [_h, {[_col, _i] call _fnc_in && {!([_col + 1, _i] call _fnc_in)}}] call _fnc_runs]
        ];
    };
};

_rects
