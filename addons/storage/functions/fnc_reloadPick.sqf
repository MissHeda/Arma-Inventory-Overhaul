#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The magazine a reload may use: the fullest one the weapon's muzzle takes that is not loaded and does not lie
 * in a container the "Use items from ..." settings close to it (fnc_useCarried). [] when there is none, or the
 * weapon is full already.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 *
 * Return Value:
 * The entry of magazinesAmmoFull, at least seven items long - [] for none <ARRAY>
 *
 * Example:
 * [player, primaryWeapon player, primaryWeapon player] call einv_storage_fnc_reloadPick;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_muzzle", "", [""]]];

private _compatible = (compatibleMagazines [_weapon, _muzzle]) apply {toLowerANSI _x};
private _usable = (([_unit, [[], [], magazinesAmmoFull _unit]] call FUNC(useCarried)) select 2) select {
    count _x >= 7 && {!(_x select 2)} && {(_x select 1) > 0} && {(toLowerANSI (_x select 0)) in _compatible}
};

if (_usable isEqualTo []) exitWith {[]};

// A full magazine in the weapon: nothing to reload.
private _loadedClass = currentMagazine _unit;

if (_loadedClass isNotEqualTo "" && {(_unit ammo _muzzle) >= getNumber (configFile >> "CfgMagazines" >> _loadedClass >> "count")}) exitWith {[]};

private _best = _usable select 0;

{
    if ((_x select 1) > (_best select 1)) then {
        _best = _x;
    };
} forEach _usable;

_best
