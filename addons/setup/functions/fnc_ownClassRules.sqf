#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The draft's own rules by class, for the Items and Containers steps:
 *   - exact: what the rules written for exactly one class set (class=X and no other condition) - several
 *     of them merged in text order, the later value winning, as the engine reads them. This is the rule
 *     those steps edit (fnc_upsertRule).
 *   - named: every class an own rule names at all - class=X, class=X+, class=A|B - with what those rules
 *     set, for "only classes with own rules": the Items step lists the ones that set size or stack, the
 *     Containers step the ones that set grid or like - a container's grid rule is no item rule.
 *   - tree: what the rules written for exactly X and everything built on it set (class=X+ and no other
 *     condition) - several of them merged in text order -, the rule the tree view's edits write
 *     (fnc_upsertRules).
 * Worked out once per draft text; the maps are shared, nobody changes them.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [exact, named, tree] <ARRAY>
 *   exact - lowercase class -> the values, as aio_items_fnc_parseRules gives a rule's <HASHMAP>
 *   named - lowercase class -> the values those rules set, by key ("footprint", "stack", "grid", "like",
 *           ...) -> true <HASHMAP>
 *   tree  - lowercase class -> the values of its class=X+ rules, as for exact <HASHMAP>
 *
 * Example:
 * ([] call aio_setup_fnc_ownClassRules) params ["_exact", "_named", "_tree"];
 *
 * Public: No
 */

private _cached = missionNamespace getVariable [QGVAR(ownClasses), []];

if ((_cached param [0, 0]) isEqualTo GVAR(draftText)) exitWith {[_cached select 1, _cached select 2, _cached select 3]};

private _exact = createHashMap;
private _named = createHashMap;
private _tree = createHashMap;

{
    _x params ["_conds", "_values"];

    {
        _x params ["_negated", "_key", "_op", "_names"];

        if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="}) then {
            {
                private _lc = toLowerANSI _x;

                if ((_lc select [count _lc - 1]) isEqualTo "+") then {
                    _lc = _lc select [0, count _lc - 1];
                };

                private _keys = _named getOrDefault [_lc, createHashMap];

                {
                    _keys set [_x, true];
                } forEach (keys _values);

                _named set [_lc, _keys];
            } forEach _names;
        };
    } forEach _conds;

    if (count _conds == 1) then {
        (_conds select 0) params ["_negated", "_key", "_op", "_names"];

        // X+ is X and everything built on it: not a rule for exactly X, but the tree's own.
        if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1}) then {
            private _lc = toLowerANSI (_names select 0);

            if ((_lc find "+") < 0) then {
                private _merged = _exact getOrDefault [_lc, createHashMap];

                _merged merge [_values, true];
                _exact set [_lc, _merged];
            } else {
                if ((_lc select [count _lc - 1]) isEqualTo "+") then {
                    _lc = _lc select [0, count _lc - 1];

                    private _merged = _tree getOrDefault [_lc, createHashMap];

                    _merged merge [_values, true];
                    _tree set [_lc, _merged];
                };
            };
        };
    };
} forEach (GVAR(draft) getOrDefault ["rules", []]);

GVAR(ownClasses) = [GVAR(draftText), _exact, _named, _tree];

[_exact, _named, _tree]
