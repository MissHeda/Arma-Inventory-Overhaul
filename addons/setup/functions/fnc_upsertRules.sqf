#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what the Items or Containers step sets for classes into the draft, as rules, in one undo step.
 * For each class:
 *   - the class alone: the rules written for exactly that class (class=X, fnc_ownClassRules) become one,
 *     the values given are set and the fields named are taken away. Whatever else they set stays - a name,
 *     a weight, a size on a container whose cells are edited. The rule goes last: later rules win
 *     (aio_items_fnc_resolve), so a broader rule further down - a group, a kind - would otherwise still
 *     decide what the class gets, and the step would show something else than what was just applied.
 *   - the class and every class built on it (tree): the same with the inheritance selector, class=X+ - one
 *     rule for the whole tree. The classes of the tree (fnc_classTree) that have a rule of their own
 *     further down keep it: those rules (class=Y or class=Y+ for Y inside the tree) are moved behind the
 *     tree's rule, so a class that was set apart stays apart. Everything else, ranging from a group to
 *     a rule for a parent, stays in front of it and loses to it. The class itself is edited with the tree:
 *     what the edit sets or takes away is taken out of its own rule class=X too, which would win over the
 *     tree's. A tree with nothing in it but the class is written as the class alone.
 * A rule left with nothing to set goes altogether: the preset answers again.
 *
 * Ends in fnc_commit: an undo step, and the step drawn again.
 *
 * Arguments:
 * 0: What to write <ARRAY>, one entry per class: [class, set, remove, tree]
 *    class  - as config names it <STRING>
 *    set    - values: "footprint" ("2x3" or a mask), "stack" <NUMBER>, "grid" (as aio_items_fnc_formatGrid
 *             writes it), "like" (a class), "weight" (kg) <NUMBER>, "name" <STRING>, "icon" ([scale, across,
 *             down] <ARRAY>, aio_items_fnc_parseIcon) <HASHMAP> (default: none)
 *    remove - fields to take away <ARRAY of STRING> (default: [])
 *    tree   - for the class and every class built on it <BOOL> (default: false)
 *
 * Return Value:
 * Written - false when no class could be written (a class name the rules language cannot hold: they take
 * letters, digits and _ only, and a rule for any other would be left out when the text is read again) <BOOL>
 *
 * Example:
 * [[["V_PlateCarrier1_rgr", createHashMapFromArray [["grid", "xxxx/x--x+2x3"]]]]] call aio_setup_fnc_upsertRules;
 *
 * Public: No
 */

params [["_entries", [], [[]]]];

private _allowed = toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";

// The rules with one class's edit in them.
private _fnc_apply = {
    params ["_rules", "_class", "_set", "_remove", "_tree"];

    private _lc = toLowerANSI _class;
    private _selector = [_class, _class + "+"] select _tree;
    private _selectorLc = toLowerANSI _selector;
    private _fields = (keys _set) + _remove;
    private _values = createHashMap;
    private _kept = [];

    {
        _x params ["_conds", "_ruleValues"];

        // 1: the rule for this selector, 2: the rule for exactly the class while a tree is edited.
        private _which = 0;

        if (count _conds == 1) then {
            (_conds select 0) params ["_negated", "_key", "_op", "_names"];

            if (!_negated && {_key isEqualTo "class"} && {_op isEqualTo "="} && {count _names == 1}) then {
                private _name = toLowerANSI (_names select 0);

                if (_name isEqualTo _selectorLc) then {
                    _which = 1;
                } else {
                    if (_tree && {_name isEqualTo _lc}) then {
                        _which = 2;
                    };
                };
            };
        };

        if (_which == 1) then {
            _values merge [_ruleValues, true];
        } else {
            if (_which == 2) then {
                {
                    _ruleValues deleteAt _x;
                } forEach _fields;

                if (count _ruleValues > 0) then {
                    _kept pushBack _x;
                };
            } else {
                _kept pushBack _x;
            };
        };
    } forEach _rules;

    {
        _values deleteAt _x;
    } forEach _remove;

    _values merge [_set, true];

    if (count _values == 0) exitWith {_kept};

    private _rule = [[[false, "class", "=", [_selector]]], _values];
    private _inTree = [];

    if (_tree) then {
        _inTree = ([_lc] call FUNC(classTree)) getOrDefault ["set", createHashMap];
    };

    // A class alone, or a tree this mod's config cannot tell: last.
    if (count _inTree == 0) exitWith {
        _kept pushBack _rule;

        _kept
    };

    // A rule only for classes inside the tree: class=Y or class=Y+ with Y in it - for Y+ below the class,
    // since class=X+ itself is the rule being written.
    private _fnc_narrower = {
        params ["_conds"];

        if (count _conds != 1) exitWith {false};

        (_conds select 0) params ["_negated", "_key", "_op", "_names"];

        if (_negated || {_key isNotEqualTo "class"} || {_op isNotEqualTo "="} || {_names isEqualTo []}) exitWith {false};

        (_names findIf {
            private _name = toLowerANSI _x;
            private _plus = (_name select [count _name - 1]) isEqualTo "+";

            if (_plus) then {
                _name = _name select [0, count _name - 1];
            };

            !(_name in _inTree) || {_plus && {_name isEqualTo _lc}}
        }) < 0
    };

    private _before = [];
    private _after = [];

    {
        if ([_x select 0] call _fnc_narrower) then {
            _after pushBack _x;
        } else {
            _before pushBack _x;
        };
    } forEach _kept;

    _before + [_rule] + _after
};

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _rules = _ast getOrDefault ["rules", []];
private _applied = 0;

{
    _x params [["_class", "", [""]], ["_set", createHashMap, [createHashMap]], ["_remove", [], [[]]], ["_tree", false, [false]]];

    if (_class isEqualTo "" || {(toArray _class) findIf {!(_x in _allowed)} >= 0}) then {
        [format [LLSTRING(Hint_BadClass), _class], "loss"] call FUNC(setHint);
    } else {
        _rules = [_rules, _class, _set, _remove, _tree] call _fnc_apply;
        _applied = _applied + 1;
    };
} forEach _entries;

if (_applied == 0) exitWith {false};

_ast set ["rules", _rules];

[_ast] call FUNC(commit);

true
