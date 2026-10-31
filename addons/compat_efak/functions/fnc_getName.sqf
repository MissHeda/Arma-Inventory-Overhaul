#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What Enhanced First Aid Kits calls a kit, for the window's names (aio_gui_fnc_itemName): the name a
 * player gave it, else the mission's name for its type. Players tell their kits apart by these, so
 * they come before the window's own names - the rules' name= and config's.
 *
 * Short, a kit with neither goes by the rules' name, else by its type's short name in that mod
 * ("IFAK", "MFAK+") rather than config's.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The short name <BOOL> (default: false)
 *
 * Return Value:
 * Name, "" for anything that is no kit and for a kit the window names by its own means <STRING>
 *
 * Example:
 * ["efak_IFAK_7", true] call aio_compat_efak_fnc_getName;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_short", false, [false]]];

if !([_class] call FUNC(isKit)) exitWith {""};

private _label = [_class] call EFAKFUNC(core,getKitLabel);

if (_label isNotEqualTo "") exitWith {_label};

private _typeName = [_class] call EFAKFUNC(core,getTypeName);

if (_typeName isNotEqualTo "") exitWith {_typeName};
if (!_short) exitWith {""};

private _ruleName = ([_class] call EFUNC(items,getInfo)) getOrDefault ["nameOverride", ""];

if (_ruleName isNotEqualTo "") exitWith {_ruleName};

[_class, true] call EFAKFUNC(core,getKitShortName)
