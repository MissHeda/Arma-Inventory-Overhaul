#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads one of the older text settings that give sizes, stacks or container grids by class:
 *   sizes  - einv_items_sizeTable, "class:WxH, class:WxH", W across and H down,
 *            e.g. "rhs_mag_30Rnd_556x45_M855A1_Stanag:1x2, rhsusf_100Rnd_762x51:1x3"
 *   stacks - einv_items_stackTable, "class:N, class:N",
 *            e.g. "ACE_fieldDressing:20, ACE_morphine:5"
 *   grids  - einv_storage_containerTable, "class:N" for that many cells, laid out the way the
 *            container's kind lays out its load, or "class:WxH+WxH" for the compartments exactly,
 *            e.g. "B_AssaultPack_rgr:30, V_PlateCarrier1_rgr:4x2+2x2"
 * fnc_compileRules turns what this reads into rules of their own, after the rules text - so the
 * tables keep winning over it, as they did before there were rules.
 *
 * Commas part the entries; semicolons and line breaks do too, so a list pasted from anywhere still
 * reads. Spaces do not matter anywhere, and a size takes "x" or "X" between its two numbers. An
 * entry that does not read is left out with a warning that names it, so one typo does not throw away
 * the rest of the list. When a class is listed twice, the later entry wins.
 *
 * Limits as before: a size at most STORAGE_COLS across, a stack and a number of cells at least 1,
 * compartments at least 1x1 and at most STORAGE_COLS by MAX_ROWS, a number of cells at most
 * MAX_CELLS. New: at most MAX_BLOCKS compartments and MAX_CELLS cells in all - the ones past that are
 * left out.
 *
 * Arguments:
 * 0: The setting's text <STRING>
 * 1: What it holds: "size", "stack" or "grid" <STRING>
 * 2: Where the warnings go; without it they go to the RPT <ARRAY> (default: nil)
 *
 * Return Value:
 * Lowercase class -> [w, h] for sizes, how many share a tile for stacks, ["cells", N] or
 * ["blocks", [[cols, rows], ...]] for grids <HASHMAP>
 *
 * Example:
 * ["ACE_fieldDressing:20, ACE_morphine:5", "stack"] call einv_items_fnc_parseTable;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_type", "stack", [""]], ["_warnings", nil, [[]]]];

private _table = createHashMap;

private _fnc_warn = {
    params ["_message"];

    if (isNil "_warnings") then {
        WARNING(_message);
    } else {
        _warnings pushBack _message;
    };
};

// A whole number only when every character is a digit - "10" yes, "1.5", "-2" or "10a" no. Anything
// else comes back as -1.
private _fnc_number = {
    params ["_string"];

    if (_string isEqualTo "" || {(toArray _string) findIf {_x < 48 || {_x > 57}} != -1}) exitWith {-1};

    parseNumber _string
};

{
    // Class names hold no spaces, so every space and tab can go: "ACE_morphine : 5" reads as well.
    private _entry = (_x splitString (toString [32, 9])) joinString "";

    // Blank between two commas - a trailing comma, say - is nothing to warn about.
    if (_entry isEqualTo "") then {continue};

    private _colon = _entry find ":";

    // Without a colon the class stays "" and the entry is reported below.
    private _class = toLowerANSI (_entry select [0, (_colon max 0)]);
    private _value = toLowerANSI (_entry select [_colon + 1]);

    switch (_type) do {
        case "size": {
            private _cross = _value find "x";
            private _w = [_value select [0, (_cross max 0)]] call _fnc_number;
            private _h = [_value select [_cross + 1]] call _fnc_number;

            if (_class isEqualTo "" || {_cross < 0} || {_w < 1} || {_h < 1}) then {
                [format ["Grid size table: '%1' is not class:WxH - left out.", _entry]] call _fnc_warn;
            } else {
                _table set [_class, [_w min STORAGE_COLS, _h min MAX_ROWS]];
            };
        };
        case "grid": {
            private _cells = [_value] call _fnc_number;

            // Compartments: each piece "WxH", -1 where a side is no number.
            private _blocks = (_value splitString "+") apply {
                private _cross = _x find "x";

                if (_cross < 0) then {
                    [-1, -1]
                } else {
                    [[_x select [0, _cross]] call _fnc_number, [_x select [_cross + 1]] call _fnc_number]
                };
            };

            switch (true) do {
                case (_class isEqualTo "" || {_value isEqualTo ""}): {
                    [format ["Container table: '%1' is no class:size pair - left out.", _entry]] call _fnc_warn;
                };
                case (_cells >= 0): {
                    _table set [_class, ["cells", (_cells max 1) min MAX_CELLS]];
                };
                case (_blocks isEqualTo [] || {_blocks findIf {(_x select 0) < 0 || {(_x select 1) < 0}} >= 0}): {
                    [format ["Container table: '%1' is neither a number of cells nor compartments like 6x4+2x3 - left out.", _entry]] call _fnc_warn;
                };
                default {
                    _blocks = _blocks apply {[((_x select 0) max 1) min STORAGE_COLS, ((_x select 1) max 1) min MAX_ROWS]};

                    if (count _blocks > MAX_BLOCKS) then {
                        [format ["Container table: '%1' has more than %2 compartments - the rest are left out.", _entry, MAX_BLOCKS]] call _fnc_warn;
                        _blocks resize MAX_BLOCKS;
                    };

                    // Whole compartments only: the ones past MAX_CELLS cells in all are left out.
                    private _total = 0;
                    private _kept = [];

                    {
                        _total = _total + (_x select 0) * (_x select 1);

                        if (_total > MAX_CELLS) exitWith {
                            [format ["Container table: '%1' has more than %2 cells - the compartments past that are left out.", _entry, MAX_CELLS]] call _fnc_warn;
                        };

                        _kept pushBack _x;
                    } forEach _blocks;

                    _table set [_class, ["blocks", _kept]];
                };
            };
        };
        default {
            private _count = [_value] call _fnc_number;

            if (_class isEqualTo "" || {_count < 0}) then {
                [format ["Stack table: '%1' is not class:N - left out.", _entry]] call _fnc_warn;
            } else {
                // A tile always holds at least one, so 0 reads as 1: no stacking.
                _table set [_class, _count max 1];
            };
        };
    };
} forEach (_text splitString (toString [44, 59, 10, 13]));

_table
