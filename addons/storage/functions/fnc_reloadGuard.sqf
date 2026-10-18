#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keyboard's reload key (the game's "Reload" action) honours the "Use items from ..." settings, and loads
 * a weapon whose muzzle is empty. The engine decides which magazine it loads and takes it from any container;
 * a mod cannot tell it otherwise, so this stands in front of the key and does the reload itself when
 *
 *   - a magazine that would do lies in a container it cannot be used from (the settings):
 *       - none of the magazines the weapon takes lies where it can be used: the key does nothing, and a line
 *         says from where to take one out
 *       - some do: the key loads the fullest of those (fnc_loadMagazine: the game's own reload action, or by
 *         hand into an empty weapon), so the magazine never comes from a blocked container
 *   - the weapon's muzzle holds no magazine at all (a magazine dragged out of its slot in the window, a
 *     script, a loadout) while a limit is active: the key loads the fullest magazine that may be used by hand
 *     (fnc_loadMagazine) - after unloading by drag and drop the game's own key was seen
 *     doing nothing for such a weapon. If nothing could be loaded the key is the game's.
 *
 * No magazine that would do lies in a blocked container, or nothing is limited, or the weapon is full: the key
 * is left to the game, untouched.
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

if (_shift || {_ctrl} || {_alt}) exitWith {false};

// Plain keys only: a code with modifiers built in is a combination the event reports separately.
if !(_key in (actionKeys "ReloadMagazine")) exitWith {false};

private _unit = missionNamespace getVariable ["ACE_player", player];

if (isNull _unit || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};

private _weapon = currentWeapon _unit;

if (_weapon isEqualTo "" || {(([primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit]) find _weapon) < 0}) exitWith {false};

// Nothing in the muzzle: the weapon was emptied (fnc_takeOff), so the key loads it itself, limits or not.
private _loadedClass = currentMagazine _unit;
private _empty = _loadedClass isEqualTo "";

// A reload already under way takes the magazine out of the muzzle for a while: that muzzle is not empty (the
// weapon's state says how far the magazine's reload has got), and the game's own key is left alone.
if (_empty && {([] call FUNC(reloadBusy)) || {((weaponState _unit) param [6, 0]) > 0}}) exitWith {false};

// Without limits the key is the game's, whatever the weapon holds: reloading is vanilla then, untouched.
if !(missionNamespace getVariable [QGVAR(useActive), false]) exitWith {false};

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

// With limits active the magazine is always the one fnc_reloadPick chooses below, never the game's own pick,
// which would take it from a blocked container although a usable one lies elsewhere.

// A full magazine in the weapon: the game does nothing, and so does this.
if (!_empty && {(_unit ammo _muzzle) >= getNumber (configFile >> "CfgMagazines" >> _loadedClass >> "count")}) exitWith {false};

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

// The fullest one that may be used (fnc_reloadPick), loaded the way every reload of this mod is
// (fnc_loadMagazine): with the game's action when the weapon holds a magazine, put in by hand when its
// muzzle is empty - the action alone did nothing there, so an empty weapon stayed empty although magazines
// that may be used lay in the vest.
private _best = [_unit, _weapon, _muzzle] call FUNC(reloadPick);

if (_best isEqualTo []) exitWith {
    // Nothing to load the weapon with (not for an empty one: the game's key may still know better).
    GVAR(reloadAt) = 0;

    false
};

// Another reload is still under way (ACE's flag, believed for a few seconds at most).
if ([] call FUNC(reloadBusy)) exitWith {true};

if !([_unit, _weapon, _muzzle, _best] call FUNC(loadMagazine)) exitWith {
    // Not loaded: the key is the game's, and the next press is not held back.
    GVAR(reloadAt) = 0;

    false
};

true
