#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Free spots for new tiles of one class in a holder's view (fnc_findEntry): the requested cell for the
 * first, when it is free, else the first fit - compartment after compartment, row by row, upright, else
 * turned a quarter - or, given an origin, the free spot nearest to it (the compartment of the origin first,
 * upright before turned). Each spot found is taken at once, so several tiles never share a cell. The cells
 * taken are those of every tile of the view that has a count and is no overflow; a shaped item (size=xx/x-)
 * takes only its own cells, holes as it lies, and one in a square box is tried turned too when that takes
 * other cells (einv_items_fnc_footprintAs). A compartment that refuses the item (it accepts only other categories, fnc_blockMode) is
 * passed over - a cell asked for in one is not free, the item goes elsewhere -, and a single slot is one spot that takes the item
 * whole: the compartment's box and holes, whatever cell and size were asked for.
 *
 * Arguments:
 * 0: The view, as fnc_findEntry gives it <HASHMAP>
 * 1: Class <STRING>
 * 2: Cell asked for, [col, row, compartment] with [.., width, height, rot] when it lies turned; [] for
 *    none <ARRAY> (default: [])
 * 3: How many spots <NUMBER> (default: 1)
 * 4: Origin, [col, row, compartment] to lie nearest to, [] for the first fit <ARRAY> (default: [])
 *
 * Return Value:
 * [spots, elsewhere] <ARRAY>
 *   spots     - one per tile asked for, [col, row, compartment, width, height, rot, holes] - holes the cells of that box the
 *               tile does not take, as it lies -, [] where none is free
 *   elsewhere - a cell was asked for and the first spot lies on another
 *
 * Example:
 * [_view, "ACE_fieldDressing", [], 1, [2, 0, 0]] call einv_storage_fnc_findSpots;
 *
 * Public: No
 */

params [
    ["_view", createHashMap, [createHashMap]],
    ["_class", "", [""]],
    ["_cell", [], [[]]],
    ["_count", 1, [0]],
    ["_origin", [], [[]]]
];

private _tiles = _view getOrDefault ["entries", []];

// The view's cells, per compartment rows of booleans, true where a tile lies or a shaped compartment
// has a hole (fnc_seedTaken).
private _blocks = _view getOrDefault ["blocks", []];
private _open = _view getOrDefault ["open", false];
private _taken = [_blocks] call FUNC(seedTaken);

// Compartments that accept only some categories or hold one item of any size (fnc_blockMode); none for most containers.
private _special = _blocks findIf {count _x > 4} >= 0;
private _groups = [];

private _fnc_mark = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {};

    [_taken select _block, (_blocks select _block) select 0, _col, _row, _w, _h, _holes] call FUNC(takeCells);
};

