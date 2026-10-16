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
 * On a grid, its cells lie where the grid's columns and rows start (fnc_createGrid "colX", "rowY"): on a
 * canvas's compartment that reaches over a seam (fnc_flowCompartments) the room between two of them is
 * wider, and the surface and the border go over it as over the pixel between two cells, so the shape
 * stays one piece. Without a grid every cell is a pitch on from the last.
 *
 * A compartment's panel (fnc_drawCompartments) is the third part: the shape's cells grown by some pixels
 * on every side, with the room between two of its cells filled - a seam's too - and its holes left open.
 * It is cut into bands down the shape, where a row's cells with their pad or a bridge over a seam between
 * two rows starts or ends, and each band is the stretches across that every row reaching into it has,
 * joined where they meet: rectangles that do not overlap, so a see-through panel is as strong everywhere.
 *
 * Arguments:
 * 0: Top left corner of its box [x, y], as fnc_spanRect gives it <ARRAY>
 * 1: A cell's width, the gap to the next one included <NUMBER>
 * 2: A cell's height, the same way <NUMBER>
 * 3: Footprint as it lies, [w, h, holes] - holes the indices row * w + col <ARRAY>
 * 4: What: "surface", "frame" or "panel" <STRING> (default: "surface")
 * 5: A frame set in by this many pixels; how far a panel reaches past the cells, in pixels <NUMBER> (default: 0)
 * 6: On a grid: [grid, column, row] of the footprint's top left cell; [] for a cell a pitch on from the
 *    last <ARRAY> (default: [])
 *
 * Return Value:
 * Rectangles [x, y, w, h]; for a surface the first is the top row's first run <ARRAY>
 *
 * Example:
 * [[_left, _top], _cellW, _cellH, [2, 2, [3]]] call einv_gui_fnc_shapeRects;
 * [[_left, _top], _cellW, _cellH, [2, 2, [3]], "surface", 0, [_grid, _col, _row]] call einv_gui_fnc_shapeRects;
 *
 * Public: No
 */

params ["_origin", "_cellW", "_cellH", "_footprint", ["_part", "surface"], ["_inset", 0], ["_on", [], [[]]]];
_footprint params ["_w", "_h", ["_holes", []]];
_on params [["_grid", createHashMap, [createHashMap]], ["_firstCol", 0], ["_firstRow", 0]];

private _left = _origin select 0;
private _top = _origin select 1;
private _colX = _grid getOrDefault ["colX", []];
private _rowY = _grid getOrDefault ["rowY", []];

// Where the grid's column (row) _index starts from its corner: its own place, the plain pitch before the
// first and on from the last (fnc_spanRect).
private _fnc_start = {
    params ["_starts", "_index", "_pitch"];

    private _count = count _starts;

    if (_index >= 0 && {_index < _count}) exitWith {_starts select _index};
    if (_index < 0 || {_count == 0}) exitWith {_index * _pitch};

    (_starts select (_count - 1)) + (_index - _count + 1) * _pitch
};

private _baseX = [_colX, _firstCol, _cellW] call _fnc_start;
private _baseY = [_rowY, _firstRow, _cellH] call _fnc_start;

// Where a column's (row's) cell starts and where it ends, a pixel before the next pitch (_this the index
// in the footprint).
private _fnc_x = {_left + ([_colX, _firstCol + _this, _cellW] call _fnc_start) - _baseX};
private _fnc_right = {(_this call _fnc_x) + _cellW - pixelW};
private _fnc_y = {_top + ([_rowY, _firstRow + _this, _cellH] call _fnc_start) - _baseY};
private _fnc_bottom = {(_this call _fnc_y) + _cellH - pixelH};

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

