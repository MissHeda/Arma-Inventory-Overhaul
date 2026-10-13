#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what the Items or Containers step sets for one class into the draft, as that class's own rule
 * class=X > ...: the rules written for exactly that class (fnc_ownClassRules) become one, the values
 * given are set and the fields named are taken away. Whatever else they set stays - a name, a weight, a
 * size on a container whose cells are edited.
 *
 * The rule goes last. Later rules win (einv_items_fnc_resolve), so a broader rule further down - a group,
 * a kind - would otherwise still decide what the class gets, and the step would show something else than
 * what was just applied. A rule left with nothing to set goes altogether: the preset answers again.
 *
 * Ends in fnc_commit: an undo step, and the step drawn again.
 *
 * Arguments:
 * 0: Class, as config names it <STRING>
 * 1: Values to set: "footprint" ("2x3"), "stack" <NUMBER>, "grid" (as einv_items_fnc_formatGrid writes it),
 *    "like" (a class) <HASHMAP> (default: none)
 * 2: Fields to take away <ARRAY of STRING> (default: [])
 *
 * Return Value:
 * Written - false for a class name the rules language cannot hold <BOOL>
 *
 * Example:
 * ["V_PlateCarrier1_rgr", createHashMapFromArray [["grid", "xxxx/x--x+2x3"]]] call einv_setup_fnc_upsertRule;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]]];

// The rules take class names of letters, digits and _ only; a rule for any other would be left out when
// the text is read again.
private _allowed = toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

if (_class isEqualTo "" || {(toArray _class) findIf {!(_x in _allowed)} >= 0}) exitWith {
    [format [LLSTRING(Hint_BadClass), _class], "loss"] call FUNC(setHint);

    false
};

private _lc = toLowerANSI _class;
private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _values = createHashMap;
private _kept = [];

{
    _x params ["_conds", "_ruleValues"];

    private _forClass = false;

    if (count _conds == 1) then {
        (_conds select 0) params ["_negated", "_key", "_op", "_names"];

        _forClass = !_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1} && {toLowerANSI (_names select 0) isEqualTo _lc};
    };

    if (_forClass) then {
        _values merge [_ruleValues, true];
    } else {
        _kept pushBack _x;
    };
} forEach (_ast getOrDefault ["rules", []]);

{
    _values deleteAt _x;
} forEach _remove;

_values merge [_set, true];

if (count _values > 0) then {
    _kept pushBack [[[false, "class", "=", [_class]]], _values];
};

_ast set ["rules", _kept];

[_ast] call FUNC(commit);

true
