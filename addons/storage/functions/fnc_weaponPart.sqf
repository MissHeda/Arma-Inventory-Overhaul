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

    // Where the muzzle's magazine stands in weaponsItems: the first muzzle's at 4, the second's at 5.
    private _slot = [4, 5] select _second;

    // Whether the muzzle holds a magazine of the class now. Asked after every try: an empty weapon does not
    // always take the first form the command knows, and a load that did not happen must not be taken for one.
    private _fnc_loaded = {
        private _item = (weaponsItems _unit) select {(_x select 0) == _weapon};

        if (_item isEqualTo []) exitWith {false};

        private _mag = (_item select 0) param [_slot, []];

        _mag isEqualType [] && {count _mag >= 2} && {(_mag select 0) == _class}
    };

    // The muzzle by its name first, as the arsenal gives it; then without it for the weapon's own muzzle;
    // then the magazine of the class as it comes and its rounds set afterwards.
    _unit addWeaponItem [_weapon, [_class, _ammo, _muzzle], true];

    if (call _fnc_loaded) exitWith {};

    if (!_second) then {
        _unit addWeaponItem [_weapon, [_class, _ammo], true];
    };

    if (call _fnc_loaded) exitWith {
        INFO_2("%1 went into %2 only without a muzzle name.",_class,_weapon);
    };

    _unit addWeaponItem [_weapon, _class, true];

    if (call _fnc_loaded) then {
        _unit setAmmo [_muzzle, _ammo];

        INFO_2("%1 went into %2 only as a plain magazine, its rounds set after.",_class,_weapon);
    } else {
        WARNING_3("%1 did not go into %2 (muzzle %3) by any form of addWeaponItem.",_class,_weapon,_muzzle);
    };
};

switch (_base) do {
    case "primary": {_unit addPrimaryWeaponItem _class};
    case "handgun": {_unit addHandgunItem _class};
    case "launcher": {_unit addSecondaryWeaponItem _class};
};
