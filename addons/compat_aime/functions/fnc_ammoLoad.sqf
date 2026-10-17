#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Loads a magazine of the chosen class into the weapon in the hands: the fullest one the "Use items from ..."
 * settings leave open (the uniform before the vest before the backpack when the rounds are equal), the way
 * every reload of this mod loads one (einv_storage_fnc_loadMagazine). Looked up again here, at the click:
 * the unit may have changed its gear since the menu opened. Nothing is loaded when no such magazine is left,
 * and a line says so.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Weapon the menu was opened for <STRING>
 * 2: Muzzle <STRING>
 * 3: Class of the magazine <STRING>
 *
 * Return Value:
 * Whether a magazine is loaded or on its way <BOOL>
 *
 * Example:
 * [ACE_player, primaryWeapon ACE_player, primaryWeapon ACE_player, "30Rnd_65x39_caseless_mag"] call einv_compat_aime_fnc_ammoLoad;
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_weapon", "", [""]], ["_muzzle", "", [""]], ["_class", "", [""]]];

// The menu was opened for this weapon; the soldier may have changed it since.
if (isNull _player || {currentWeapon _player isNotEqualTo _weapon} || {missionNamespace getVariable ["ace_common_isReloading", false]}) exitWith {false};

private _all = magazinesAmmoFull _player;

private _usable = (([_player, [[], [], _all]] call EFUNC(storage,useCarried)) select 2) select {
    count _x >= 7 && {!(_x select 2)} && {(_x select 1) > 0} && {(toLowerANSI (_x select 0)) isEqualTo (toLowerANSI _class)}
};

if (_usable isEqualTo []) exitWith {
    [format [localize "STR_einv_storage_Hint_NoReload", [[_player, _class] call EFUNC(storage,useBlockedIn)] call EFUNC(storage,useKindName)]] call EFUNC(storage,useHint);

    false
};

private _best = _usable select 0;
private _bestAt = USE_KINDS find (toLowerANSI format ["%1", _best select 4]);

{
    private _at = USE_KINDS find (toLowerANSI format ["%1", _x select 4]);

    if ((_x select 1) > (_best select 1) || {(_x select 1) == (_best select 1) && {_at >= 0} && {_bestAt < 0 || {_at < _bestAt}}}) then {
        _best = _x;
        _bestAt = _at;
    };
} forEach _usable;

[_player, _weapon, _muzzle, _best] call EFUNC(storage,loadMagazine)
