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
 *   xxxx/x--x+2x3 - a compartment may also be drawn as a shape: its rows from the top, separated by
 *                   "/", each the same length, "x" a cell and "-" a hole - a cell the compartment does
 *                   not have. Joined with "+" like the others, and mixed with them.
 *
 * A shape is read to its smallest form (fnc_parseMask, which reads an item's size= the same way): rows
 * and columns at its edges that are only holes go, and a shape with no hole left is a plain WxH -
 * fnc_formatGrid writes it as 2x3 again. The separator is
 * "/" because it is the one character the rules already allow that reads as "next row"; a row can
 * never be empty, so "//" - which a cba_settings.sqf could take for a comment - is never part of a
 * grid.
 *
 * Within limits: at most STORAGE_COLS across, MAX_ROWS down, MAX_BLOCKS compartments and MAX_CELLS
 * cells in all, holes not counted - the window makes a control per cell. A value past a limit is cut
 * down to it and said so in the messages (a shape loses its columns and rows past the limit); one
 * that cannot be read, or a shape without a single cell, gives no spec at all.
 *
 * Arguments:
 * 0: Grid text <STRING>
 *
 * Return Value:
 * [spec, messages] <ARRAY>
 *   spec     - ["auto"], ["cells", N], ["percent", P], ["pattern", name, N or -1] or
 *              ["blocks", [[cols, rows, holes], ...]] - holes the indices row * cols + col of the
 *              cells a shape does not have, ascending, [] for a full rectangle; [] when the text
 *              cannot be read <ARRAY>
 *   messages - what was cut down, or why it cannot be read <ARRAY of STRING>
 *
 * Example:
 * ["6x4+xxx/x-x"] call einv_items_fnc_parseGrid;
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

// A compartment cut down to STORAGE_COLS across and MAX_ROWS down. A shape is drawn again and read once
// more within those limits (fnc_formatMask, fnc_parseMask), so it comes out at its smallest as any
// other; with no cell left it is [0, 0, []] and left out.
private _fnc_cut = {
    params ["_cols", "_rows", "_holes"];

    if (_holes isEqualTo []) exitWith {[_cols min STORAGE_COLS, _rows min MAX_ROWS, []]};

    [[_cols, _rows, _holes] call FUNC(formatMask), STORAGE_COLS, MAX_ROWS] call FUNC(parseMask)
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

    case (_value find "x" >= 0 || {_value find "-" >= 0} || {_value find "/" >= 0}): {
        // Compartments: each piece WxH, both at least 1, or a shape. A piece that cannot be read is
        // [-1, -1, error].
        private _blocks = (_value splitString "+") apply {
            if ((toArray _x) findIf {_x >= 48 && {_x <= 57}} < 0) then {
                [_x] call FUNC(parseMask)
            } else {
                private _cross = _x find "x";

                if (_cross < 0) then {
                    [-1, -1, ""]
                } else {
                    [[_x select [0, _cross]] call _fnc_whole, [_x select [_cross + 1]] call _fnc_whole, []]
                };
            };
        };

        private _bad = _blocks findIf {(_x select 0) < 1 || {(_x select 1) < 1}};

        if (_blocks isEqualTo [] || {_bad >= 0}) then {
            // A shape says what is wrong with it; a WxH piece holds its holes there, which are no words.
            private _why = if (_bad >= 0) then {(_blocks select _bad) select 2} else {""};

            if (!(_why isEqualType "") || {_why isEqualTo ""}) then {
                _why = "compartments are written like 6x4+2x3 or drawn like xxx/x-x, each at least one cell";
            };

            _messages pushBack format ["'%1' is no grid: %2", _value, _why];
            []
        } else {
            if (_blocks findIf {(_x select 0) > STORAGE_COLS || {(_x select 1) > MAX_ROWS}} >= 0) then {
                _messages pushBack format ["grid=%1: a compartment is at most %2 across and %3 down - cut down", _value, STORAGE_COLS, MAX_ROWS];
                _blocks = _blocks apply {_x call _fnc_cut};
            };

            if (count _blocks > MAX_BLOCKS) then {
                _messages pushBack format ["grid=%1: at most %2 compartments - the rest are left out", _value, MAX_BLOCKS];
                _blocks resize MAX_BLOCKS;
            };

            // Whole compartments only: the ones past MAX_CELLS cells in all are left out. A shape that
            // lost all its cells to a cut is left out the same way.
            private _total = 0;
            private _kept = [];

            {
                _x params ["_cols", "_rows", "_holes"];

                private _cells = _cols * _rows - count _holes;

                _total = _total + _cells;

                if (_total > MAX_CELLS) exitWith {
                    _messages pushBack format ["grid=%1: at most %2 cells in all - the compartments past that are left out", _value, MAX_CELLS];
                };

                if (_cells > 0) then {
                    _kept pushBack _x;
                };
            } forEach _blocks;

            if (_kept isEqualTo []) then {[]} else {["blocks", _kept]};
        };
    };

    default {
        _messages pushBack format ["'%1' is no grid: auto, a number of cells, a share like %3, a pattern (%2) or compartments like 6x4+2x3 or xxx/x-x", _value, GRID_PATTERNS joinString ", ", "120%"];
        []
    };
};

[_spec, _messages]
