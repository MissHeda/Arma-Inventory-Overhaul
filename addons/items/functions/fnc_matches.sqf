#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item meets every one of a rule's conditions. Takes the conditions compiled
 * (fnc_compileCond, as fnc_compileRules keeps them) or as fnc_parseRules reads them - those are
 * compiled first, against the groups of the compiled rules given.
 *
 * Whether an item is in a group is worked out once per call of fnc_resolve, not once per rule that
 * asks: the memo keeps it. Conditions run cheapest first and stop at the first that fails.
 *
 * Arguments:
 * 0: The item's facts (fnc_getFacts) <HASHMAP>
 * 1: Conditions, all of which must hold - none means every item <ARRAY>
 * 2: Compiled rules, for the groups <HASHMAP>
 * 3: Group key -> member or not, kept between calls for the same item <HASHMAP> (default: a new one)
 *
 * Return Value:
 * Meets them all - false too when a condition cannot be compiled <BOOL>
 *
 * Example:
 * [["arifle_MX_F"] call aio_items_fnc_getFacts, [[false, "kind", "=", ["rifle"]]], call aio_items_fnc_currentRules] call aio_items_fnc_matches;
 *
 * Public: No
 */

params [
    ["_facts", createHashMap, [createHashMap]],
    ["_conds", [], [[]]],
    ["_compiled", createHashMap, [createHashMap]],
    ["_memo", nil, [createHashMap]]
];

if (isNil "_memo") then {
    _memo = createHashMap;
};

// Read but not compiled yet: four elements instead of five.
if (_conds findIf {count _x < 5} >= 0) then {
    private _groupKeys = _compiled getOrDefault ["groupKeys", createHashMap];
    private _compiledConds = [];

    {
        ([_x, _groupKeys] call FUNC(compileCond)) params ["_error", "_cond"];

        if (_error isNotEqualTo "") exitWith {
            _compiledConds = [];
        };

        _compiledConds pushBack _cond;
    } forEach _conds;

    // One that could not be compiled fails the lot: [false] is a condition nothing meets.
    _conds = if (count _compiledConds == count _conds) then {_compiledConds} else {[[false, "kind", "=", createHashMap, 0]]};
};

private _groups = _compiled getOrDefault ["groups", createHashMap];

private _fnc_member = {
    params ["_groupKey"];

    private _known = _memo get _groupKey;

    if (!isNil "_known") exitWith {_known};

    // A group is either of its definitions, each a set of conditions that must all hold.
    private _is = (_groups getOrDefault [_groupKey, []]) findIf {
        _x findIf {!([_x] call _fnc_test)} < 0
    } >= 0;

    _memo set [_groupKey, _is];

    _is
};

private _fnc_test = {
    params ["_cond"];

    _cond params ["_negated", "_key", "_op", "_data"];

    private _hit = switch (_key) do {
        // A kit is an item as well (KINDS_AS_ITEM): kind=item reaches it, kind=kit only kits.
        case "kind": {
            private _kind = _facts get "kind";

            _kind in _data || {_kind in KINDS_AS_ITEM && {"item" in _data}}
        };
        case "cat": {(_facts get "category") in _data};
        case "class": {
            if (_op isEqualTo "~") then {
                private _lc = _facts get "lc";

                _data findIf {_lc find _x >= 0} >= 0
            } else {
                private _lc = _facts get "lc";

                (_data select 0) getOrDefault [_lc, false]
                || {(_facts get "lineage") findIf {_x in (_data select 1)} >= 0}
                || {(_data param [2, []]) findIf {(_lc select [0, count _x]) isEqualTo _x} >= 0}
            };
        };
        case "addon": {
            private _addon = _facts get "addon";

            if (_op isEqualTo "~") then {
                _data findIf {_addon find _x >= 0} >= 0
            } else {
                _addon in _data
            };
        };
        case "well";
        case "for": {(_facts get "lc") in _data};
        case "mass";
        case "rounds";
        case "load": {
            private _value = _facts get (["mass", "rounds", "maxLoad"] select (["mass", "rounds", "load"] find _key));

            switch (_op) do {
                case "<": {_data findIf {_value < _x} >= 0};
                case "<=": {_data findIf {_value <= _x} >= 0};
                case ">": {_data findIf {_value > _x} >= 0};
                case ">=": {_data findIf {_value >= _x} >= 0};
                default {_data findIf {_value == _x} >= 0};
            }
        };
        case "@": {_data findIf {[_x] call _fnc_member} >= 0};
        // Everything else: where such a rule is asked is what makes it a fallback (fnc_resolve).
        case "all": {true};
        default {false};
    };

    _hit isNotEqualTo _negated
};

_conds findIf {!([_x] call _fnc_test)} < 0
