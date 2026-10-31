#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The name a soldier goes by on the window, for the captions of what he wears in the loot column ("Backpack - Miller")
 * and the loot column's title: ACE's name for him, and where ACE knows none, what he is ("Rifleman" rather than
 * "Unknown") - the way einv_storage_fnc_getLootSections titles a body.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The name, "" for no unit <STRING>
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_ownerName;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {""};

private _name = [_unit, false, true] call ACEFUNC(common,getName);

if (_name isEqualTo "" || {_name isEqualTo localize "STR_ACE_Common_Unknown"}) then {
    _name = getText (configOf _unit >> "displayName");
};

_name
