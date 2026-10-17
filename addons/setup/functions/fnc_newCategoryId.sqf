#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The id for a new category from the name it was given: lowercase letters and digits, anything else (a space, an accent) an
 * underscore, cut to CAT_ID_MAX, and made to differ from every category the draft has and from every word that cats= would read as
 * one of the eight built-in categories (einv_items_fnc_builtinGroup) or from a word of its own (CAT_ID_RESERVED) by a number on the end.
 *
 * Arguments:
 * 0: The name <STRING>
 *
 * Return Value:
 * The id <STRING>
 *
 * Example:
 * ["Bandit loot"] call einv_setup_fnc_newCategoryId; // "bandit_loot"
 *
 * Public: No
 */

params [["_name", "", [""]]];

private _taken = [GVAR(draftRules)] call EFUNC(items,categories);

private _codes = (toArray toLowerANSI _name) apply {
    [95, _x] select ((_x >= 97 && {_x <= 122}) || {_x >= 48 && {_x <= 57}})
};

// One underscore between the words, none at the ends.
private _id = ((toString _codes) splitString "_") joinString "_";

if (_id isEqualTo "") then {
    _id = "category";
};

_id = _id select [0, CAT_ID_MAX - 3];

private _base = _id;
private _number = 1;

while {_id in _taken || {_id in CAT_ID_RESERVED} || {([_id] call EFUNC(items,builtinGroup)) isNotEqualTo ""}} do {
    _number = _number + 1;
    _id = format ["%1_%2", _base, _number];
};

_id
