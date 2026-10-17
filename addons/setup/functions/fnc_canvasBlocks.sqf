#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The compartments a canvas (fnc_uiCanvas) holds. On a painted one (the Containers step) cells of one
 * colour that touch - side by side or one above the other, not only at a corner - are one compartment;
 * another colour beside them is another compartment, a place without colour no cell at all. So two red
 * columns with a blue block between them are three compartments. On one of cells (the Items step) all
 * cells that touch are one. Each is written as the box around its cells, each place of the box that is
 * not one of its cells a hole - another compartment's cell lying in that box too. For an item, the one
 * compartment is its shape.
 *
 * In reading order, by each one's first cell from the top left: a canvas laid out by
 * fnc_canvasFromBlocks gives its compartments back in the order it was given them, so drawing on one
 * keeps the others where they were.
 *
 * Two or more come back where they lie on the canvas - the owner draws a container the way it is built
 * and the inventory shows it so, cell for cell (einv_items_fnc_formatGrid writes them as one canvas,
 * aab/acc): a pos each, from the top left corner of the box around them all. One alone needs no place
 * and has none, for an item's shape as for a container of one compartment. So have painted ones that lie
 * exactly where the inventory would flow them (fnc_canvasFromBlocks, only the places): they are the
 * Blocks way's compartments, drawn and written the same.
 *
 * A painted canvas also carries the attributes of its compartments (the Paint way of the Containers step): "attrs",
 * [[places, accepts, single], ...] - the places a compartment with a category lock or a single slot had when it was last
 * looked at. Each is given to the compartment that has most of those places now (fnc_canvasMatch), so an attribute follows its
 * compartment through repainting: a split one keeps it on the larger part, a merge takes the first's, one whose places are
 * all painted away is gone. A compartment with attributes comes back as fnc_parseGrid gives it, [cols, rows, holes, pos,
 * accepts, single] ([cols, rows, holes, [], accepts, single] where the pos is dropped), one without as before.
 *
 * Asked to sync, it also writes into the canvas what it found: "attrs" with the places as they are now, "parts" (per
 * compartment its places, ascending) and "label" (per place its compartment, -1 for none), which the editor
 * (fnc_canvasPick, fnc_drawCellAttrs) reads. Every change of a canvas does that, so the next one maps from the
 * compartments as they were.
 *
 * Arguments:
 * 0: Canvas, see fnc_canvasFromBlocks <HASHMAP>
 * 1: Sync: write "attrs", "parts" and "label" into the canvas <BOOL> (default: false)
 *
 * Return Value:
 * Compartments [[cols, rows, holes, pos], ...], holes the indices row * cols + col, ascending, [] for a
 * full rectangle; pos [x, y] on the canvas, [] for a single or a flowed one; [] for a canvas without a
 * cell <ARRAY>
 *
 * Example:
 * private _blocks = [_canvas] call einv_setup_fnc_canvasBlocks;
 *
 * Public: No
 */

params [["_canvas", createHashMap, [createHashMap]], ["_sync", false, [false]]];

private _cols = _canvas getOrDefault ["cols", 1];
private _rows = _canvas getOrDefault ["rows", 0];

// What each place holds: its colour, or 1 for a cell; 0 for nothing.
private _values = if ("paint" in _canvas) then {
    _canvas get "paint"
} else {
    (_canvas getOrDefault ["cells", []]) apply {parseNumber _x}
};

// Per place the compartment it belongs to, -1 for none yet.
private _label = _values apply {-1};
private _blocks = [];
private _parts = [];

{
    if (_x == 0 || {(_label select _forEachIndex) >= 0}) then {continue};

    private _value = _x;
    private _id = count _blocks;
    private _members = [_forEachIndex];
    private _next = 0;

    _label set [_forEachIndex, _id];

    // Every cell of its colour it reaches.
    while {_next < count _members} do {
        private _cell = _members select _next;
        private _col = _cell mod _cols;
        private _row = floor (_cell / _cols);

        _next = _next + 1;

        {
            _x params ["_open", "_neighbour"];

            if (_open && {(_values select _neighbour) == _value} && {(_label select _neighbour) < 0}) then {
                _label set [_neighbour, _id];
                _members pushBack _neighbour;
            };
        } forEach [
            [_col < _cols - 1, _cell + 1],
            [_col > 0, _cell - 1],
            [_row < _rows - 1, _cell + _cols],
            [_row > 0, _cell - _cols]
        ];
    };

    _members sort true;
    _parts pushBack _members;

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

    _blocks pushBack [_w, _h, _holes, [_minCol, _minRow]];
} forEach _values;

// The attributes of a painted canvas: each entry goes to the compartment that has most of its places, none to two.
private _attrOf = _blocks apply {[]};

if ("paint" in _canvas) then {
    private _taken = [];
    private _kept = [];

    {
        _x params ["_places", "_accepts", "_single"];

        private _index = [_label, count _blocks, _places, _taken] call FUNC(canvasMatch);

        if (_index >= 0) then {
            _taken pushBack _index;
            _attrOf set [_index, [_accepts, _single]];
            _kept pushBack [_parts select _index, _accepts, _single];
        };
    } forEach (_canvas getOrDefault ["attrs", []]);

    if (_sync) then {
        _canvas set ["attrs", _kept];
        _canvas set ["parts", _parts];
        _canvas set ["label", _label];
    };
};

// A block with its attributes after the pos, as fnc_parseGrid has it.
private _fnc_attach = {
    params ["_list"];

    {
        private _attrs = _attrOf select _forEachIndex;

        if (_attrs isNotEqualTo []) then {
            _list set [_forEachIndex, (_x select [0, 4]) + _attrs];
        };
    } forEach _list;

    _list
};

if (count _blocks == 1) exitWith {
    (_blocks select 0) set [3, []];

    [_blocks] call _fnc_attach
};

// From the corner of the box around them all: where the canvas starts drawing is no part of it.
private _minX = selectMin (_blocks apply {(_x select 3) select 0});
private _minY = selectMin (_blocks apply {(_x select 3) select 1});

{
    (_x select 3) params ["_posX", "_posY"];

    _x set [3, [_posX - _minX, _posY - _minY]];
} forEach _blocks;

// Painted compartments that lie exactly where the inventory would flow them are the same configuration as
// the Blocks way's: they come back with no pos, so Apply writes them joined by + and the preview draws them
// as it draws those blocks - whichever way they were drawn, the result is one. Only a layout the flow
// cannot make keeps its places.
if ("paint" in _canvas) then {
    private _flowed = [_blocks apply {[_x select 0, _x select 1, _x select 2]}, 1, CANVAS_ROWS_LOADED, _cols, false, true] call FUNC(canvasFromBlocks);

    if (_flowed isEqualTo (_blocks apply {_x select 3})) then {
        _blocks = _blocks apply {[_x select 0, _x select 1, _x select 2, []]};
    };
};

[_blocks] call _fnc_attach
