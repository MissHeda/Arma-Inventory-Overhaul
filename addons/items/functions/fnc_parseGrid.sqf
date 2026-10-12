#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads how a container is split into compartments, as "grid=" in the rules and the object variable
 * einv_grid write it. einv_storage_fnc_blocksFor lays a container out by the result.
 *
 *   auto          - by its load: maximum load / mass per cell cells, laid out the way its kind is
 *                   (pockets, pouches, one big compartment)
 *   24            - that many cells, laid out the same way, met exactly
 *   120%          - that share of what its load gives, 10 to 500 %
 *   rig, rig:16   - a pattern by name, with its cells from the load or given: pockets,
 *                   pockets_mixed, rig, mixed, plate, long, single, wide
 *   6x4+2x3+2x3   - the compartments exactly, each W cells across and H down
 *
 * Within limits: at most STORAGE_COLS across, MAX_ROWS down, MAX_BLOCKS compartments and MAX_CELLS
 * cells in all - the window makes a control per cell. A value past a limit is cut down to it and said
 * so in the messages; one that cannot be read gives no spec at all.
 *
 * Arguments:
 * 0: Grid text <STRING>
 *
 * Return Value:
 * [spec, messages] <ARRAY>
 *   spec     - ["auto"], ["cells", N], ["percent", P], ["pattern", name, N or -1] or
 *              ["blocks", [[cols, rows], ...]]; [] when the text cannot be read <ARRAY>
 *   messages - what was cut down, or why it cannot be read <ARRAY of STRING>
 *
 * Example:
 * ["6x4+2x3"] call einv_items_fnc_parseGrid;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _value = toLowerANSI (trim _text);
private _messages = [];

// A whole number written out in digits, else -1.
private _fnc_whole = {
    params ["_digits"];

    if (_digits isEqualTo "" || {(toArray _digits) findIf {_x < 48 || {_x > 57}} >= 0}) exitWith {-1};

    parseNumber _digits
};

// A number of cells: at least one, at most MAX_CELLS.
private _fnc_cells = {
    params ["_cells"];

    if (_cells < 1) then {
        _messages pushBack format ["grid=%1: a container has at least one cell - read as 1", _value];
        _cells = 1;
    };

    if (_cells > MAX_CELLS) then {
        _messages pushBack format ["grid=%1: at most %2 cells - cut down", _value, MAX_CELLS];
        _cells = MAX_CELLS;
    };

    _cells
};

private _colon = _value find ":";
private _name = _value;

if (_colon >= 0) then {
    _name = _value select [0, _colon];
};

// The last character, for a share like 120%.
private _last = "";

if (_value isNotEqualTo "") then {
    _last = _value select [count _value - 1];
};

private _spec = switch (true) do {
    case (_value isEqualTo ""): {
        _messages pushBack "an empty grid= says nothing";
        []
    };

    case (_value isEqualTo "auto"): {["auto"]};

    case ([_value] call _fnc_whole >= 0): {
        ["cells", [[_value] call _fnc_whole] call _fnc_cells]
    };

    // A "%" goes into the messages as an argument: in format's own text it could be taken for one.
    case (_last isEqualTo "%" && {[_value select [0, count _value - 1]] call _fnc_whole >= 0}): {
        private _percent = [_value select [0, count _value - 1]] call _fnc_whole;
        private _clamped = (_percent max PERCENT_MIN) min PERCENT_MAX;

        if (_clamped != _percent) then {
            _messages pushBack format ["grid=%1: a share is between %2 and %3 - cut to %4", _value, PERCENT_MIN, PERCENT_MAX, str _clamped + "%"];
        };

        ["percent", _clamped]
    };

    case (_name in GRID_PATTERNS): {
        if (_colon < 0) then {
            ["pattern", _name, -1]
        } else {
            private _cells = [_value select [_colon + 1]] call _fnc_whole;

            if (_cells < 0) then {
                _messages pushBack format ["'%1' is no grid: after the pattern's name comes a number of cells, like rig:16", _value];
                []
            } else {
                ["pattern", _name, [_cells] call _fnc_cells]
            };
        };
    };

    case (_value find "x" >= 0): {
        // Compartments: each piece WxH, both at least 1.
        private _blocks = (_value splitString "+") apply {
            private _cross = _x find "x";

            if (_cross < 0) then {
                [-1, -1]
            } else {
                [[_x select [0, _cross]] call _fnc_whole, [_x select [_cross + 1]] call _fnc_whole]
            };
        };

        if (_blocks isEqualTo [] || {_blocks findIf {(_x select 0) < 1 || {(_x select 1) < 1}} >= 0}) then {
            _messages pushBack format ["'%1' is no grid: compartments are written like 6x4+2x3, each at least 1x1", _value];
            []
        } else {
            if (_blocks findIf {(_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}} >= 0) then {
                _messages pushBack format ["grid=%1: a compartment is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                _blocks = _blocks apply {[(_x select 0) min STORAGE_COLS, (_x select 1) min MAX_ROWS]};
            };

            if (count _blocks > MAX_BLOCKS) then {
                _messages pushBack format ["grid=%1: at most %2 compartments - the rest are left out", _value, MAX_BLOCKS];
                _blocks resize MAX_BLOCKS;
            };

            // Whole compartments only: the ones past MAX_CELLS cells in all are left out.
            private _total = 0;
            private _kept = [];

            {
                _total = _total + (_x select 0) * (_x select 1);

                if (_total > MAX_CELLS) exitWith {
                    _messages pushBack format ["grid=%1: at most %2 cells in all - the compartments past that are left out", _value, MAX_CELLS];
                };

                _kept pushBack _x;
            } forEach _blocks;

            if (_kept isEqualTo []) then {[]} else {["blocks", _kept]};
        };
    };

    default {
        _messages pushBack format ["'%1' is no grid: auto, a number of cells, a share like %3, a pattern (%2) or compartments like 6x4+2x3", _value, GRID_PATTERNS joinString ", ", "120%"];
        []
    };
};

[_spec, _messages]
