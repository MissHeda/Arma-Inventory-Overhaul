#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The name typed into a category's field on the General step. A category of the setup's own needs a name; one of the built-in
 * eight with the name this mod ships, or none, is the shipped one again (fnc_setCategory takes its statement away).
 *
 * Arguments:
 * 0: The category's id <STRING>
 * 1: The text typed <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["bandit", "Bandit loot"] call aio_setup_fnc_renameCategory;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_text", "", [""]]];

private _name = (trim _text) select [0, CAT_NAME_MAX];
private _builtin = _id in ITEM_GROUPS;

if (_name isEqualTo "" && {!_builtin}) exitWith {
    [LLSTRING(Categories_NeedName), "loss"] call FUNC(setHint);
    [GVAR(step)] call FUNC(showStep);
};

if (_builtin && {_name isEqualTo (localize format ["STR_aio_setup_Cat_%1", _id])}) then {
    _name = "";
};

[_id, createHashMapFromArray [["name", _name]]] call FUNC(setCategory);
