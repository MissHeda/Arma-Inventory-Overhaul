#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Which step of the wizard a rule belongs to - where a line of the change lists opens, and which step's dot
 * a change lights. A rule for one class, or for a class and everything built on it (class=X, class=X+), goes
 * to the step that lists its kind: Containers for a uniform, vest, backpack, crate, vehicle or kit - a crate or
 * vehicle always (the Items step has none), the others when the rule sets grid= or like=, or sets nothing
 * of an item's own (size, stack, weight, name, use), a picture alone say -, else Items; a container's own
 * size, stack, weight and name, as any item's, are Items'. A rule for a class this game does not have, for
 * several classes or for a kind (all kind=uniform > grid=5x5 is the General step's own) belongs to General.
 *
 * Arguments:
 * 0: The rule, [conditions, values] as einv_items_fnc_parseRules lists it under "rules" <ARRAY>
 *
 * Return Value:
 * [step id: "general", "items" or "containers", the class, "" for none, for the class and everything built on it] <ARRAY>
 *
 * Example:
 * [(einv_setup_draft get "rules") select 0] call einv_setup_fnc_ruleStep;
 *
 * Public: No
 */

params [["_rule", [], [[]]]];

_rule params [["_conds", [], [[]]], ["_values", createHashMap, [createHashMap]]];

if (count _conds != 1) exitWith {["general", "", false]};

(_conds select 0) params [["_negated", false], ["_key", ""], ["_op", ""], ["_names", []]];

if (_negated || {_key isNotEqualTo "class"} || {_op isNotEqualTo "="} || {count _names != 1}) exitWith {["general", "", false]};

private _name = _names select 0;
private _tree = (_name select [count _name - 1]) isEqualTo "+";

if (_tree) then {
    _name = _name select [0, count _name - 1];
};

private _facts = [_name] call EFUNC(items,getFacts);

if ((_facts getOrDefault ["root", ""]) isEqualTo "") exitWith {["general", "", false]};

private _kind = _facts getOrDefault ["kind", ""];
private _container = (_kind in CONTAINER_KINDS) && {
    _kind in ["crate", "vehicle"] || {"grid" in _values} || {"like" in _values}
    || {!("footprint" in _values) && {!("stack" in _values)} && {!("weight" in _values)} && {!("name" in _values)} && {!("use" in _values)}}
};

[["items", "containers"] select _container, _facts getOrDefault ["class", _name], _tree]
