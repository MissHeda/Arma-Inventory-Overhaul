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
 * A grid may also be drawn as a canvas (letters allowed): each cell carries the letter of its
 * compartment, "a" to "z", and cells of the same letter are one compartment wherever they lie -
 * "aaa/aba/aaa" is a box of eight cells with a cell of its own in the middle. So the compartments come
 * out where they were drawn, not where the window would flow them. A shape with no letter but "x"
 * stays the one compartment it always was. An item has one shape only, so size= allows no letters.
 *
 * Arguments:
 * 0: Shape text, like "xxx/x-x" <STRING>
 * 1: At most this many columns, -1 for no limit <NUMBER> (default: -1)
 * 2: At most this many rows, -1 for no limit <NUMBER> (default: -1)
 * 3: Letters allowed - a canvas <BOOL> (default: false)
 *
 * Return Value:
 * [cols, rows, holes] - holes the indices row * cols + col of the cells it does not have, ascending,
 * [] for a full rectangle; [-1, -1, why] when the text cannot be read; [0, 0, []] when a cut to the
 * limits left no cell. A canvas has a fourth element, its compartments [[cols, rows, holes, [x, y]],
 * ...] in reading order of each one's first cell, [x, y] its top left corner on the canvas; its own
 * holes are then the places with no cell of any of them; a fifth element, the letters of those compartments in the same
 * order ("a", "b", ...), which fnc_parseGrid needs to hand each its attributes <ARRAY>
 *
 * Example:
 * ["xx/x-"] call aio_items_fnc_parseMask; // [2, 2, [3]]
 * ["aaa/aba/aaa", 10, 40, true] call aio_items_fnc_parseMask; // [3, 3, [], [[3, 3, [4], [0, 0]], [1, 1, [], [1, 1]]], ["a", "b"]]
 *
 * Public: No
 */

params [["_text", "", [""]], ["_maxCols", -1, [0]], ["_maxRows", -1, [0]], ["_letters", false, [false]]];

private _piece = toLowerANSI _text;
private _lines = _piece splitString "/";
private _codes = toArray _piece;

// splitString drops empty rows; a shape has none - and so never holds "//", which a cba_settings.sqf
// could take for a comment.
if (count _lines != ({_x == 47} count toArray _piece) + 1) exitWith {
    [-1, -1, "every row of a shape holds cells or holes, like xxx/x-x"]
};

if (!_letters && {_codes findIf {!(_x in [120, 45, 47])} >= 0}) exitWith {
    [-1, -1, "a shape is drawn with x for a cell and - for a hole, rows separated by /, like xxx/x-x"]
};

if (_letters && {_codes findIf {!(_x in [45, 47]) && {_x < 97 || {_x > 122}}} >= 0}) exitWith {
    [-1, -1, "a shape is drawn with x for a cell and - for a hole, a canvas with a letter per compartment, rows separated by /, like xxx/x-x or aab/acc"]
};

// A letter other than x names compartments: a canvas.
private _isCanvas = _letters && {_codes findIf {_x >= 97 && {_x <= 122} && {_x != 120}} >= 0};

private _width = count (_lines select 0);

if (_lines findIf {count _x != _width} >= 0) exitWith {
    [-1, -1, "every row of a shape is as long as the first, like xxx/x-x"]
};

// Where the cells are: the smallest rectangle around them.
private _left = _width;
private _right = -1;
private _top = -1;
private _bottom = -1;

// Every letter is a cell, "-" a hole.
{
    private _row = _forEachIndex;
    private _lineCodes = toArray _x;
    private _first = _lineCodes findIf {_x != 45};

    if (_first >= 0) then {
        private _last = _width - 1;

        while {(_lineCodes select _last) == 45} do {_last = _last - 1};

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

    private _shape = [_cut joinString "/", -1, -1, _letters] call FUNC(parseMask);

    [_shape, [0, 0, []]] select ((_shape select 0) < 1)
};

private _holes = [];

// Per letter of a canvas, in the order they first appear reading from the top left: the box around
// its cells and the cells themselves, on the canvas.
private _order = [];
private _found = createHashMap;

for "_r" from 0 to (_rows - 1) do {
    private _line = (_lines select (_top + _r)) select [_left, _cols];

    for "_c" from 0 to (_cols - 1) do {
        private _char = _line select [_c, 1];

        if (_char isEqualTo "-") then {
            _holes pushBack (_r * _cols + _c);
            continue;
        };

        if (!_isCanvas) then {continue};

        private _entry = _found get _char;

        if (isNil "_entry") then {
            _entry = [_c, _c, _r, _r, []];
            _found set [_char, _entry];
            _order pushBack _char;
        };

        _entry set [0, (_entry select 0) min _c];
        _entry set [1, (_entry select 1) max _c];
        _entry set [3, _r];
        (_entry select 4) pushBack (_r * _cols + _c);
    };
};

if (!_isCanvas) exitWith {[_cols, _rows, _holes]};

// Each compartment as the box around its cells, every place of the box that is not its own a hole -
// another compartment's cell, or one of the canvas's holes.
private _parts = _order apply {
    (_found get _x) params ["_minCol", "_maxCol", "_minRow", "_maxRow", "_cells"];

    private _w = _maxCol - _minCol + 1;
    private _h = _maxRow - _minRow + 1;
    private _own = [];

    for "_r" from 0 to (_h - 1) do {
        for "_c" from 0 to (_w - 1) do {
            if !(((_minRow + _r) * _cols + _minCol + _c) in _cells) then {
                _own pushBack (_r * _w + _c);
            };
        };
    };

    [_w, _h, _own, [_minCol, _minRow]]
};

[_cols, _rows, _holes, _parts, _order]
