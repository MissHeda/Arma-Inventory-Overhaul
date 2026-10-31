#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Finds one of the General step's rules for a kind of container in a setup's rules (fnc_kindRule,
 * fnc_upsertKinds): the text's rules with "all", which the engine asks after the preset, for what no other
 * rule answers (aio_items_fnc_resolve). They are known by their selector, not by a class as the Items and
 * Containers steps know theirs (fnc_ownClassRules): "all" alone, "all kind=uniform" with exactly the kinds given - in
 * whatever order they were typed. A rule with "all" and any other condition is someone's own and is not one of
 * them.
 *
 * Arguments:
 * 0: Rules, [[conditions, values], ...] as aio_items_fnc_parseRules lists them under "rules" <ARRAY>
 * 1: Kinds, [] for the rule for every item <ARRAY> (default: [])
 *
 * Return Value:
 * Its index in the rules, the last one should there be several (a later rule wins), -1 for none <NUMBER>
 *
 * Example:
 * [aio_setup_draft get "rules", ["uniform", "vest", "backpack"]] call aio_setup_fnc_allRule;
 *
 * Public: No
 */

params [["_rules", [], [[]]], ["_kinds", [], [[]]]];

private _want = _kinds apply {toLowerANSI _x};
_want sort true;

private _found = -1;

{
    private _conds = _x param [0, []];

    // "all" stands first: aio_items_fnc_parseRules puts it there, wherever it was typed.
    if (((_conds param [0, []]) param [1, ""]) isEqualTo "all") then {
        private _is = if (_want isEqualTo []) then {
            count _conds == 1
        } else {
            count _conds == 2 && {
                (_conds select 1) params [["_negated", false], ["_key", ""], ["_op", ""], ["_values", []]];

                private _have = _values apply {toLowerANSI _x};
                _have sort true;

                !_negated && {_key isEqualTo "kind"} && {_have isEqualTo _want}
            }
        };

        if (_is) then {
            _found = _forEachIndex;
        };
    };
} forEach _rules;

_found
