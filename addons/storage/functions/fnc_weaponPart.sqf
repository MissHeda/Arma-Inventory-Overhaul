#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts an attachment or magazine on one of a unit's weapons, or takes it off - each weapon slot has
 * its own pair of commands. A magazine goes on with its own rounds, into the muzzle it belongs to.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon slot - "primary", "handgun" or "launcher" <STRING>
 * 2: Put on (true) or take off (false) <BOOL>
 * 3: Class <STRING>
 * 4: Rounds, for a magazine put on <NUMBER> (default: -1)
 * 5: Second muzzle, for a magazine put on <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "primary", true, "optic_Aco"] call einv_storage_fnc_weaponPart;
 *
 * Public: No
 */

params ["_unit", "_base", "_on", "_class", ["_ammo", -1], ["_second", false]];

if (_class isEqualTo "") exitWith {};

private _weapon = (([_unit] call FUNC(getEquipment)) getOrDefault [_base, []]) param [0, ""];

if (_weapon isEqualTo "") exitWith {};

if (!_on) exitWith {
    switch (_base) do {
        case "primary": {_unit removePrimaryWeaponItem _class};
        case "handgun": {_unit removeHandgunItem _class};
        case "launcher": {_unit removeSecondaryWeaponItem _class};
    };
};

private _kind = ([_class] call EFUNC(items,getInfo)) get "kind";

if (_kind in ["magazine", "grenade"]) exitWith {
    private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
    private _muzzle = if (_second) then {
        (_muzzles select {_x != "this" && {_x != (_muzzles param [0, ""])}}) param [0, _weapon]
    } else {
        _weapon
    };

    if (_ammo < 0) then {
        _ammo = getNumber (configFile >> "CfgMagazines" >> _class >> "count");
    };

    _unit addWeaponItem [_weapon, [_class, _ammo, _muzzle], true];
};

switch (_base) do {
    case "primary": {_unit addPrimaryWeaponItem _class};
    case "handgun": {_unit addHandgunItem _class};
    case "launcher": {_unit addSecondaryWeaponItem _class};
};
