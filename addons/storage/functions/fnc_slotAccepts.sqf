#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item can go into one of a unit's equipment slots (ids as in fnc_getSlot): the right kind
 * of item, and for a weapon's parts one that fits the weapon in that slot - an attachment from its
 * compatible items, a magazine its muzzle takes. Never a slot ACRE2 keeps for itself (the dummy radio in
 * the radio slot, einv_compat_acre_fnc_isFixedSlot): every way to equip asks this - drag, Alt+click, menu,
 * double click.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Item class <STRING>
 *
 * Return Value:
 * Fits <BOOL>
 *
 * Example:
 * [player, "primary_optic", "optic_Aco"] call einv_storage_fnc_slotAccepts;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_slotId", "", [""]], ["_class", "", [""]]];

if (isNull _unit || {_class isEqualTo ""}) exitWith {false};

// ACRE2's radio slot (einv_compat_acre, only when that addon is loaded).
if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_unit, _slotId] call EFUNC(compat_acre,isFixedSlot)}) exitWith {false};

(_slotId splitString "_") params [["_base", ""], ["_part", ""]];

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_part isEqualTo "") exitWith {
    _kind isEqualTo (switch (_base) do {
        case "primary": {"rifle"};
        default {_base};
    })
};

private _weapon = (([_unit] call FUNC(getEquipment)) getOrDefault [_base, []]) param [0, ""];

if (_weapon isEqualTo "") exitWith {false};

private _key = toLowerANSI _class;

if (_part in ["mag", "mag2"]) exitWith {
    if !(_kind in ["magazine", "grenade"]) exitWith {false};

    private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
    private _muzzle = if (_part isEqualTo "mag") then {"this"} else {
        (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, ""]
    };

    if (_muzzle isEqualTo "") exitWith {false};

    (compatibleMagazines [_weapon, _muzzle]) findIf {toLowerANSI _x isEqualTo _key} >= 0
};

if (_kind isNotEqualTo _part) exitWith {false};

([_weapon] call CBA_fnc_compatibleItems) findIf {toLowerANSI _x isEqualTo _key} >= 0
