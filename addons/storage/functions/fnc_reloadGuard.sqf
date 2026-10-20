#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keyboard's reload key (the game's "Reload" action) while a "Use items from ..." setting limits something.
 * The engine decides which magazine it loads and takes it from any container, and "Reloaded" cannot be
 * cancelled - so with limits active the key is this mod's alone, for a rifle, pistol or launcher in the hands
 * on foot, and the engine never reloads such a weapon by the key:
 *
 *   - a reload under way (the weapon's magazine reload phase, weaponState entry 6) or a key held down (one
 *     answer per RELOAD_GUARD_GAP): swallowed, nothing new starts
 *   - a full magazine in the weapon: swallowed, nothing happens - as in the game
 *   - the fullest magazine the weapon's muzzle takes that may be used (fnc_reloadPick): loaded with
 *     fnc_loadMagazine - the game's own reload action for that one magazine when the muzzle holds one (one
 *     animation; fnc_onReloaded tidies the magazine the game put away, once), by hand into an empty muzzle
 *   - none that may be used, but some in containers that are closed to them: nothing loads, and a line says
 *     from where to take one out
 *   - no magazine the muzzle takes at all: the key is the game's, which has nothing to load either
 *
 * Without limits (every setting on Everything) the key is never looked at: reloading is the game's.
 *
 * The plain key only - a vehicle's gun, a gamepad button and the action menu's entry are not caught here; a
 * reload by them that took a closed container's magazine is taken back afterwards (fnc_onReloaded). Called by
 * the one KeyDown handler of the main display (XEH_postInit), which swallows the key when this says so.
 * ACE's "is reloading" flag is not asked: ACE sets it in its own KeyDown handler for this very key press, so
 * it would take the press for a reload already under way.
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

// Without limits the key is the game's, whatever the weapon holds: reloading is vanilla then, untouched.
if !(missionNamespace getVariable [QGVAR(useActive), false]) exitWith {false};

// Plain keys only: a code with modifiers built in is a combination the event reports separately.
if (_shift || {_ctrl} || {_alt} || {!(_key in (actionKeys "ReloadMagazine"))}) exitWith {false};

private _unit = missionNamespace getVariable ["ACE_player", player];

if (isNull _unit || {!alive _unit} || {!isNull objectParent _unit}) exitWith {false};

private _weapon = currentWeapon _unit;

if (_weapon isEqualTo "" || {(([primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit]) find _weapon) < 0}) exitWith {false};

private _muzzle = currentMuzzle _unit;
private _compatible = (compatibleMagazines [_weapon, _muzzle]) apply {toLowerANSI _x};

// What the game could load: magazines with rounds in them that are not loaded and that this muzzle takes.
// None: the game has nothing to load either, and the key stays its own.
if ((magazinesAmmoFull _unit) findIf {!(_x select 2) && {(_x select 1) > 0} && {(toLowerANSI (_x select 0)) in _compatible}} < 0) exitWith {false};

// From here on the key is this mod's: the engine's own reload would take its pick from any container.

// A key held down repeats, and a reload under way (the hotbar's, AIME's, the last press's) runs its course.
if (diag_tickTime < (missionNamespace getVariable [QGVAR(reloadAt), 0]) || {((weaponState _unit) param [6, 0]) > 0}) exitWith {true};

// A full magazine in the weapon: nothing to do, as in the game.
private _loadedClass = currentMagazine _unit;

if (_loadedClass isNotEqualTo "" && {(_unit ammo _muzzle) >= getNumber (configFile >> "CfgMagazines" >> _loadedClass >> "count")}) exitWith {true};

GVAR(reloadAt) = diag_tickTime + RELOAD_GUARD_GAP;

private _best = [_unit, _weapon, _muzzle] call FUNC(reloadPick);

if (_best isEqualTo []) exitWith {
    // Only magazines that may not be used: from where to take one out.
    private _where = [];

    {
        if (!(_x select 2) && {(_x select 1) > 0} && {(toLowerANSI (_x select 0)) in _compatible}) then {
            {
                _where pushBackUnique _x;
            } forEach ([_unit, _x select 0] call FUNC(useBlockedIn));
        };
    } forEach (magazinesAmmoFull _unit);

    // Not found where they lie: every container a setting limits.
    if (_where isEqualTo []) then {
        _where = USE_KINDS select {([_x] call FUNC(useMode)) isNotEqualTo USE_ALL};
    };

    [format [localize "STR_einv_storage_Hint_NoReload", [USE_KINDS select {_x in _where}] call FUNC(useKindName)]] call FUNC(useHint);

    true
};

// Loaded the way every reload of this mod is (fnc_loadMagazine). Should that fail the press did nothing, and
// the next one is not held back - the game's own reload is not let in, it would take its own pick.
if !([_unit, _weapon, _muzzle, _best] call FUNC(loadMagazine)) then {
    GVAR(reloadAt) = 0;

    WARNING_3("Reload key: %1 could not be loaded into %2 (muzzle %3).",_best select 0,_weapon,_muzzle);
};

true
