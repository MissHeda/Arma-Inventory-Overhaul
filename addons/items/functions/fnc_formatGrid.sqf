#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a container's grid as "grid=" in the rules has it - the way back from fnc_parseGrid, so a
 * text read and written again stays the same.
 *
 * A compartment with holes is drawn as its shape, rows separated by "/" ("x" a cell, "-" a hole); one
 * without is written WxH, the shorter of the two (fnc_formatMask, which an item's size= shares).
 *
 * Compartments that lie where they were drawn (a pos of their own) are written as one canvas, where
 * each cell carries its compartment's letter: "a" for the one whose first cell comes first reading
 * from the top left, "b" for the next and so on - the order fnc_parseGrid gives them back in, so a
 * single row without a hole reads as a canvas again. The canvas stands where the first of them
 * stood among the others. A canvas of one compartment is only that compartment, written as above.
 *
 * A compartment that accepts only some categories or is a single slot (a fifth and sixth element of its block,
 * fnc_parseGrid) has them after a colon: "2x2:ammo|grenade", "1x1:grenade|one"; on a canvas each letter's
 * after the canvas, "aab/aab:a=ammo:b=grenade|one". A compartment without any is written as it always was.
 *
 * Arguments:
 * 0: Spec, as fnc_parseGrid gives it <ARRAY>
 *
 * Return Value:
 * Grid text: "auto", "24", "120%", "rig", "rig:16", "6x4+2x3", "xxx/x-x+2x3" or "aaa/aba/aaa"; "" for
 * an empty spec
 * <STRING>
 *
 * Example:
 * [["blocks", [[6, 4, []], [3, 2, [4]]]]] call einv_items_fnc_formatGrid; // "6x4+xxx/x-x"
 * [["blocks", [[3, 3, [4], [0, 0]], [1, 1, [], [1, 1]]]]] call einv_items_fnc_formatGrid; // "aaa/aba/aaa"
 *
 * Public: No
 */

params [["_spec", [], [[]]]];

_spec params [["_mode", "", [""]]];

// The compartments that lie on a canvas, as one mask: the box around them, every place without a cell
// of theirs a "-".
private _fnc_canvas = {
    params ["_placed"];

    private _minX = selectMin (_placed apply {(_x select 3) select 0});
    private _minY = selectMin (_placed apply {(_x select 3) select 1});
    private _width = selectMax (_placed apply {((_x select 3) select 0) + (_x select 0)}) - _minX;
    private _height = selectMax (_placed apply {((_x select 3) select 1) + (_x select 1)}) - _minY;
    private _chars = [];
    private _order = [];
    private _letterOf = _placed apply {""};

    _chars resize (_width * _height);
    _chars = _chars apply {"-"};

    // Each one's cells on the canvas, and where its first one lies - which decides its letter.
    private _cells = _placed apply {
        _x params ["_cols", "_rows", ["_holes", []], "_pos"];

        private _own = [];

        for "_r" from 0 to (_rows - 1) do {
            for "_c" from 0 to (_cols - 1) do {
                if !((_r * _cols + _c) in _holes) then {
                    _own pushBack (((_pos select 1) - _minY + _r) * _width + (_pos select 0) - _minX + _c);
                };
            };
        };

        _own
    };

    {
        _order pushBack [selectMin (_x + [1e9]), _forEachIndex];
    } forEach _cells;

    _order sort true;

    {
        private _letter = "abcdefghijklmnopqrstuvwxyz" select [_forEachIndex min 25, 1];

        _letterOf set [_x select 1, _letter];

        {
            _chars set [_x, _letter];
        } forEach (_cells select (_x select 1));
    } forEach _order;

    private _lines = [];

    for "_r" from 0 to (_height - 1) do {
        _lines pushBack ((_chars select [_r * _width, _width]) joinString "");
    };

    [_lines joinString "/", _letterOf]
};

switch (_mode) do {
    case "auto": {"auto"};
    case "cells": {str (_spec select 1)};
    case "percent": {str (_spec select 1) + "%"};
    case "pattern": {
        _spec params ["", "_name", ["_cells", -1]];

        [_name, format ["%1:%2", _name, _cells]] select (_cells > 0)
    };
    case "blocks": {
        private _blocks = _spec select 1;
        private _placed = _blocks select {(_x param [3, []]) isNotEqualTo []};
        private _onCanvas = count _placed > 1;
        private _parts = [];
        private _written = false;

        // The attributes of a block, after a colon: its categories joined with |, and "one" for a single slot.
        private _fnc_attrs = {
            params ["_block"];

            private _words = ITEM_GROUPS select {_x in (_block param [4, []])};

            if (_block param [5, false]) then {
                _words pushBack "one";
            };

            _words joinString "|"
        };

        {
            if (_onCanvas && {(_x param [3, []]) isNotEqualTo []}) then {
                if (!_written) then {
                    ([_placed] call _fnc_canvas) params ["_text", "_letters"];

                    // Each compartment with attributes has its letter's after the canvas, in the order of the letters.
                    private _tails = [];

                    {
                        private _attrs = [_x] call _fnc_attrs;

                        if (_attrs isNotEqualTo "") then {
                            _tails pushBack [_letters select _forEachIndex, _attrs];
                        };
                    } forEach _placed;

                    _tails sort true;

                    _parts pushBack (_text + ((_tails apply {format [":%1=%2", _x select 0, _x select 1]}) joinString ""));
                    _written = true;
                };
            } else {
                private _attrs = [_x] call _fnc_attrs;
                private _piece = [_x select 0, _x select 1, _x param [2, []]] call FUNC(formatMask);

                _parts pushBack ([_piece, _piece + ":" + _attrs] select (_attrs isNotEqualTo ""));
            };
        } forEach _blocks;

        _parts joinString "+"
    };
    default {""};
}
