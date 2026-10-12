#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Turns one condition as fnc_parseRules reads it into what fnc_matches checks fast: lists into sets,
 * class=X+ into a test against the classes an item is built on, numbers into numbers, a magazine well
 * or "the magazines this weapon loads" into the set of those magazines - worked out here, once, so
 * matching an item is only looking things up. Plain data only: compiled rules end up in save games.
 *
 * A group is looked up by name: the caller says which definition each name stands for (in an own
 * group, @itself means the preset's group of that name, see fnc_compileRules). A name it does not
 * know is an error - the whole statement goes, rather than "not in a group that does not exist"
 * reaching every item.
 *
 * Arguments:
 * 0: Condition, [negated, key, op, values] <ARRAY>
 * 1: Group name -> the key of its definition in the compiled groups <HASHMAP> (default: empty)
 *
 * Return Value:
 * [error, condition] - error "" when it worked; the condition [negated, key, op, data, cost], cost
 * ordering conditions cheapest first <ARRAY>
 *   kind, cat     - data a set (HashMap) of kinds / CATEGORY_* numbers
 *   class =       - data [set of exact classes, set of classes whose descendants count], lowercase
 *   class ~, addon ~ - data the lowercase texts to look for
 *   addon =       - data a set of lowercase addons
 *   well, for     - data a set of lowercase magazine classes
 *   mass, rounds, load - data the numbers
 *   @             - data the group keys
 *
 * Example:
 * [[false, "class", "=", ["ACE_fieldDressing+"]]] call einv_items_fnc_compileCond;
 *
 * Public: No
 */

params [["_cond", [], [[]]], ["_groupKeys", createHashMap, [createHashMap]]];

_cond params [["_negated", false, [false]], ["_key", "", [""]], ["_op", "=", [""]], ["_values", [], [[]]]];

// A set as a HashMap: "in" is a lookup then, however long the list.
private _fnc_set = {
    params ["_list"];

    private _set = createHashMap;

    {
        _set set [_x, true];
    } forEach _list;

    _set
};

switch (_key) do {
    case "@": {
        private _keys = _values apply {_groupKeys getOrDefault [_x, ""]};
        private _missing = _keys find "";

        if (_missing >= 0) then {
            [format ["there is no group @%1", _values select _missing], []]
        } else {
            ["", [_negated, "@", "=", _keys, 5]]
        };
    };
    case "kind": {
        ["", [_negated, "kind", "=", [_values apply {toLowerANSI _x}] call _fnc_set, 0]]
    };
    case "cat": {
        private _numbers = (_values apply {CATEGORY_NAMES find (toLowerANSI _x)}) select {_x >= 0};

        ["", [_negated, "cat", "=", [_numbers] call _fnc_set, 1]]
    };
    case "class": {
        if (_op isEqualTo "~") then {
            ["", [_negated, "class", "~", _values apply {toLowerANSI _x}, 6]]
        } else {
            private _exact = [];
            private _lineage = [];

            {
                private _name = toLowerANSI _x;

                if ((_name select [count _name - 1]) isEqualTo "+") then {
                    _lineage pushBack (_name select [0, count _name - 1]);
                } else {
                    _exact pushBack _name;
                };
            } forEach _values;

            ["", [_negated, "class", "=", [[_exact] call _fnc_set, [_lineage] call _fnc_set], 3]]
        };
    };
    case "addon": {
        if (_op isEqualTo "~") then {
            ["", [_negated, "addon", "~", _values apply {toLowerANSI _x}, 6]]
        } else {
            ["", [_negated, "addon", "=", [_values apply {toLowerANSI _x}] call _fnc_set, 3]]
        };
    };
    // A magazine well lists its magazines in arrays of its own, one per mod that adds to it.
    case "well": {
        private _magazines = [];

        {
            private _well = configFile >> "CfgMagazineWells" >> _x;

            if (isClass _well) then {
                {
                    _magazines append ((getArray _x) select {_x isEqualType ""});
                } forEach configProperties [_well, "isArray _x", true];
            };
        } forEach _values;

        ["", [_negated, "well", "=", [_magazines apply {toLowerANSI _x}] call _fnc_set, 4]]
    };
    // Every magazine the weapon takes, on any of its muzzles, wells included. A weapon of a mod that is
    // not loaded takes none: the condition then matches nothing, as a class rule for it would.
    case "for": {
        private _magazines = [];

        {
            if (isClass (configFile >> "CfgWeapons" >> _x)) then {
                _magazines append (compatibleMagazines _x);
            };
        } forEach _values;

        ["", [_negated, "for", "=", [_magazines apply {toLowerANSI _x}] call _fnc_set, 4]]
    };
    case "mass";
    case "rounds";
    case "load": {
        ["", [_negated, _key, _op, _values apply {parseNumber _x}, 2]]
    };
    default {
        [format ["there is no key '%1'", _key], []]
    };
}