private _fnc_free = {
    params ["_block", "_col", "_row", "_w", "_h", ["_holes", []]];

    if (_block < 0 || {_block >= count _blocks}) exitWith {false};

    (_blocks select _block) params ["_cols", "_rows"];

    if (_col < 0 || {_row < 0} || {_col + _w > _cols} || {!_open && {_row + _h > _rows}}) exitWith {false};

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

// Whether a single slot has nothing in it yet.
private _fnc_slotFree = {
    params ["_block"];

    ([_blocks select _block] call FUNC(slotOf)) params ["_col", "_row", "_w", "_h", "_holes"];

    [_taken select _block, _col, _row, _w, _h, _holes] call FUNC(cellsFree)
};

// Compartment after compartment (in the order given, fnc_blockOrder), row by row - past the last row of an open grid everything
// is free. Cells are only ever taken from here on, so each search remembers per shape and compartment where it found its spot
// and the next one for that shape starts there.
private _resume = createHashMap;

private _fnc_firstFit = {
    params ["_w", "_h", ["_holes", []], ["_order", []]];

    private _found = [];
    private _shape = format ["%1x%2", _w, _h] + (["", str _holes] select (_holes isNotEqualTo []));
    private _from = _resume get _shape;

    if (isNil "_from") then {
        _from = _blocks apply {0};
        _resume set [_shape, _from];
    };

    private _plain = _holes isEqualTo [];

    {
        private _block = _x;

        (_blocks select _block) params ["_cols", "_rows"];

        // A single slot is one spot, whole, when it is empty (a compartment that refuses the item is not in the order).
        if (_special && {([_blocks select _block, _groups] call FUNC(blockMode)) == 1}) then {
            if ([_block] call _fnc_slotFree) then {
                _found = [0, 0, _block, true];

                break;
            };

            continue;
        };

        if (_cols < _w) then {continue};

        private _grid = _taken select _block;
        private _last = if (_open) then {count _grid} else {_rows - _h};
        private _start = _from select _block;

        for "_row" from (floor (_start / _cols)) to _last do {
            private _line = _grid param [_row, []];

            for "_col" from ((_start - _row * _cols) max 0) to (_cols - _w) do {
                // A taken first cell rules out any box that has one there (a hole of a shape may lie on it).
                if (_plain && {_line isNotEqualTo []} && {_line select _col}) then {continue};

                if ([_grid, _col, _row, _w, _h, _holes] call FUNC(cellsFree)) exitWith {
                    _found = [_col, _row, _block];
                    _from set [_block, _row * _cols + _col];
                };
            };

            if (_found isNotEqualTo []) exitWith {};
        };

        if (_found isNotEqualTo []) exitWith {};

        _from set [_block, (_last + 1) * _cols];
    } forEach _order;

    _found
};

// The free spot nearest to the origin; the origin's own compartment is looked through first, the others
// only when it has none.
private _fnc_nearest = {
    params ["_w", "_h", ["_holes", []], "_order"];

    private _best = [];
    private _bestDistance = 1e12;
    private _originBlock = _origin param [2, 0];
    private _order = [];

    if (_originBlock >= 0 && {_originBlock < count _blocks}) then {
        _order pushBack _originBlock;
    };

    for "_i" from 0 to (count _blocks - 1) do {
        if (_i != _originBlock) then {
            _order pushBack _i;
        };
    };

    {
        private _block = _x;

        (_blocks select _block) params ["_cols", "_rows"];

        if (_special) then {
            private _mode = [_blocks select _block, _groups] call FUNC(blockMode);

            if (_mode < 0) then {continue};

            if (_mode == 1) then {
                if ([_block] call _fnc_slotFree) then {
                    _best = [0, 0, _block, true];

                    break;
                };

                continue;
            };
        };

        private _last = if (_open) then {count (_taken select _block)} else {_rows - _h};

        for "_row" from 0 to _last do {
            for "_col" from 0 to (_cols - _w) do {
                if ([_block, _col, _row, _w, _h, _holes] call _fnc_free) then {
                    private _distance = [_col, _row] distanceSqr [_origin select 0, _origin select 1];

                    if (_distance < _bestDistance) then {
                        _bestDistance = _distance;
                        _best = [_col, _row, _block];
                    };
                };
            };
        };

        if (_best isNotEqualTo []) exitWith {};
    } forEach _order;

    _best
};

{
    if ((_x getOrDefault ["count", 1]) > 0 && {!(_x getOrDefault ["overflow", false])}) then {
        [
            _x getOrDefault ["block", -1], _x getOrDefault ["col", 0], _x getOrDefault ["row", 0],
            _x getOrDefault ["w", 1], _x getOrDefault ["h", 1], _x getOrDefault ["holes", []]
        ] call _fnc_mark;
    };
} forEach _tiles;

// The requested cell when it is free - in the item's size, the way round it says (rot, 1 turned a
// quarter clockwise; a cell without it is turned when not as wide as the item upright) -, else the
// first fit or the nearest, upright, then turned.
private _info = [_class] call EFUNC(items,getInfo);

(_info getOrDefault ["footprint", [1, 1, []]]) params [["_w", 1, [0]], ["_h", 1, [0]], ["_holes", [], [[]]]];
_cell params [["_col", -1, [0]], ["_row", -1, [0]], ["_block", 0, [0]], ["_cellW", _w, [0]], ["_cellH", _h, [0]], ["_cellRot", -1, [0]]];

if !(_cellRot in [0, 1]) then {
    _cellRot = parseNumber (_cellW != _w);
};

if (([[_w, _h], [_h, _w]] select (_cellRot == 1)) isNotEqualTo [_cellW, _cellH]) then {
    _cellW = _w;
    _cellH = _h;
    _cellRot = 0;
};

private _turnedHoles = (_info getOrDefault ["footprintTurned", [_h, _w, []]]) param [2, []];
private _spots = [];
private _elsewhere = false;

_groups = _info getOrDefault ["groups", ["misc"]];

// A single slot found, as a spot: the compartment whole, upright (fnc_slotOf).
private _fnc_slotSpot = {
    params ["_block"];

    ([_blocks select _block] call FUNC(slotOf)) params ["_slotCol", "_slotRow", "_slotW", "_slotH", "_slotHoles"];

    [_slotCol, _slotRow, _block, _slotW, _slotH, 0, _slotHoles]
};

// The compartments a first fit looks through, in tiers (fnc_blockOrder): those whose category lock includes one of the item's
// categories, then the unrestricted ones. [[]] for the nearest spot, which has its own order.
private _tiers = [[]];

if (_origin isEqualTo []) then {
    private _order = [_blocks, _groups] call FUNC(blockOrder);
    private _locked = _order select {count (_blocks select _x) > 4 && {((_blocks select _x) select 4) isNotEqualTo []}};

    _tiers = [_locked, _order - _locked] select {_x isNotEqualTo []};
};

for "_i" from 0 to (_count - 1) do {
    private _spot = [];

    // What the compartment asked for makes of it: refused (-1) it is no place, a single slot (1) takes it whole whatever
    // cell and size were asked for.
    private _mode = 0;

    if (_i == 0 && {_cell isNotEqualTo []} && {_special} && {_block >= 0} && {_block < count _blocks}) then {
        _mode = [_blocks select _block, _groups] call FUNC(blockMode);
    };

    if (_i == 0 && {_cell isNotEqualTo []} && {_mode == 1} && {[_block] call _fnc_slotFree}) then {
        _spot = [_block] call _fnc_slotSpot;
    } else {
        if (
            _i == 0 && {_cell isNotEqualTo []} && {_mode == 0}
            && {[_block, _col, _row, _cellW, _cellH, [_holes, _turnedHoles] select (_cellRot == 1)] call _fnc_free}
        ) then {
            _spot = [_col, _row, _block, _cellW, _cellH, _cellRot, [_holes, _turnedHoles] select (_cellRot == 1)];
        } else {
            private _fnc_pick = [_fnc_firstFit, _fnc_nearest] select (_origin isNotEqualTo []);
            private _found = [];
            private _turned = false;

            // Upright, else turned a quarter, in the compartments whose category lock includes the item's first, then in the
            // unrestricted ones. The nearest spot to an origin goes by distance and ignores the tiers.
            {
                _found = [_w, _h, _holes, _x] call _fnc_pick;
                _turned = false;

                if (_found isEqualTo [] && {_w != _h || {_holes isNotEqualTo _turnedHoles}}) then {
                    _found = [_h, _w, _turnedHoles, _x] call _fnc_pick;
                    _turned = _found isNotEqualTo [];
                };

                if (_found isNotEqualTo []) exitWith {};
            } forEach _tiers;

            if (_found isNotEqualTo []) then {
                _spot = if (count _found > 3) then {
                    [_found select 2] call _fnc_slotSpot
                } else {
                    _found + ([[_w, _h, 0, _holes], [_h, _w, 1, _turnedHoles]] select _turned)
                };
            };

            if (_i == 0) then {
                _elsewhere = _cell isNotEqualTo [] && {_spot isNotEqualTo []};
            };
        };
    };

    if (_spot isNotEqualTo []) then {
        _spot params ["_spotCol", "_spotRow", "_spotBlock", "_spotW", "_spotH", "_spotRot", "_spotHoles"];

        [_spotBlock, _spotCol, _spotRow, _spotW, _spotH, _spotHoles] call _fnc_mark;
    };

    _spots pushBack _spot;
};

[_spots, _elsewhere]