// A compartment's panel: bands down the shape [top, bottom, stretches across], cut where any starts or ends.
if (_part isEqualTo "panel") exitWith {
    private _padX = _inset * pixelW;
    private _padY = _inset * pixelH;

    // A run of cells [first, last] as its panel covers it across, the pad on both ends.
    private _fnc_span = {[((_this select 0) call _fnc_x) - _padX, ((_this select 1) call _fnc_right) + _padX]};

    // Each row's runs with the pad above and below; and where the next row lies further than the two pads
    // reach - a seam inside the compartment - a bridge over the room between, for the columns both rows have.
    private _bands = [];

    for "_row" from 0 to (_h - 1) do {
        private _runs = [_w, {[_i, _row] call _fnc_in}] call _fnc_runs;

        if (_runs isNotEqualTo []) then {
            _bands pushBack [(_row call _fnc_y) - _padY, (_row call _fnc_bottom) + _padY, _runs apply {_x call _fnc_span}];
        };

        if (_row < _h - 1) then {
            private _from = (_row call _fnc_bottom) + _padY;
            private _to = ((_row + 1) call _fnc_y) - _padY;
            private _both = [_w, {[_i, _row] call _fnc_in && {[_i, _row + 1] call _fnc_in}}] call _fnc_runs;

            if (_to > _from && {_both isNotEqualTo []}) then {
                _bands pushBack [_from, _to, _both apply {_x call _fnc_span}];
            };
        };
    };

    private _cuts = [];

    {
        _cuts pushBackUnique (_x select 0);
        _cuts pushBackUnique (_x select 1);
    } forEach _bands;

    _cuts sort true;

    // The stretches of the piece above, and where that piece started: a piece under it with the same
    // stretches goes on in the same rectangles.
    private _open = [];
    private _openTop = 0;

    private _fnc_close = {
        params ["_bottom"];

        {
            _rects pushBack [_x select 0, _openTop, (_x select 1) - (_x select 0), _bottom - _openTop];
        } forEach _open;
    };

    for "_i" from 0 to (count _cuts - 2) do {
        private _pieceTop = _cuts select _i;
        private _pieceBottom = _cuts select (_i + 1);

        // Two cuts a rounding apart: no piece of their own, the one above goes on over it.
        if (_pieceBottom - _pieceTop < pixelH * 0.5) then {continue};

        private _spans = [];

        {
            _x params ["_bandTop", "_bandBottom", "_bandSpans"];

            if (_bandTop <= _pieceTop && {_bandBottom >= _pieceBottom}) then {
                _spans append _bandSpans;
            };
        } forEach _bands;

        _spans sort true;

        private _joined = [];

        {
            _x params ["_from", "_to"];

            if (_joined isNotEqualTo [] && {_from <= ((_joined select (count _joined - 1)) select 1)}) then {
                private _lastSpan = _joined select (count _joined - 1);

                _lastSpan set [1, (_lastSpan select 1) max _to];
            } else {
                _joined pushBack [_from, _to];
            };
        } forEach _spans;

        if (_joined isNotEqualTo _open) then {
            [_pieceTop] call _fnc_close;

            _open = _joined;
            _openTop = _pieceTop;
        };
    };

    if (_cuts isNotEqualTo []) then {
        [_cuts select (count _cuts - 1)] call _fnc_close;
    };

    _rects
};

if (_part isEqualTo "surface") then {
    for "_row" from 0 to (_h - 1) do {
        {
            _x params ["_first", "_last"];

            _rects pushBack [_first call _fnc_x, _row call _fnc_y, (_last call _fnc_right) - (_first call _fnc_x), (_row call _fnc_bottom) - (_row call _fnc_y)];
        } forEach ([_w, {[_i, _row] call _fnc_in}] call _fnc_runs);

        // The gap to the next row, where both rows have cells: a pixel, or the room a seam opens there.
        if (_row < _h - 1) then {
            {
                _x params ["_first", "_last"];

                _rects pushBack [
                    _first call _fnc_x, _row call _fnc_bottom,
                    (_last call _fnc_right) - (_first call _fnc_x), ((_row + 1) call _fnc_y) - (_row call _fnc_bottom)
                ];
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
