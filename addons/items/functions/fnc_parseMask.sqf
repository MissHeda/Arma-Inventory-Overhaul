#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads a shape drawn as text: its rows from the top separated by "/", each the same length, "x" a
 * cell and "-" a hole. A compartment of grid= (fnc_parseGrid) and an item's size= (fnc_parseRules)
 * are drawn the same way, so both read them here and nowhere else.
 *
 * A shape is read to its smallest form: the rows and columns at its edges that are only holes go, so
 * "---/-xx/-x-" is the same as "xx/x-". With limits, what lies past them is cut away (the top left
 * part is kept) and what is left read again the same way.
 *
 * Arguments:
 * 0: Shape text, like "xxx/x-x" <STRING>
 * 1: At most this many columns, -1 for no limit <NUMBER> (default: -1)
 * 2: At most this many rows, -1 for no limit <NUMBER> (default: -1)
 *
 * Return Value:
 * [cols, rows, holes] - holes the indices row * cols + col of the cells it does not have, ascending,
 * [] for a full rectangle; [-1, -1, why] when the text cannot be read; [0, 0, []] when a cut to the
 * limits left no cell <ARRAY>
 *
 * Example:
 * ["xx/x-"] call einv_items_fnc_parseMask; // [2, 2, [3]]
 *
 * Public: No
 */

params [["_text", "", [""]], ["_maxCols", -1, [0]], ["_maxRows", -1, [0]]];

private _piece = toLowerANSI _text;
private _lines = _piece splitString "/";

// splitString drops empty rows; a shape has none - and so never holds "//", which a cba_settings.sqf
// could take for a comment.
if (count _lines != ({_x == 47} count toArray _piece) + 1) exitWith {
    [-1, -1, "every row of a shape holds cells or holes, like xxx/x-x"]
};

if ((toArray _piece) findIf {!(_x in [120, 45, 47])} >= 0) exitWith {
    [-1, -1, "a shape is drawn with x for a cell and - for a hole, rows separated by /, like xxx/x-x"]
};

private _width = count (_lines select 0);

if (_lines findIf {count _x != _width} >= 0) exitWith {
    [-1, -1, "every row of a shape is as long as the first, like xxx/x-x"]
};

// Where the cells are: the smallest rectangle around them.
private _left = _width;
private _right = -1;
private _top = -1;
private _bottom = -1;

{
    private _row = _forEachIndex;
    private _first = _x find "x";

    if (_first >= 0) then {
        private _codes = toArray _x;
        private _last = _width - 1;

        while {(_codes select _last) != 120} do {_last = _last - 1};

        _left = _left min _first;
        _right = _right max _last;
        _bottom = _row;

        if (_top < 0) then {_top = _row};
    };
} forEach _lines;

if (_top < 0) exitWith {
    [-1, -1, "a shape needs at least one cell (x)"]
};

private _cols = _right - _left + 1;
private _rows = _bottom - _top + 1;

// Too large: drawn again from its top left part only and read once more, so it comes out at its
// smallest as any other - or as no shape at all when the cut took every cell.
if ((_maxCols > 0 && {_cols > _maxCols}) || {_maxRows > 0 && {_rows > _maxRows}}) exitWith {
    private _keepCols = [_cols, _cols min _maxCols] select (_maxCols > 0);
    private _keepRows = [_rows, _rows min _maxRows] select (_maxRows > 0);
    private _cut = [];

    for "_r" from 0 to (_keepRows - 1) do {
        _cut pushBack ((_lines select (_top + _r)) select [_left, _keepCols]);
    };

    private _shape = [_cut joinString "/"] call FUNC(parseMask);

    [_shape, [0, 0, []]] select ((_shape select 0) < 1)
};

private _holes = [];

for "_r" from 0 to (_rows - 1) do {
    private _line = (_lines select (_top + _r)) select [_left, _cols];

    for "_c" from 0 to (_cols - 1) do {
        if ((_line select [_c, 1]) isEqualTo "-") then {
            _holes pushBack (_r * _cols + _c);
        };
    };
};

[_cols, _rows, _holes]
