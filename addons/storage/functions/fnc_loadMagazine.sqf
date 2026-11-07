#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Loads one chosen magazine of the unit into a weapon's muzzle - the one way every reload of this mod ends
 * (the reload key's guard, the undo of a refused reload, the hotbar, other mods' menus that load a
 * magazine). The caller chooses the magazine among those the "Use items from ..." settings leave open; this
 * only loads it:
 *
 *   - the muzzle holds a magazine: the game's own reload action for exactly this magazine (by its id and
 *     creator), with its animation, which swaps the two (the old magazine goes back into the unit's gear).
 *     Before the action a one-shot note is written, GVAR(reloadToken): the first "Reloaded" event of the unit
 *     spends it (fnc_onReloaded) - when it shows this magazine loaded, the reload is not taken back, and the
 *     old magazine is moved once out of a container the settings close (fnc_reloadTidy). The note runs out
 *     after RELOAD_TOKEN_MAX seconds and is cleared when a magazine is taken out of a weapon (fnc_takeOff).
 *   - the muzzle is EMPTY (a spent launcher, a weapon whose magazine was taken out) or holds an empty
 *     magazine (a weapon fired dry): the game's reload as well. An empty muzzle is first given an empty
 *     magazine of the chosen class - what a weapon fired dry holds - since the game's action does nothing
 *     for a muzzle with no magazine at all. The game then reloads as it always does: its animation, the
 *     time it takes, a weapon that cannot fire until it is done, the empty magazine gone. Should the reload
 *     not start within RELOAD_START_WAIT, the magazine goes in by hand after all (below).
 *   - by hand (argument 4, the undo of a refused reload, which never starts a reload of the game's; and the
 *     fallback above): into an empty muzzle or over an empty magazine. The magazine is taken out of the
 *     container it lies in (counted before and after) and put into the muzzle with addWeaponItem
 *     (fnc_weaponPart, which tries three forms of the command and looks at the weapon after each), the
 *     weapon's reload gesture and sound play as the window plays them, and a magazine that did not go in is
 *     put back into its container. It is in at once, so the weapon fires while the gesture still plays -
 *     why the key no longer loads this way (Mia, 0.6.29: a launcher reloaded from a whitelisted backpack
 *     fired during its reload, again and again). A hand load is a noted one (fnc_noteHandLoad, from
 *     fnc_weaponPart): the reload undo leaves it alone.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon - a rifle, pistol or launcher the unit carries <STRING>
 * 2: Muzzle <STRING>
 * 3: The magazine, an entry of magazinesAmmoFull: [class, rounds, loaded, type, location, id, creator] <ARRAY>
 * 4: By hand - never the game's reload; a muzzle that holds a magazine with rounds is left as it is <BOOL> (default: false)
 *
 * Return Value:
 * Whether the magazine is loaded or on its way (the action runs for seconds) <BOOL>
 *
 * Example:
 * [player, primaryWeapon player, primaryWeapon player, _entry] call aio_storage_fnc_loadMagazine;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_muzzle", "", [""]],
    ["_entry", [], [[]]],
    ["_byHand", false, [false]]
];

_entry params [["_class", "", [""]], ["_rounds", 0, [0]]];

private _which = [primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon;

if (isNull _unit || {!alive _unit} || {_which < 0} || {_class isEqualTo ""} || {_rounds <= 0}) exitWith {false};

// The reload action wants the magazine by its id and its creator, which the entry carries behind the rounds.
// The token first, should the event come at once: [unit, weapon, "creator:id", class, rounds, the magazine the
// weapon had [class, rounds] or [], the container the new one lies in, how many magazines like the old one
// each container held before [uniform, vest, backpack], until when it stands].
private _fnc_action = {
    params [["_old", [], [[]]]];

    if (count _entry < 7) exitWith {false};

    private _id = format ["%1:%2", _entry select 6, _entry select 5];
    private _kind = toLowerANSI format ["%1", _entry select 4];

    if !(_kind in USE_KINDS) then {
        _kind = GVAR(useIds) getOrDefault [_id, ""];
    };

    private _counts = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit] apply {
        private _box = _x;

        if (isNull _box || {_old isEqualTo []}) then {0} else {
            {(_x select 0) == (_old select 0) && {(_x select 1) == (_old select 1)}} count (magazinesAmmoCargo _box)
        }
    };

    GVAR(reloadToken) = [_unit, toLowerANSI _weapon, _id, _class, _rounds, _old, _kind, _counts, diag_tickTime + RELOAD_TOKEN_MAX];

    _unit action ["LoadMagazine", vehicle _unit, _unit, _entry select 6, _entry select 5, _weapon, _muzzle];

    true
};

// The muzzle's magazine: [class, rounds], [] for none. The first muzzle's stands at 4 of weaponsItems, a
// second one's (a grenade launcher) at 5.
private _muzzles = getArray (configFile >> "CfgWeapons" >> _weapon >> "muzzles");
private _second = _muzzle isNotEqualTo _weapon && {_muzzle isNotEqualTo "this"} && {_muzzle isNotEqualTo (_muzzles param [0, "this"])};

private _fnc_loaded = {
    private _item = (weaponsItems _unit) select {(_x select 0) == _weapon};

    if (_item isEqualTo []) exitWith {[]};

    private _mag = (_item select 0) param [[4, 5] select _second, []];

    if (_mag isEqualType [] && {count _mag >= 2} && {(_mag select 0) isNotEqualTo ""}) then {
        [_mag select 0, _mag select 1]
    } else {
        []
    }
};

