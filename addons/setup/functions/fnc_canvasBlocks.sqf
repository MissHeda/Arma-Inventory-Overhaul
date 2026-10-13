#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The compartments a canvas (fnc_uiCanvas) holds. Cells that touch - side by side or one above the
 * other, not only at a corner - with no divider between them are one compartment; it is written as the
 * box around its cells, each place of the box that is not one of its cells a hole - another
 * compartment's cell lying in that box too. For an item, the one compartment is its shape.
 *
 * In reading order, by each one's first cell from the top left: a canvas laid out by
 * fnc_canvasFromBlocks gives its compartments back in the order it was given them, so drawing on one
 * keeps the others where they were.
 *
 * Arguments:
 * 0: Canvas, see fnc_canvasFromBlocks <HASHMAP>
 *
 * Return Value:
 * Compartments [[cols, rows, holes], ...], holes the indices row * cols + col, ascending, [] for a full
 * rectangle; [] for a canvas without a cell <ARRAY>
 *
 * Example:
 * private _blocks = [_canvas] call einv_setup_fnc_canvasBlocks;
 *
 * Public: No
 */

params [["_canvas", createHashMap, [createHashMap]]];

private _cols = _canvas getOrDefault ["cols", 1];
private _rows = _canvas getOrDefault ["rows", 0];
private _cells = _canvas getOrDefault ["cells", []];
private _right = _canvas getOrDefault ["right", []];
private _below = _canvas getOrDefault ["below", []];

// Per place the compartment it belongs to, -1 for none yet.
private _label = _cells apply {-1};
private _blocks = [];

{
    if (!_x || {(_label select _forEachIndex) >= 0}) then {continue};

    private _id = count _blocks;
    private _members = [_forEachIndex];
    private _next = 0;

    _label set [_forEachIndex, _id];

    // Every cell it reaches without crossing a divider.
    while {_next < count _members} do {
        private _cell = _members select _next;
        private _col = _cell mod _cols;
        private _row = floor (_cell / _cols);

        _next = _next + 1;

        {
            _x params ["_open", "_neighbour"];

            if (_open && {_cells select _neighbour} && {(_label select _neighbour) < 0}) then {
                _label set [_neighbour, _id];
                _members pushBack _neighbour;
            };
        } forEach [
            [_col < _cols - 1 && {!(_right select _cell)}, _cell + 1],
            [_col > 0 && {!(_right select (_cell - 1))}, _cell - 1],
            [_row < _rows - 1 && {!(_below select _cell)}, _cell + _cols],
            [_row > 0 && {!(_below select (_cell - _cols))}, _cell - _cols]
        ];
    };

    // The box around them; what of it is not theirs is a hole.
    private _minCol = _cols;
    private _maxCol = -1;
    private _minRow = _rows;
    private _maxRow = -1;

    {
        private _col = _x mod _cols;
        private _row = floor (_x / _cols);

        _minCol = _minCol min _col;
        _maxCol = _maxCol max _col;
        _minRow = _minRow min _row;
        _maxRow = _maxRow max _row;
    } forEach _members;

    private _w = _maxCol - _minCol + 1;
    private _h = _maxRow - _minRow + 1;
    private _holes = [];

    for "_row" from 0 to (_h - 1) do {
        for "_col" from 0 to (_w - 1) do {
            if ((_label select ((_minRow + _row) * _cols + _minCol + _col)) != _id) then {
                _holes pushBack (_row * _w + _col);
            };
        };
    };

    _blocks pushBack [_w, _h, _holes];
} forEach _cells;

_blocks
