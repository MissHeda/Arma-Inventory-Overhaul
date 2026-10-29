#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sets the name and picture of a category in the draft (the statement category=ID > name=... picture=... of the rules text) -
 * a new category of the setup's own, or another name and picture for one of the built-in eight. An empty name or picture takes
 * that part away; a built-in category left with neither is back to what this mod ships and its statement goes. An undo step
 * (fnc_commit), the step is drawn again.
 *
 * Arguments:
 * 0: The category's id <STRING>
 * 1: What to set, "name" and/or "picture" (a texture path with backslashes) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["bandit", createHashMapFromArray [["name", "Bandit loot"]]] call einv_setup_fnc_setCategory;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_fields", createHashMap, [createHashMap]]];

if (_id isEqualTo "") exitWith {};

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _categories = +(_ast getOrDefault ["categories", []]);
private _at = _categories findIf {(_x select 0) isEqualTo _id};
// Not a select on both: the second would throw for a category that is not there yet.
private _entry = [_id, "", "", ""];

if (_at >= 0) then {
    _entry = +(_categories select _at);
};

if ("name" in _fields) then {
    _entry set [1, (trim (_fields get "name")) select [0, CAT_NAME_MAX]];
};

if ("picture" in _fields) then {
    _entry set [2, _fields get "picture"];
};

if (_id in ITEM_GROUPS && {(_entry select 1) isEqualTo ""} && {(_entry select 2) isEqualTo ""} && {(_entry param [3, ""]) isEqualTo ""}) then {
    // Back to what this mod ships.
    if (_at >= 0) then {
        _categories deleteAt _at;
    };
} else {
    if (_at >= 0) then {
        _categories set [_at, _entry];
    } else {
        _categories pushBack _entry;
    };
};

_ast set ["categories", _categories];

[_ast] call FUNC(commit);
