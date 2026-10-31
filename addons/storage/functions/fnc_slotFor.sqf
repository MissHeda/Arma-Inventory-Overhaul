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
 * [player, "optic_Aco"] call aio_storage_fnc_slotFor;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_class", "", [""]]];

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_kind in ["handgun", "launcher", "binocular", "headgear", "goggles", "nvg", "uniform", "vest", "backpack", "map", "gps", "radio", "compass", "watch"]) exitWith {_kind};
if (_kind isEqualTo "rifle") exitWith {"primary"};

private _slot = "";

// Read once for the three weapons, and only for an item that may go on a part of one.
private _equipment = createHashMap;

if (_kind in ["muzzle", "optic", "rail", "bipod", "magazine", "grenade"]) then {
    _equipment = [_unit] call FUNC(getEquipment);
};

{
    _slot = [_unit, _x, _class, _equipment] call FUNC(partFor);

    if (_slot isNotEqualTo "") exitWith {};
} forEach ["primary", "handgun", "launcher"];

_slot
