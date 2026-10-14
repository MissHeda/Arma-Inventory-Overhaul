#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A canvas to draw on (fnc_uiCanvas), holding compartments where the inventory puts them
 * (einv_gui_fnc_flowCompartments): side by side as far as STORAGE_COLS cells reach, then on the next line.
 * The inventory leaves a gap between two compartments; the canvas has none, so a line breaks where the
 * inventory's does - the gap counted. A compartment's holes are places without a cell. An item's
 * footprint is one compartment: it lies in the top left corner. Compartments drawn on a canvas before (a
 * pos each, grid=aab/acc) lie where they were drawn, their canvas one piece of the flow and what follows
 * under it, as the inventory has them (einv_gui_fnc_flowCompartments).
 *
 * Painted (the Containers step), every compartment gets a colour, and two that touch never the same
 * one: cells of one colour that touch are one compartment (fnc_canvasBlocks), so two neighbours of one
 * colour would read back as one. Greedy, in the order given, each one trying the colours from its own
 * place in that order on - so compartments laid out one after the other mostly differ even where they
 * do not touch, which is what makes a flowed grid readable at a glance. Read back, a painted canvas
 * gives the same compartments in the same order, except one whose own holes cut it into pieces (x-x):
 * each piece is a compartment of its own then.
 *
 * Arguments:
 * 0: Compartments [[cols, rows, holes, pos], ...], holes the indices row * cols + col, pos [x, y] on
 *    their canvas or [] (both may be left out) <ARRAY>
 * 1: At least this many rows <NUMBER> (default: 1)
 * 2: At most this many rows - what lies below is cut away <NUMBER> (default: CANVAS_ROWS_LOADED)
 * 3: Columns: STORAGE_COLS for a container, SHAPE_MAX for an item's board <NUMBER> (default: STORAGE_COLS)
 * 4: Painted: colours instead of cells <BOOL> (default: false)
 *
 * Return Value:
 * Canvas <HASHMAP>
 *   "cols"  - its columns, as given <NUMBER>
 *   "rows"  - its rows <NUMBER>
 *   "cells" - not painted: per place (index row * cols + col) whether it is a cell <ARRAY of BOOL>
 *   "paint" - painted: per place its colour, 0 for none, else 1 to PAINT_COUNT <ARRAY of NUMBER>
 *
 * Example:
 * private _canvas = [[[4, 2, [5, 6]], [2, 3, []]], 1, CANVAS_ROWS_LOADED, STORAGE_COLS, true] call einv_setup_fnc_canvasFromBlocks;
 *
 * Public: No
 */

params [
    ["_blocks", [], [[]]], ["_minRows", 1, [0]], ["_maxRows", CANVAS_ROWS_LOADED, [0]], ["_cols", STORAGE_COLS, [0]], ["_painted", false, [false]]
];

// Where each compartment goes, in cells. The gap the inventory leaves after one only decides where a
// line breaks.
private _places = [];
private _lineX = 0;
private _lineGaps = 0;
private _lineY = 0;
private _lineH = 0;

// Where the next piece goes, _w by _h cells: [col, row].
private _fnc_flow = {
    params ["_w", "_h"];

    if (_lineX > 0 && {_lineX + _lineGaps * COMPARTMENT_GAP + _w > _cols + 0.0001}) then {
        _lineX = 0;
        _lineGaps = 0;
        _lineY = _lineY + _lineH;
        _lineH = 0;
    };

    private _place = [_lineX, _lineY];

    _lineX = _lineX + _w;
    _lineGaps = _lineGaps + 1;
    _lineH = _lineH max _h;

    _place
};

private _index = 0;

while {_index < count _blocks} do {
    (_blocks select _index) params [["_w", 0], ["_h", 0], "", ["_pos", []]];

    switch (true) do {
        case (_w < 1 || {_h < 1}): {
            _places pushBack [];
            _index = _index + 1;
        };
        case (_pos isEqualTo []): {
            _places pushBack ([_w, _h] call _fnc_flow);
            _index = _index + 1;
        };
        default {
            // The canvas, as one piece: this compartment and the placed ones after it.
            private _last = _index;

            while {_last + 1 < count _blocks && {((_blocks select (_last + 1)) param [3, []]) isNotEqualTo []}} do {
                _last = _last + 1;
            };

            private _group = _blocks select [_index, _last - _index + 1];
            private _minX = selectMin (_group apply {(_x select 3) select 0});
            private _minY = selectMin (_group apply {(_x select 3) select 1});
            private _groupW = selectMax (_group apply {((_x select 3) select 0) + (_x select 0)}) - _minX;
            private _groupH = selectMax (_group apply {((_x select 3) select 1) + (_x select 1)}) - _minY;

            ([_groupW, _groupH] call _fnc_flow) params ["_canvasX", "_canvasY"];

            {
                (_x select 3) params ["_posX", "_posY"];

                _places pushBack [_canvasX + _posX - _minX, _canvasY + _posY - _minY];
            } forEach _group;

            // What follows starts under it.
            _lineX = 1e6;
            _index = _last + 1;
        };
    };
};

private _rows = (((_lineY + _lineH) max _minRows) min _maxRows) max 1;
private _count = _cols * _rows;
private _owners = [];

_owners resize _count;
_owners = _owners apply {-1};

// Each compartment's cells, as far as the canvas reaches; its holes stay places without one.
{
    private _place = _places select _forEachIndex;

    if (_place isEqualTo []) then {continue};

    _x params ["_w", "_h", ["_holes", []]];
    _place params ["_left", "_top"];

    private _block = _forEachIndex;

    for "_row" from 0 to (_h - 1) do {
        for "_col" from 0 to (_w - 1) do {
            if (_left + _col < _cols && {_top + _row < _rows} && {!((_row * _w + _col) in _holes)}) then {
                _owners set [(_top + _row) * _cols + _left + _col, _block];
            };
        };
    };
} forEach _blocks;

private _cells = _owners apply {_x >= 0};

if (!_painted) exitWith {
    createHashMapFromArray [["cols", _cols], ["rows", _rows], ["cells", _cells]]
};

// Which compartments touch, side by side or one above the other.
private _touching = _blocks apply {createHashMap};

{
    if (_x < 0) then {continue};

    private _owner = _x;

    {
        if (_x >= 0 && {_x != _owner}) then {
            (_touching select _owner) set [_x, true];
            (_touching select _x) set [_owner, true];
        };
    } forEach [
        [-1, _owners param [_forEachIndex + 1, -1]] select ((_forEachIndex mod _cols) < _cols - 1),
        [-1, _owners param [_forEachIndex + _cols, -1]] select (_forEachIndex + _cols < _count)
    ];
} forEach _owners;

private _colors = _blocks apply {0};

{
    private _taken = (keys (_touching select _forEachIndex)) apply {_colors select _x};
    private _first = _forEachIndex mod PAINT_COUNT;
    private _color = 0;

    for "_step" from 0 to (PAINT_COUNT - 1) do {
        private _try = (_first + _step) mod PAINT_COUNT + 1;

        if !(_try in _taken) exitWith {
            _color = _try;
        };
    };

    // Eight neighbours of eight colours: a drawing nobody makes. It shares one with a neighbour, which
    // then reads back as one compartment with it.
    if (_color == 0) then {
        _color = _first + 1;
    };

    _colors set [_forEachIndex, _color];
} forEach _blocks;

createHashMapFromArray [
    ["cols", _cols], ["rows", _rows], ["paint", _owners apply {if (_x < 0) then {0} else {_colors select _x}}]
]
