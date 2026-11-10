#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a weapon reloads by its own script: its config has an event handler class with a "reload" entry
 * (RHS's shotguns: rhs_fnc_reloadShotgun loads shell by shell, puts the old magazine back by addMagazine and
 * keeps a fake magazine in a hidden muzzle), or a muzzle whose only magazines cannot be picked up (scope < 2,
 * mass 0 - RHS_ReloadAction's rhs_mag_fakeMuzzle1). Such a weapon's reload is left to the game and the weapon's
 * script entirely: the reload key is never taken (fnc_reloadGuard), a reload is never taken back
 * (fnc_onReloaded) and the magazine put away is never moved (fnc_reloadTidy) - any of these broke the script's
 * own bookkeeping, and the reload key did nothing after two reloads (Discord report, 0.7.2, RHS M590).
 * The answer is kept per class.
 *
 * Arguments:
 * 0: Weapon class <STRING>
 *
 * Return Value:
 * Reloads by its own script <BOOL>
 *
 * Example:
 * ["rhs_weap_M590_5RD"] call aio_storage_fnc_scriptedReload;
 *
 * Public: Yes
 */

params [["_weapon", "", [""]]];

if (_weapon isEqualTo "") exitWith {false};

if (isNil QGVAR(scriptedReloads)) then {
    GVAR(scriptedReloads) = createHashMap;
};

private _key = toLowerANSI _weapon;
private _known = GVAR(scriptedReloads) get _key;

if (!isNil "_known") exitWith {_known};

private _config = configFile >> "CfgWeapons" >> _weapon;
private _scripted = false;

// Event handlers of the weapon itself: a class of them, or the entries directly.
private _handlers = _config >> "EventHandlers";

if (isClass _handlers) then {
    if ((getText (_handlers >> "reload")) isNotEqualTo "") then {_scripted = true};

    {
        if (isClass _x && {(getText (_x >> "reload")) isNotEqualTo ""}) exitWith {_scripted = true};
    } forEach (configProperties [_handlers, "isClass _x", true]);
};

// A muzzle that holds nothing but a fake magazine.
if (!_scripted) then {
    {
        if (_x isEqualTo "this") then {continue};

        private _mags = getArray (_config >> _x >> "magazines");

        if (_mags isNotEqualTo [] && {_mags findIf {
            private _mag = configFile >> "CfgMagazines" >> _x;
            getNumber (_mag >> "scope") >= 2 && {getNumber (_mag >> "mass") > 0}
        } < 0}) exitWith {_scripted = true};
    } forEach getArray (_config >> "muzzles");
};

GVAR(scriptedReloads) set [_key, _scripted];

_scripted
