#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a container's grid as "grid=" in the rules has it - the way back from fnc_parseGrid, so a
 * text read and written again stays the same.
 *
 * A compartment with holes is drawn as its shape, rows separated by "/" ("x" a cell, "-" a hole); one
 * without is written WxH, the shorter of the two.
 *
 * Arguments:
 * 0: Spec, as fnc_parseGrid gives it <ARRAY>
 *
 * Return Value:
 * Grid text: "auto", "24", "120%", "rig", "rig:16", "6x4+2x3" or "xxx/x-x+2x3"; "" for an empty spec
 * <STRING>
 *
 * Example:
 * [["blocks", [[6, 4, []], [3, 2, [4]]]]] call einv_items_fnc_formatGrid;
 *
 * Public: No
 */

params [["_spec", [], [[]]]];

_spec params [["_mode", "", [""]]];

switch (_mode) do {
    case "auto": {"auto"};
    case "cells": {str (_spec select 1)};
    case "percent": {str (_spec select 1) + "%"};
    case "pattern": {
        _spec params ["", "_name", ["_cells", -1]];

        [_name, format ["%1:%2", _name, _cells]] select (_cells > 0)
    };
    case "blocks": {
        ((_spec select 1) apply {
            _x params ["_cols", "_rows", ["_holes", []]];

            if (_holes isEqualTo []) then {
                format ["%1x%2", _cols, _rows]
            } else {
                private _lines = [];

                for "_r" from 0 to (_rows - 1) do {
                    private _line = "";

                    for "_c" from 0 to (_cols - 1) do {
                        _line = _line + (["x", "-"] select ((_r * _cols + _c) in _holes));
                    };

                    _lines pushBack _line;
                };

                _lines joinString "/"
            };
        }) joinString "+"
    };
    default {""};
}
