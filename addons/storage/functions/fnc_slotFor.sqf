#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The slot an item would go into on a unit (ids as in fnc_getSlot) - for "equip this" without saying
 * where: by kind, and for attachments and magazines the first of the unit's weapons that takes them.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Item class <STRING>
 *
 * Return Value:
 * Slot id, "" when there is none <STRING>
 *
 * Example:
 * [player, "optic_Aco"] call einv_storage_fnc_slotFor;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_kind in ["handgun", "launcher", "binocular", "headgear", "goggles", "nvg", "uniform", "vest", "backpack", "map", "gps", "radio", "compass", "watch"]) exitWith {_kind};
if (_kind isEqualTo "rifle") exitWith {"primary"};

private _slot = "";

{
    _slot = [_unit, _x, _class] call FUNC(partFor);

    if (_slot isNotEqualTo "") exitWith {};
} forEach ["primary", "handgun", "launcher"];

_slot
