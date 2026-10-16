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
 *   layer     - "forced", "own", "legacy:<setting>", "mod", "preset:<preset>", "all" (the text's rules
 *               for everything else, after the preset) or "builtin" <STRING>
 *   index     - the rule's place in its text, -1 for config, "forced" and "builtin" <NUMBER>
 *   statement - the rule as the writer has it, or the config value; "" for "forced" and "builtin" <STRING>
 *   fields    - of "footprint", "stack", "grid", "weight", "name", "icon" <ARRAY>
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
private _fields = ["footprint", "weight", "name", "icon"];

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

((_compiled getOrDefault ["byKind", createHashMap]) getOrDefault [_kind, [[], [], [], []]]) params [
    "_ownIndices", "_presetIndices", "", "", ["_fallbackIndices", []]
];

// The tag "own:3" or "preset:default:12" as [layer, index].
private _fnc_place = {
    params ["_tag"];

    private _parts = _tag splitString ":";
    private _index = parseNumber (_parts deleteAt (count _parts - 1));

    [_parts joinString ":", _index]
};

// The preset's rules without conditions, its own everything else, as fnc_resolve has them: what one of
// them wins, the text's "all" rules may still take - [line, field] each.
private _caught = [];

private _fnc_walk = {
    params ["_rules", "_indices", ["_noteCaught", false]];

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

            private _line = _lines pushBack [_layer, _index, _text, _sets, _wins];

            if (_noteCaught && {_conds isEqualTo []}) then {
                {
                    _caught pushBack [_line, _x];
                } forEach _wins;
            };
        };
    } forEach _indices;
};

[_compiled getOrDefault ["own", []], _ownIndices] call _fnc_walk;

// The item's own mod, as fnc_resolve reads it: the keys written like the rules first, then the older
// ones, so the line that wins a field is the first one of that field.
private _mod = _facts get "mod";

private _fnc_size = {
    params ["_value"];

    if (_value isEqualType "") then {_value} else {_value call FUNC(formatMask)}
};

{
    _x params ["_field", "_key", "_text"];

    if (_field in _fields && {_key in _mod}) then {
        private _wins = [_field] arrayIntersect _open;

        _open = _open - _wins;
        _lines pushBack ["mod", -1, _text, [_field], _wins];
    };
} forEach [
    ["footprint", "size", format ["%1 = %2", QGVARMAIN(size), [_mod getOrDefault ["size", ""]] call _fnc_size]],
    ["footprint", "gridSize", format ["%1[] = %2", QGVARMAIN(gridSize), str (_mod getOrDefault ["gridSize", []])]],
    ["stack", "stack", format ["%1 = %2", QGVARMAIN(stack), _mod getOrDefault ["stack", 0]]],
    ["stack", "stackSize", format ["%1 = %2", QGVARMAIN(stackSize), _mod getOrDefault ["stackSize", 0]]],
    ["grid", "grid", format ["%1 = %2", QGVARMAIN(grid), [_mod getOrDefault ["grid", []]] call FUNC(formatGrid)]],
    ["grid", "grids", format ["%1[] = %2", QGVARMAIN(grids), str (_mod getOrDefault ["grids", []])]],
    ["grid", "slots", format ["%1 = %2", QGVARMAIN(slots), _mod getOrDefault ["slots", 0]]],
    ["weight", "weight", format ["%1 = %2", QGVARMAIN(weight), _mod getOrDefault ["weight", 0]]],
    ["name", "name", format ["%1 = %2", QGVARMAIN(name), _mod getOrDefault ["name", ""]]],
    ["icon", "icon", format ["%1 = %2", QGVARMAIN(icon), [_mod getOrDefault ["icon", ICON_PLAIN], ","] call FUNC(formatIcon)]]
];

[_compiled getOrDefault ["preset", []], _presetIndices, true] call _fnc_walk;

// Everything else (all): asked after the preset, so it wins only what is still open - and what only the
// preset's everything else won, which that line then no longer wins.
if (_fallbackIndices isNotEqualTo []) then {
    private _reopened = _caught apply {_x select 1};

    _open append _reopened;

    [_compiled getOrDefault ["fallback", []], _fallbackIndices] call _fnc_walk;

    {
        _x params ["_line", "_field"];

        if !(_field in _open) then {
            private _wins = (_lines select _line) select 4;

            _wins deleteAt (_wins find _field);
        };
    } forEach _caught;

    _open = _open - _reopened;
};

if (_open isNotEqualTo []) then {
    _lines pushBack ["builtin", -1, "", _open, _open];
};

_lines
