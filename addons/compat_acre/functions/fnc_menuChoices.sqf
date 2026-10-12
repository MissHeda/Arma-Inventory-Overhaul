#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The right-click choices of a radio: "Open radio" (ACRE2's own dialog for it) and "Use as active radio" -
 * only for the player's own radios, in their uniform, vest or backpack. A radio lying in a crate or on
 * someone else gets nothing, and neither does a base radio (nobody carries it yet).
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Unused, the same arguments as the other radio addons take <OBJECT> (default: objNull)
 * 2: It is the player's own - in their uniform, vest or backpack <BOOL> (default: false)
 * 3: It is asked from a slot, not a tile <BOOL> (default: false)
 *
 * Return Value:
 * Choices for einv_gui_fnc_openMenu, [text, arguments, code] each <ARRAY>
 *
 * Example:
 * ["ACRE_PRC152_ID_1", objNull, true, false] call einv_compat_acre_fnc_menuChoices;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_holder", objNull, [objNull]], ["_own", false, [false]], ["_inSlot", false, [false]]];

if (!_own || {([_class] call FUNC(radioType)) isNotEqualTo 1}) exitWith {[]};

private _choices = [[LLSTRING(Menu_Open), [_class], {_this call FUNC(open)}]];

if (!_inSlot && {_class != ([] call acre_api_fnc_getCurrentRadio)}) then {
    _choices pushBack [LLSTRING(Menu_MakeActive), [_class], {_this call FUNC(makeActive)}];
};

_choices
