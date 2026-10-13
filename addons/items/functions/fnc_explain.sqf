#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Why an item looks the way it does: every rule and config value that has a say about it, highest
 * first, with what each sets and which of that it wins - for the setup wizard's "Why?" and for anyone
 * puzzling over a size in the debug console. Walks the same layers as fnc_resolve, but does not stop
 * at the first answer.
 *
 * Arguments:
 * 0: Class name <STRING>
 * 1: Compiled rules <HASHMAP> (default: the rules in effect)
 *
 * Return Value:
 * [[layer, index, statement, fields it sets, fields it wins], ...], highest first <ARRAY>
 *   layer     - "forced", "own", "legacy:<setting>", "mod", "preset:<preset>" or "builtin" <STRING>
 *   index     - the rule's place in its text, -1 for config and the fallbacks <NUMBER>
 *   statement - the rule as the writer has it, or the config value; "" for the fallbacks <STRING>
 *   fields    - of "footprint", "stack", "grid", "weight", "name" <ARRAY>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag"] call einv_items_fnc_explain;
 *
 * Public: Yes
 */

params [["_class", "", [""]], ["_compiled", nil, [createHashMap]]];

if (isNil "_compiled") then {
    _compiled = call FUNC(currentRules);
};

private _facts = [_class] call FUNC(getFacts);
private _kind = _facts get "kind";
private _fields = ["footprint", "weight", "name"];

if !(_kind in KINDS_SINGLE) then {
    _fields pushBack "stack";
};

if (_kind in KINDS_CONTAINER) then {
    _fields pushBack "grid";
};

private _open = +_fields;
private _lines = [];
private _memo = createHashMap;

// Weapons and containers are alone on their tile whatever anyone says.
if (_kind in KINDS_SINGLE) then {
    _lines pushBack ["forced", -1, "", ["stack"], ["stack"]];
};

((_compiled getOrDefault ["byKind", createHashMap]) getOrDefault [_kind, [[], [], [], []]]) params ["_ownIndices", "_presetIndices"];

// The tag "own:3" or "preset:default:12" as [layer, index].
private _fnc_place = {
    params ["_tag"];

    private _parts = _tag splitString ":";
    private _index = parseNumber (_parts deleteAt (count _parts - 1));

    [_parts joinString ":", _index]
};

private _fnc_walk = {
    params ["_rules", "_indices"];

    {
        (_rules select _x) params ["_conds", "_values", "_tag", "_text"];

        private _offers = keys _values;

        // like= sets what the rule does not set itself from another class (fnc_resolve).
        if ("like" in _values) then {
            _offers append LIKE_FIELDS;
        };

        private _sets = _offers arrayIntersect _fields;

        if (_sets isNotEqualTo [] && {[_facts, _conds, _compiled, _memo] call FUNC(matches)}) then {
            private _wins = _sets arrayIntersect _open;

            _open = _open - _wins;

            ([_tag] call _fnc_place) params ["_layer", "_index"];

            _lines pushBack [_layer, _index, _text, _sets, _wins];
        };
    } forEach _indices;
};

[_compiled getOrDefault ["own", []], _ownIndices] call _fnc_walk;

// The item's own mod, as fnc_resolve reads it.
private _mod = _facts get "mod";

{
    _x params ["_field", "_key", "_text"];

    if (_field in _fields && {_key in _mod}) then {
        private _wins = [_field] arrayIntersect _open;

        _open = _open - _wins;
        _lines pushBack ["mod", -1, _text, [_field], _wins];
    };
} forEach [
    ["footprint", "gridSize", format ["%1[] = %2", QGVARMAIN(gridSize), str (_mod getOrDefault ["gridSize", []])]],
    ["stack", "stackSize", format ["%1 = %2", QGVARMAIN(stackSize), _mod getOrDefault ["stackSize", 0]]],
    ["grid", "grids", format ["%1[] = %2", QGVARMAIN(grids), str (_mod getOrDefault ["grids", []])]],
    ["grid", "slots", format ["%1 = %2", QGVARMAIN(slots), _mod getOrDefault ["slots", 0]]]
];

[_compiled getOrDefault ["preset", []], _presetIndices] call _fnc_walk;

if (_open isNotEqualTo []) then {
    _lines pushBack ["builtin", -1, "", _open, _open];
};

_lines
