#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Writes the General step's size for a kind of container into the draft: the rule all kind=uniform >
 * grid=WxH - a rule the engine asks after everything that is about a class, so it fills only the containers of
 * that kind that no class rule, mod or older table answers (einv_items_fnc_resolve). Each is found by its
 * selector, not by a class as the Items and Containers steps find theirs (fnc_allRule): wherever it stands in
 * the text, and edited in its place - a later rule with "all" still wins over an earlier one, so it keeps its
 * rank -, a new one goes last. Whatever else the rule sets (typed in by hand) stays; the values given are set
 * and the fields named are taken away, and a rule left with nothing to set goes altogether: the built-in answer,
 * a grid from the load, fills the gaps again. Other rules with "all" (all kind=magazine > stack=30, typed in by
 * hand) are not touched.
 *
 * Ends in fnc_commit: one undo step for all of them, and the step drawn again.
 *
 * Arguments:
 * 0: What to write, [[kind, values to set, fields to take away], ...] - the kind one of GENERAL_KINDS, the values
 *    "grid" ("WxH"), the fields ["grid"] to take the size back <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[["uniform", createHashMapFromArray [["grid", "5x5"]], []]]] call einv_setup_fnc_upsertKinds;
 *
 * Public: No
 */

params [["_edits", [], [[]]]];

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _rules = _ast getOrDefault ["rules", []];

{
    _x params [["_kind", "", [""]], ["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]]];

    if !(_kind in GENERAL_KINDS) then {continue};

    private _index = [_rules, [_kind]] call FUNC(allRule);
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
            _rules pushBack [[[false, "all", "", []], [false, "kind", "=", [_kind]]], _values];
        };
    };
} forEach _edits;

_ast set ["rules", _rules];

[_ast] call FUNC(commit);
