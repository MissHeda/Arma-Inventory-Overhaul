#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the draft would make of a class without its own say - the answer the small reset buttons of the Items and
 * Containers steps take a field back to: the draft's rules with the given fields taken out of the rules written for
 * exactly that class (class=X) and for it with everything built on it (class=X+), the General step's settings and
 * every other rule still in. A rule left with nothing to set is dropped. Compiled and asked once per draft text,
 * class and fields, and kept - a step draws again on every click.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The fields to leave out of its own rules, as the rules write them ("footprint", "stack", "grid", ...) <ARRAY>
 *
 * Return Value:
 * The class as aio_items_fnc_getInfo gives it under those rules <HASHMAP>
 *
 * Example:
 * ["B_Carryall_blk", ["grid", "like"]] call aio_setup_fnc_classDefault;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_fields", [], [[]]]];

private _lc = toLowerANSI _class;
private _key = format ["%1|%2|%3", GVAR(draftText), _lc, _fields joinString ","];
private _known = GVAR(defaultCache) get _key;

if (!isNil "_known") exitWith {_known};

// A few kept at most: the texts are long.
if (count GVAR(defaultCache) > 40) then {
    GVAR(defaultCache) = createHashMap;
};

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _rules = [];

{
    _x params ["_conds", "_values"];

    // For exactly this class, or for it and everything built on it.
    private _own = false;

    if (count _conds == 1) then {
        (_conds select 0) params [["_negated", false], ["_ruleKey", ""], ["_op", ""], ["_names", []]];

        if (!_negated && {_ruleKey isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1}) then {
            private _name = toLowerANSI (_names select 0);

            if ((_name select [count _name - 1]) isEqualTo "+") then {
                _name = _name select [0, count _name - 1];
            };

            _own = _name isEqualTo _lc;
        };
    };

    if (_own) then {
        private _kept = +_values;

        {
            _kept deleteAt _x;
        } forEach _fields;

        if (count _kept > 0) then {
            _rules pushBack [_conds, _kept];
        };
    } else {
        _rules pushBack _x;
    };
} forEach (_ast getOrDefault ["rules", []]);

_ast set ["rules", _rules];

private _compiled = [[_ast] call EFUNC(items,writeRules)] call EFUNC(items,compileRules);
private _info = [_class, _compiled, createHashMap] call EFUNC(items,getInfo);

GVAR(defaultCache) set [_key, _info];

_info
