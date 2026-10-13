#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the rules make of a class, in a few words, and where that comes from - for the lists and editors
 * of the Items and Containers steps:
 *
 *   grid  - "6x4, 2 holes" "your rule";  "3 × 1x2" "preset";  "Pockets, 4 cells" "preset";
 *           "6x4" "same as V_PlateCarrier1_rgr" when the class's own rule takes it from another class;
 *           "3 compartments in a 7×7 drawing" for the ones drawn where they lie (grid=aab/acc);
 *           "no room by default" for a grid by load on a class whose config holds nothing - a cosmetic
 *           backpack, a radio pack - which only an own grid gives cells
 *   size  - "2x3" "preset"
 *   stack - "5 per tile" "your rule"
 * The lists and editors show the two as one line, "6x4 (your rule)" (STR_einv_setup_Answer_Line).
 *
 * Compartments that follow each other with the same size and holes are counted rather than listed again.
 *
 * Arguments:
 * 0: The class, as einv_items_fnc_getInfo gives it <HASHMAP>
 * 1: Field: "grid", "size" or "stack" <STRING>
 * 2: The values of the class's own rule (fnc_ownClassRules) <HASHMAP> (default: none)
 *
 * Return Value:
 * [words, where it comes from] <ARRAY of STRING>
 *
 * Example:
 * [["V_PlateCarrier1_rgr", einv_setup_draftRules, einv_setup_draftCache] call einv_items_fnc_getInfo, "grid"] call einv_setup_fnc_answerText;
 *
 * Public: No
 */

params [["_info", createHashMap, [createHashMap]], ["_field", "grid", [""]], ["_own", createHashMap, [createHashMap]]];

private _key = ["footprint", _field] select (_field isNotEqualTo "size");

private _words = switch (_field) do {
    case "size": {
        // A shaped item (size=xx/x-) in words: its cells and the box around them.
        (_info getOrDefault ["footprint", [1, 1, []]]) params ["_cols", "_rows", ["_holes", []]];

        [_info getOrDefault ["shape", "1x1"], format [LLSTRING(Value_SizeShape), _cols, _rows, _cols * _rows - count _holes]] select (_holes isNotEqualTo [])
    };
    case "stack": {format [LLSTRING(Answer_Stack), _info getOrDefault ["stack", 1]]};
    default {
        private _spec = _info getOrDefault ["grid", []];

        _spec params [["_mode", "", [""]]];

        // By load, with a config that holds nothing: no cell at all, until a rule gives it some.
        private _noRoom = (_mode in ["auto", "percent"] || {_mode isEqualTo "pattern" && {(_spec param [2, -1]) <= 0}})
            && {(_info getOrDefault ["maxLoad", 0]) <= 0};

        if (_noRoom) then {
            LLSTRING(Answer_NoRoom)
        } else {
            switch (_mode) do {
                case "blocks": {
                    private _blocks = _spec select 1;
                    private _placed = _blocks select {(_x param [3, []]) isNotEqualTo []};
                    private _parts = [];
                    private _run = 0;

                    // The canvas in one go, where its first compartment stands.
                    if (count _placed > 1) then {
                        private _canvasW = selectMax (_placed apply {((_x select 3) select 0) + (_x select 0)});
                        private _canvasH = selectMax (_placed apply {((_x select 3) select 1) + (_x select 1)});
                        private _first = _blocks findIf {(_x param [3, []]) isNotEqualTo []};

                        // select and + rather than deleteRange/insert: nothing newer than REQUIRED_VERSION is used.
                        _blocks = (_blocks select [0, _first])
                            + [format [LLSTRING(Value_GridCanvas), count _placed, _canvasW, _canvasH]]
                            + (_blocks select [_first + count _placed]);
                    };

                    {
                        if (_x isEqualType "") then {
                            _parts pushBack _x;
                            continue;
                        };

                        _x params ["_cols", "_rows", ["_holes", []]];

                        _run = _run + 1;

                        if ((_blocks param [_forEachIndex + 1, []]) isNotEqualTo _x) then {
                            private _word = format ["%1x%2", _cols, _rows];

                            if (_holes isNotEqualTo []) then {
                                _word = format [LLSTRING(Answer_Holes), _word, count _holes];
                            };

                            if (_run > 1) then {
                                _word = format [LLSTRING(Answer_Run), _run, _word];
                            };

                            _parts pushBack _word;
                            _run = 0;
                        };
                    } forEach _blocks;

                    [_parts joinString " + ", "-"] select (_parts isEqualTo [])
                };
                case "auto": {LLSTRING(Answer_ByLoad)};
                case "cells": {format [LLSTRING(Cont_Cells), _spec select 1]};
                case "percent": {format [LLSTRING(Answer_Percent), _spec select 1]};
                case "pattern": {
                    // Its name as the wizard says it ("Magazine rig"), not as the rules write it (rig:16).
                    _spec params ["", "_name", ["_count", -1]];

                    private _key = format ["STR_einv_setup_Pattern_%1", _name];
                    private _word = if (isLocalized _key) then {localize _key} else {_name};

                    [_word, format ["%1, %2", _word, format [LLSTRING(Cont_Cells), _count]]] select (_count > 0)
                };
                default {"-"};
            };
        };
    };
};

// Where it comes from: the source tags of einv_items_fnc_resolve.
private _src = (_info getOrDefault ["src", createHashMap]) getOrDefault [_key, "builtin"];
private _like = _own getOrDefault ["like", ""];

private _from = switch (true) do {
    case ((_src select [0, 4]) isEqualTo "own:"): {
        // The class's own rule names another class and sets nothing of this field itself: that class
        // gave it.
        [LLSTRING(Answer_Own), format [LLSTRING(Answer_Like), _like]] select (_like isNotEqualTo "" && {!(_key in _own)})
    };
    case ((_src select [0, 7]) isEqualTo "legacy:"): {LLSTRING(Answer_Legacy)};
    case ((_src select [0, 7]) isEqualTo "preset:"): {LLSTRING(Answer_Preset)};
    case ((_src select [0, 4]) isEqualTo "mod:"): {LLSTRING(Answer_Mod)};
    case (_src isEqualTo "forced"): {LLSTRING(Answer_Forced)};
    default {LLSTRING(Answer_Builtin)};
};

[_words, _from]
