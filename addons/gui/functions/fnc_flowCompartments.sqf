#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Where a container's compartments (aio_storage_fnc_getBlocks) lie in a block STORAGE_COLS cells wide:
 * side by side as far as that reaches, then on the next line - and, should anything not fit any of
 * them, a line of its own for that, each such item in a little compartment of its own size. A column's
 * section (fnc_drawSection) and a kit's window (fnc_drawWindow) lay their grids out the same way, and
 * fnc_drawCompartments draws them where this put them. The setup wizard's preview (aio_setup_fnc_drawPreview)
 * lays its compartments out here too, so it shows what the window shows.
 *
 * Compartments drawn on a canvas (grid=aab/acc, a pos of their own) are not flowed: they lie where they
 * were drawn - the owner draws a backpack the way it is built and wants it to look like that. Every
 * cell has the one size and the plain gap to the next, but where two compartments touch the drawing
 * opens up: a column boundary at which some row has cells of two different compartments on its two
 * sides is a seam, and so is a row boundary at which some column has. Each seam gets SEAM_GAP of a cell
 * (whole pixels) more room, and everything beyond it moves on by that much, so the compartments keep
 * their places relative to each other and line up as painted. A boundary where a compartment meets an
 * empty place is no seam; two that touch only at a corner open the column boundary between them, should
 * neither boundary there be a seam already, so their panels do not meet. A cell's place is its column's
 * and its row's offset from the canvas's corner: the column times the cell plus a gap per seam before it.
 * A compartment that reaches over a seam drawn for two others (a wide one under two narrow ones, the
 * ring of aaa/aba/aaa) has that room between two of its own cells; its panel (fnc_drawCompartments)
 * covers it, so it still reads as one. Such a compartment's place brings its own columns' and rows'
 * offsets, which its grid keeps (fnc_createGrid "colX", "rowY"), so tiles, frames and the mouse use
 * the same places. The canvas is one piece of the flow, the box around its compartments and their
 * seams, and whatever comes after it starts below it. Two of them may share a box (a ring and the cell
 * inside it); the grids find a point by the cells they have (fnc_screenToCell), never by their box.
 *
 * Every compartment has a panel behind its cells that reaches COMPARTMENT_PAD_PX pixels past them. The
 * callers keep a pixel left of and above the block for it (the lines of old); the rest is room in the
 * block: every place moves on by it, and the height and width count it on both sides.
 *
 * Arguments:
 * 0: Layout, see aio_storage_fnc_getLayout <HASHMAP>
 * 1: Cell size [w, h] <ARRAY> (default: fnc_getCell's)
 *
 * Return Value:
 * [places, height, width] <ARRAY>
 *   places - [x, y] from the block's top left corner per compartment, then per overflowing item; [] for
 *            a compartment with no rows, which takes no place. A canvas's compartment has
 *            [x, y, colX, rowY]: where each of its columns and rows starts from its own corner, the
 *            seams it reaches over included
 *   height - how tall all of it is, 0 for nothing at all
 *   width  - how wide its widest line is: more than STORAGE_COLS cells where a canvas has seams across
 *
 * Example:
 * ([_layout] call aio_gui_fnc_flowCompartments) params ["_places", "_height", "_width"];
 *
 * Public: No
 */

params ["_layout", ["_cell", [], [[]]]];

if (_cell isEqualTo []) then {
    _cell = call FUNC(getCell);
};

_cell params ["_cellW", "_cellH"];

private _gridW = STORAGE_COLS * _cellW;
private _gap = round (_cellW * COMPARTMENT_GAP / pixelW) * pixelW;
private _gapY = round (_cellH * COMPARTMENT_GAP / pixelH) * pixelH;
private _seamW = round (_cellW * SEAM_GAP / pixelW) * pixelW;
private _seamH = round (_cellH * SEAM_GAP / pixelH) * pixelH;
private _places = [];
private _lineX = 0;
private _lineY = 0;
private _lineHeight = 0;
private _widest = 0;

// Where the next piece goes, of _width by _height: [x, y].
private _fnc_flow = {
    params ["_width", "_height"];

    if (_lineX > 0 && {_lineX + _width > _gridW + 0.0001}) then {
        _lineX = 0;
        _lineY = _lineY + _lineHeight + _gapY;
        _lineHeight = 0;
    };

    private _place = [_lineX, _lineY];

    _widest = _widest max (_lineX + _width);
    _lineX = _lineX + _width + _gap;
    _lineHeight = _lineHeight max _height;

    _place
};

private _blocks = _layout getOrDefault ["blocks", []];
private _index = 0;

while {_index < count _blocks} do {
    (_blocks select _index) params ["_cols", "_rows", "", ["_pos", []]];

    switch (true) do {
        // A compartment with no rows - a container that holds nothing at all - takes no place.
        case (_rows <= 0): {
            _places pushBack [];
            _index = _index + 1;
        };
        case (_pos isEqualTo []): {
            _places pushBack ([_cols * _cellW, _rows * _cellH] call _fnc_flow);
            _index = _index + 1;
        };
        default {
            // The canvas: this compartment and the ones placed with it that follow, as one piece.
            private _last = _index;

            while {_last + 1 < count _blocks && {((_blocks select (_last + 1)) param [3, []]) isNotEqualTo []}} do {
                _last = _last + 1;
            };

            private _group = _blocks select [_index, _last - _index + 1];
            private _minX = selectMin (_group apply {(_x select 3) select 0});
            private _minY = selectMin (_group apply {(_x select 3) select 1});
            private _canvasCols = selectMax (_group apply {((_x select 3) select 0) + (_x select 0)}) - _minX;
            private _canvasRows = selectMax (_group apply {((_x select 3) select 1) + (_x select 1)}) - _minY;

            // Which of them has a cell on each place of the canvas (row * cols + col), -1 for none: a hole of
            // one compartment may be another's cell.
            private _owner = [];
            _owner resize (_canvasCols * _canvasRows);
            _owner = _owner apply {-1};

            {
                _x params ["_blockCols", "_blockRows", ["_blockHoles", []], "_blockPos"];
                _blockPos params ["_posX", "_posY"];

                private _block = _forEachIndex;

                for "_row" from 0 to (_blockRows - 1) do {
                    for "_col" from 0 to (_blockCols - 1) do {
                        if !((_row * _blockCols + _col) in _blockHoles) then {
                            _owner set [(_posY - _minY + _row) * _canvasCols + _posX - _minX + _col, _block];
                        };
                    };
                };
            } forEach _group;

            // Whether the places _first and _second hold cells of two different compartments.
            private _fnc_meet = {
                params ["_first", "_second"];

                private _one = _owner select _first;
                private _other = _owner select _second;

                _one >= 0 && {_other >= 0} && {_one != _other}
            };

            // The seams: the boundary before column (row) n, true where two compartments meet across it.
            private _seamCols = [];
            private _seamRows = [];

            _seamCols resize _canvasCols;
            _seamRows resize _canvasRows;
            _seamCols = _seamCols apply {false};
            _seamRows = _seamRows apply {false};

            for "_col" from 1 to (_canvasCols - 1) do {
                for "_row" from 0 to (_canvasRows - 1) do {
                    if ([_row * _canvasCols + _col - 1, _row * _canvasCols + _col] call _fnc_meet) exitWith {
                        _seamCols set [_col, true];
                    };
                };
            };

            for "_row" from 1 to (_canvasRows - 1) do {
                for "_col" from 0 to (_canvasCols - 1) do {
                    if ([(_row - 1) * _canvasCols + _col, _row * _canvasCols + _col] call _fnc_meet) exitWith {
                        _seamRows set [_row, true];
                    };
                };
            };

            // Two that touch only at a corner, with no seam between them either way: their panels would meet
            // there, so the column boundary between them opens.
            for "_row" from 1 to (_canvasRows - 1) do {
                for "_col" from 1 to (_canvasCols - 1) do {
                    if (
                        !(_seamCols select _col) && {!(_seamRows select _row)} && {
                            [(_row - 1) * _canvasCols + _col - 1, _row * _canvasCols + _col] call _fnc_meet
                            || {[(_row - 1) * _canvasCols + _col, _row * _canvasCols + _col - 1] call _fnc_meet}
                        }
                    ) then {
                        _seamCols set [_col, true];
                    };
                };
            };

            // Where each column and row of the canvas starts: the plain pitch, and a seam's gap for every seam
            // before it.
            private _colX = [];
            private _rowY = [];
            private _seams = 0;

            {
                if (_x) then {
                    _seams = _seams + 1;
                };

                _colX pushBack (_forEachIndex * _cellW + _seams * _seamW);
            } forEach _seamCols;

            _seams = 0;

            {
                if (_x) then {
                    _seams = _seams + 1;
                };

                _rowY pushBack (_forEachIndex * _cellH + _seams * _seamH);
            } forEach _seamRows;

            private _canvasW = (_colX select (_canvasCols - 1)) + _cellW;
            private _canvasH = (_rowY select (_canvasRows - 1)) + _cellH;

            ([_canvasW, _canvasH] call _fnc_flow) params ["_canvasX", "_canvasY"];

            // Every compartment where it was drawn, its columns and rows where the canvas's lie.
            {
                _x params ["_blockCols", "_blockRows", "", "_blockPos"];

                private _firstCol = (_blockPos select 0) - _minX;
                private _firstRow = (_blockPos select 1) - _minY;
                private _left = _colX select _firstCol;
                private _top = _rowY select _firstRow;

                _places pushBack [
                    _canvasX + _left,
                    _canvasY + _top,
                    (_colX select [_firstCol, _blockCols]) apply {_x - _left},
                    (_rowY select [_firstRow, _blockRows]) apply {_x - _top}
                ];
            } forEach _group;

            // Nothing beside it: what follows starts under the canvas.
            _lineX = 1e6;
            _index = _last + 1;
        };
    };
};

// What has no room: on a line of its own, each item in a little compartment of its own size.
private _overflow = _layout getOrDefault ["overflow", []];

if (_overflow isNotEqualTo []) then {
    _lineX = 1e6;

    {
        _places pushBack ([(_x get "w") * _cellW, (_x get "h") * _cellH] call _fnc_flow);
    } forEach _overflow;
};

if ((_places findIf {_x isNotEqualTo []}) < 0) exitWith {[_places, 0, 0]};

// The panels reach COMPARTMENT_PAD_PX pixels past the cells (fnc_drawCompartments): one of them lies in the
// pixel the callers keep left of and above the block, the rest is room in it on every side.
private _pad = COMPARTMENT_PAD_PX(_cellW);
private _marginX = (_pad - 1) * pixelW;
private _marginY = (_pad - 1) * pixelH;

_places = _places apply {
    if (_x isEqualTo []) then {[]} else {
        private _place = +_x;

        _place set [0, (_x select 0) + _marginX];
        _place set [1, (_x select 1) + _marginY];
        _place
    }
};

[_places, _lineY + _lineHeight + _marginY * 2, _widest + _marginX * 2]
