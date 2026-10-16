#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keyboard's reload key (the game's "Reload" action) honours the "Use items from ..." settings. The
 * engine decides which magazine it loads and takes it from any container; a mod cannot tell it otherwise,
 * so this stands in front of the key and, only when a magazine that would do lies in a container it cannot
 * be used from, does the reload itself:
 *
 *   - none of the magazines the weapon takes lies where it can be used: the key does nothing, and a line
 *     says from where to take one out
 *   - some do: the key loads the fullest of those with the game's own reload action (the one the hotbar
 *     uses), so the magazine never comes from a blocked container
 *   - no magazine that would do lies in a blocked container, or nothing is limited, or the weapon is full:
 *     the key is left to the game, untouched
 *
 * On foot only, with a rifle, pistol or launcher in the hands, and only for the plain key - the reload from
 * a vehicle's gun is not caught, and a gamepad button or the action menu entry is taken back after the
 * fact (fnc_onReloaded). A handler of the main display's KeyDown event (XEH_postInit); its return value
 * true swallows the key.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Key code <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 *
 * Return Value:
 * Whether the key is swallowed <BOOL>
 *
 * Example:
 * [_display, 19, false, false, false] call einv_storage_fnc_reloadGuard;
 *
 * Public: No
 */

params ["", ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]]];

if (!(missionNamespace getVariable [QGVAR(useActive), false]) || {_shift} || {_ctrl} || {_alt}) exitWith {false};

// Plain keys only: a code with modifiers built in is a combination the event reports separately.
if !(_key in (actionKeys "ReloadMagazine")) exitWith {false};

private _unit = missionNamespace getVariable ["ACE_player", player];

if (isNull _unit || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};

private _weapon = currentWeapon _unit;

if (_weapon isEqualTo "" || {(([primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit]) find _weapon) < 0}) exitWith {false};

private _muzzle = currentMuzzle _unit;
private _compatible = (compatibleMagazines [_weapon, _muzzle]) apply {toLowerANSI _x};

// What the game would load: magazines with rounds in them that are not loaded and that this muzzle takes.
private _fnc_fit = {
    params ["_entry"];

    !(_entry select 2) && {(_entry select 1) > 0} && {(toLowerANSI (_entry select 0)) in _compatible}
};

private _all = magazinesAmmoFull _unit;
private _candidates = _all select {[_x] call _fnc_fit};

if (_candidates isEqualTo []) exitWith {false};

private _usable = (([_unit, [[], [], _all]] call FUNC(useCarried)) select 2) select {[_x] call _fnc_fit};

// Nothing that would do lies in a blocked container: the game's own reload.
if (count _usable == count _candidates) exitWith {false};

// A full magazine in the weapon: the game does nothing, and so does this.
private _loadedClass = currentMagazine _unit;

if (_loadedClass isNotEqualTo "" && {(_unit ammo _muzzle) >= getNumber (configFile >> "CfgMagazines" >> _loadedClass >> "count")}) exitWith {false};

// A key held down repeats; answered once.
if (diag_tickTime < (missionNamespace getVariable [QGVAR(reloadAt), 0])) exitWith {true};

GVAR(reloadAt) = diag_tickTime + RELOAD_GUARD_GAP;

if (_usable isEqualTo []) exitWith {
    // From where to take one out: the containers the magazines that would do lie blocked in.
    private _where = [];

    {
        private _class = _x;

        {
            _where pushBackUnique _x;
        } forEach ([_unit, _class] call FUNC(useBlockedIn));
    } forEach (_candidates apply {_x select 0});

    [format [localize "STR_einv_storage_Hint_NoReload", [USE_KINDS select {_x in _where}] call FUNC(useKindName)]] call FUNC(useHint);

    true
};

// The fullest one that may be used. The game's reload action wants the magazine by its id and its creator,
// which the list carries behind the rounds (seven entries) - without them the game is left to do it.
private _best = _usable select 0;

{
    if ((_x select 1) > (_best select 1)) then {
        _best = _x;
    };
} forEach _usable;

if (count _best < 7 || {missionNamespace getVariable ["ace_common_isReloading", false]}) exitWith {count _best >= 7};

_unit action ["LoadMagazine", _unit, _unit, _best select 6, _best select 5, _weapon, _muzzle];

true