// A muzzle that holds a magazine with rounds left: the game swaps them, with its animation. The one it puts
// away may land in a container the settings close; the token lets fnc_onReloaded move it once, when the
// reload is done. By hand nothing is swapped: that is the game's reload, which a hand load never starts.
private _old = call _fnc_loaded;

if (_old isNotEqualTo [] && {(_old select 1) > 0}) exitWith {!_byHand && {[_old] call _fnc_action}};

private _base = ["primary", "handgun", "launcher"] select _which;

// An empty muzzle gets an empty magazine of the chosen class, as a weapon fired dry has: the game's action
// does nothing without one (Mia, 0.5.13), and a magazine put in by hand is in at once while only the gesture
// shows a reload. The empty one is no chosen magazine - the reload that follows is the token's, not a hand
// load. Should it not go in, the magazine goes in by hand below, as before.
if (!_byHand && {_old isEqualTo []} && {count _entry >= 7}) then {
    [_unit, _base, true, _class, 0, _second] call FUNC(weaponPart);
    [objNull] call FUNC(noteHandLoad);

    _old = call _fnc_loaded;
};

// The game's reload from the empty magazine. It is watched until it is under way (the magazine reload
// phase), done or overtaken (the token spent or written again by a later load), or the muzzle holds rounds.
// Nothing of that within RELOAD_START_WAIT - the game did not take the action, or dropped the empty magazine
// at once -: the magazine goes in by hand after all, for the weapon in the hands only, so a weapon put away
// is not loaded behind the player's back (the next press of the key tries again).
if (!_byHand && {_old isNotEqualTo []}) exitWith {
    if !([_old] call _fnc_action) exitWith {false};

    [{
        params ["_unit", "_weapon", "", "", "_slot", "_token"];

        private _mag = (((weaponsItems _unit) select {(_x select 0) == _weapon}) param [0, []]) param [_slot, []];

        GVAR(reloadToken) isNotEqualTo _token
        || {((weaponState _unit) param [6, 0]) > 0}
        || {_mag isEqualType [] && {count _mag >= 2} && {(_mag select 1) > 0}}
    }, {}, [_unit, _weapon, _muzzle, _entry, [4, 5] select _second, GVAR(reloadToken)], RELOAD_START_WAIT, {
        params ["_unit", "_weapon", "_muzzle", "_entry", "", "_token"];

        // Overtaken, or under way after all: the token stays for the event.
        if (GVAR(reloadToken) isNotEqualTo _token || {((weaponState _unit) param [6, 0]) > 0}) exitWith {};

        GVAR(reloadToken) = [];

        if (!alive _unit || {currentWeapon _unit isNotEqualTo _weapon}) exitWith {};

        WARNING_3("The game did not reload %1 into %2 within %3 s - loaded by hand.",_entry select 0,_weapon,RELOAD_START_WAIT);

        [_unit, _weapon, _muzzle, _entry, true] call FUNC(loadMagazine);
    }] call CBA_fnc_waitUntilAndExecute;

    true
};

// By hand. The container the magazine lies in: the location the game gave, else the one container that
// holds a magazine of this class and these rounds. Without the game's reload as the last try, by hand.
private _fnc_last = {
    if (_byHand) exitWith {false};

    [[]] call _fnc_action
};

private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

private _fnc_count = {
    params [["_container", objNull, [objNull]], ["_c", _class, [""]], ["_r", _rounds, [0]]];

    if (isNull _container) exitWith {0};

    {(_x select 0) == _c && {(_x select 1) == _r}} count (magazinesAmmoCargo _container)
};

private _at = USE_KINDS find (toLowerANSI format ["%1", _entry param [4, ""]]);

if (_at < 0 || {([_containers select _at] call _fnc_count) < 1}) then {
    _at = _containers findIf {([_x] call _fnc_count) > 0};
};

if (_at < 0) exitWith {call _fnc_last};

private _box = _containers select _at;
private _before = [_box] call _fnc_count;

_box addMagazineAmmoCargo [_class, -1, _rounds];

// The container did not let it go: nothing has changed.
if (([_box] call _fnc_count) >= _before) exitWith {call _fnc_last};

// An empty magazine in the muzzle is replaced. Should the game hand it to a container rather than drop it,
// it goes: the game's own reload never keeps one either.
private _empties = _containers apply {[_x, _old param [0, ""], 0] call _fnc_count};

[_unit, _base, true, _class, _rounds, _second] call FUNC(weaponPart);

private _now = call _fnc_loaded;

if !(_now isNotEqualTo [] && {(_now select 0) == _class} && {(_now select 1) > 0}) exitWith {
    // It did not go in: back where it lay.
    _box addMagazineAmmoCargo [_class, 1, _rounds];

    call _fnc_last
};

if (_old isNotEqualTo []) then {
    {
        if (([_x, _old select 0, 0] call _fnc_count) > (_empties select _forEachIndex)) then {
            _x addMagazineAmmoCargo [_old select 0, -1, 0];
        };
    } forEach _containers;
};

// The window's reload gesture and sound (aio_gui, when it is loaded), then the notes that follow any change
// of the gear: where the magazines lie, and what the grid has no room for.
if (!isNil QEFUNC(gui,playReload)) then {
    [_unit, format ["%1_%2", _base, ["mag", "mag2"] select _second]] call EFUNC(gui,playReload);
};

[_unit] call FUNC(queueMigrate);
[_unit] call FUNC(useTrack);

true
