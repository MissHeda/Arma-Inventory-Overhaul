#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A shape turned a quarter clockwise, as an item lies turned (R while dragging, or the layout turning it
 * to make it fit) - the convention of the storage. The cell in column c,
 * row r of the upright shape, cols wide and rows high, lies in column rows - 1 - r, row c of the turned
 * one, which is rows wide and cols high: the top left corner goes to the top right.
 *
 * Arguments:
 * 0: Columns <NUMBER>
 * 1: Rows <NUMBER>
 * 2: Holes, the indices row * cols + col of the cells it does not have <ARRAY> (default: [])
 *
 * Return Value:
 * [cols, rows, holes] turned: the columns are the rows before, the holes ascending <ARRAY>
 *
 * Example:
 * [3, 2, [4, 5]] call einv_items_fnc_turnMask; // xxx/x-- turned: [2, 3, [2, 4]], xx/-x/-x
 *
 * Public: No
 */

params [["_cols", 1, [0]], ["_rows", 1, [0]], ["_holes", [], [[]]]];

private _turned = _holes apply {
    private _col = _x mod _cols;
    private _row = floor (_x / _cols);

    _col * _rows + (_rows - 1 - _row)
};

_turned sort true;

[_rows, _cols, _turned]
