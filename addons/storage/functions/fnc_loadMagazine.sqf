#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Loads one chosen magazine of the unit into a weapon's muzzle - the one way every reload of this mod ends
 * (the reload key's guard, the undo of a refused reload, the hotbar, other mods' menus that load a
 * magazine). The caller chooses the magazine among those the "Use items from ..." settings leave open; this
 * only loads it:
 *
 *   - the muzzle holds a magazine: the game's own reload action with its animation, which swaps the two
 *     (the old magazine goes back into the unit's gear)
 *   - the muzzle is EMPTY: the magazine is taken out of the container it lies in (counted before and after)
 *     and put into the muzzle with addWeaponItem (fnc_weaponPart, which tries three forms of the command and
 *     looks at the weapon after each), the weapon's reload gesture and sound play as the window plays them,
 *     and a magazine that did not go in is put back into its container. Only if that fails too the game's
 *     reload action is tried. The action alone did nothing for a weapon with no magazine in it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon - a rifle, pistol or launcher the unit carries <STRING>
 * 2: Muzzle <STRING>
 * 3: The magazine, an entry of magazinesAmmoFull: [class, rounds, loaded, type, location, id, creator] <ARRAY>
 *
 * Return Value:
 * Whether the magazine is loaded or on its way (the action runs for seconds) <BOOL>
 *
 * Example:
 * [player, primaryWeapon player, primaryWeapon player, _entry] call einv_storage_fnc_loadMagazine;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_muzzle", "", [""]],
    ["_entry", [], [[]]]
];

_entry params [["_class", "", [""]], ["_rounds", 0, [0]]];

private _which = [primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon;

if (isNull _unit || {!alive _unit} || {_which < 0} || {_class isEqualTo ""} || {_rounds <= 0}) exitWith {false};

// The reload action wants the magazine by its id and its creator, which the entry carries behind the rounds.
private _fnc_action = {
    if (count _entry < 7) exitWith {false};

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

// A muzzle that holds a magazine: the game swaps them, with its animation.
if ((call _fnc_loaded) isNotEqualTo []) exitWith {call _fnc_action};

// An empty muzzle. The container the magazine lies in: the location the game gave, else the one container
// that holds a magazine of this class and these rounds.
private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

private _fnc_count = {
    params [["_container", objNull, [objNull]]];

    if (isNull _container) exitWith {0};

    {(_x select 0) == _class && {(_x select 1) == _rounds}} count (magazinesAmmoCargo _container)
};

private _at = USE_KINDS find (toLowerANSI format ["%1", _entry param [4, ""]]);

if (_at < 0 || {([_containers select _at] call _fnc_count) < 1}) then {
    _at = _containers findIf {([_x] call _fnc_count) > 0};
};

if (_at < 0) exitWith {call _fnc_action};

private _box = _containers select _at;
private _before = [_box] call _fnc_count;

_box addMagazineAmmoCargo [_class, -1, _rounds];

// The container did not let it go: nothing has changed, the game's own reload is left to try.
if (([_box] call _fnc_count) >= _before) exitWith {call _fnc_action};

[_unit, ["primary", "handgun", "launcher"] select _which, true, _class, _rounds, _second] call FUNC(weaponPart);

if ((call _fnc_loaded) isEqualTo []) exitWith {
    // It did not go in: back where it lay.
    _box addMagazineAmmoCargo [_class, 1, _rounds];

    call _fnc_action
};

// The window's reload gesture and sound (einv_gui, when it is loaded), then the notes that follow any change
// of the gear: where the magazines lie, and what the grid has no room for.
if (!isNil QEFUNC(gui,playReload)) then {
    [_unit, format ["%1_%2", ["primary", "handgun", "launcher"] select _which, ["mag", "mag2"] select _second]] call EFUNC(gui,playReload);
};

[_unit] call FUNC(queueMigrate);
[_unit] call FUNC(useTrack);

true
