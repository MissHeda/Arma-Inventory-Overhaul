#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Writes the Start step's "Everything else" into the draft (fnc_drawStart): the rule all > size=WxH
 * stack=N for the items and all kind=uniform|vest|backpack > grid=WxH for the containers - rules the
 * engine asks after the preset, so they fill only the gaps no rule, table, mod or preset answers
 * (einv_items_fnc_resolve). They have their own way in, keyed by their selector (fnc_allRule), where
 * fnc_upsertRules keys a rule by its class=X: each is found wherever it stands in the text and edited in
 * its place - a later rule with "all" still wins over an earlier one, so it keeps its rank -, a new one
 * goes last. Whatever else the rule sets (a weight typed in by hand) stays; the values given are set and
 * the fields named are taken away, and a rule left with nothing to set goes altogether: the built-in answer
 * fills the gaps again. Other rules with "all" (all kind=magazine > stack=30, typed at Review) are not
 * touched.
 *
 * Ends in fnc_commit: one undo step for both rules, and the step drawn again.
 *
 * Arguments:
 * 0: For the items: [values to set - "footprint" ("WxH") and "stack" <NUMBER> -, fields to take away]
 *    <ARRAY> (default: [{}, []])
 * 1: For the containers: [values to set - "grid" ("WxH") -, fields to take away] <ARRAY>
 *    (default: [{}, []])
 *
 * Return Value:
 * None
 *
 * Example:
 * [[createHashMapFromArray [["footprint", "1x1"], ["stack", 10]], []], [createHashMapFromArray [["grid", "6x4"]], []]] call einv_setup_fnc_upsertAll;
 *
 * Public: No
 */

params [["_items", [createHashMap, []], [[]]], ["_containers", [createHashMap, []], [[]]]];

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _rules = _ast getOrDefault ["rules", []];

{
    _x params ["_kinds", "_edit"];
    _edit params [["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]]];

    private _index = [_rules, _kinds] call FUNC(allRule);
    private _values = if (_index < 0) then {createHashMap} else {+((_rules select _index) select 1)};

    {
        _values deleteAt _x;
    } forEach _remove;

    _values merge [_set, true];

    switch (true) do {
        case (count _values == 0): {
            if (_index >= 0) then {
                _rules deleteAt _index;
            };
        };
        case (_index >= 0): {
            _rules set [_index, [(_rules select _index) select 0, _values]];
        };
        default {
            private _conds = [[false, "all", "", []]];

            if (_kinds isNotEqualTo []) then {
                _conds pushBack [false, "kind", "=", +_kinds];
            };

            _rules pushBack [_conds, _values];
        };
    };
} forEach [[[], _items], [ELSE_CONTAINER_KINDS, _containers]];

_ast set ["rules", _rules];

[_ast] call FUNC(commit);
