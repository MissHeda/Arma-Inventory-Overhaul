#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The magazine a reload may use: the fullest one the weapon's muzzle takes that is not loaded and does not lie
 * in a container the "Use items from ..." settings close to it (fnc_useCarried); of equal rounds the one from the uniform, then the vest, then the backpack. [] when there is
 * none, or the weapon is full already - unless a swap is asked for: the reload key swaps a full magazine for another one, as the game does.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 * 3: Swap - also pick while the weapon holds a full magazine <BOOL> (default: false)
 *
 * Return Value:
 * The entry of magazinesAmmoFull, at least seven items long - [] for none <ARRAY>
 *
 * Example:
 * [player, primaryWeapon player, primaryWeapon player] call einv_storage_fnc_reloadPick;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_weapon", "", [""]], ["_muzzle", "", [""]], ["_swap", false, [false]]];

private _compatible = (compatibleMagazines [_weapon, _muzzle]) apply {toLowerANSI _x};
private _usable = (([_unit, [[], [], magazinesAmmoFull _unit]] call FUNC(useCarried)) select 2) select {
    count _x >= 7 && {!(_x select 2)} && {(_x select 1) > 0} && {(toLowerANSI (_x select 0)) in _compatible}
};

if (_usable isEqualTo []) exitWith {[]};

// A full magazine in the weapon: nothing to reload, unless the player swaps it for another.
private _loadedClass = currentMagazine _unit;

if (!_swap && {_loadedClass isNotEqualTo ""} && {(_unit ammo _muzzle) >= getNumber (configFile >> "CfgMagazines" >> _loadedClass >> "count")}) exitWith {[]};

// The fullest one; of equal rounds the one from the container that comes first: uniform, vest, backpack.
private _best = _usable select 0;
private _bestAt = USE_KINDS find (toLowerANSI format ["%1", _best select 4]);

{
    private _at = USE_KINDS find (toLowerANSI format ["%1", _x select 4]);

    if ((_x select 1) > (_best select 1) || {(_x select 1) == (_best select 1) && {_at >= 0} && {_bestAt < 0 || {_at < _bestAt}}}) then {
        _best = _x;
        _bestAt = _at;
    };
} forEach _usable;

_best
