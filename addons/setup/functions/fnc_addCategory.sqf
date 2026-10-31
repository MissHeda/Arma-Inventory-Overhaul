#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds a category of the setup's own to the draft from the name typed in the Add row of the General step: its id is made from the
 * name (fnc_newCategoryId), it has no picture yet (the star until one is picked). Refused, with a hint, without a name and at
 * MAX_CUSTOM_CATEGORIES.
 *
 * Arguments:
 * 0: The name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Bandit loot"] call aio_setup_fnc_addCategory;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _name = (trim _text) select [0, CAT_NAME_MAX];

if (_name isEqualTo "") exitWith {
    [LLSTRING(Categories_NeedName), "text2"] call FUNC(setHint);
};

if (({!(_x in ITEM_GROUPS)} count ([GVAR(draftRules)] call EFUNC(items,categories))) >= MAX_CUSTOM_CATEGORIES) exitWith {
    [format [LLSTRING(Categories_Max), MAX_CUSTOM_CATEGORIES], "loss"] call FUNC(setHint);
};

missionNamespace setVariable [QGVAR(newCategory), ""];

[[_name] call FUNC(newCategoryId), createHashMapFromArray [["name", _name]]] call FUNC(setCategory);
