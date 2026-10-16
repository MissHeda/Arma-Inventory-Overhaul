#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player's unit reloaded - by the scroll menu's entry, a gamepad button, a script or anything else the
 * reload key's guard (fnc_reloadGuard) does not stand in front of. The game has loaded a magazine; if that
 * one came out of a container the "Use items from ..." settings close to it (noted beforehand,
 * fnc_useTrack) and is not whitelisted for it, the reload is undone a frame later (fnc_reloadUndo).
 * Everything else is left alone: a magazine from a container that allows it, one whose origin is not
 * known, a reload of another unit, from a vehicle's gun, or of a weapon the unit does not carry.
 *
 * A handler of the "Reloaded" event of CAManBase (XEH_postInit); it runs where the unit is local.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 * 3: New magazine, [class, rounds, ...] <ARRAY>
 * 4: Old magazine, [] when nothing was loaded <ARRAY>
 *
 * Return Value:
 * Whether it is being undone <BOOL>
 *
 * Example:
 * [player, "arifle_MX_F", "arifle_MX_F", ["30Rnd_65x39_caseless_mag", 30, 1, 0], []] call einv_storage_fnc_onReloaded;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_weapon", "", [""]],
    ["_muzzle", "", [""]],
    ["_new", [], [[]]],
    ["_old", [], [[]]]
];

if (!(missionNamespace getVariable [QGVAR(useActive), false]) || {GVAR(undoBusy)}) exitWith {false};

if (isNull _unit || {!local _unit} || {_unit isNotEqualTo (missionNamespace getVariable ["ACE_player", player])}) exitWith {false};

if (!alive _unit || {!isNull objectParent _unit} || {([primaryWeapon _unit, handgunWeapon _unit, secondaryWeapon _unit] find _weapon) < 0}) exitWith {false};

_new params [["_class", "", [""]], ["_rounds", 0, [0]]];

if (_class isEqualTo "" || {_rounds <= 0}) exitWith {false};

// The magazine that is in the weapon now. The event does not say which one it was by id, so the loaded
// magazine of this class and these rounds is looked for; more than one (the same magazine in two weapons)
// is not told apart, and the game's reload stands.
private _loaded = (magazinesAmmoFull _unit) select {
    count _x >= 7 && {_x select 2} && {(_x select 0) == _class} && {(_x select 1) == _rounds}
};

if (count _loaded != 1) exitWith {false};

private _kind = GVAR(useIds) getOrDefault [format ["%1:%2", (_loaded select 0) select 6, (_loaded select 0) select 5], ""];

if (_kind isEqualTo "" || {([_class, _kind] call FUNC(useState)) isNotEqualTo "blocked"}) exitWith {false};

// A frame later: the game is still putting the old magazine away.
[FUNC(reloadUndo), [_unit, _weapon, _muzzle, [_class, _rounds], _old, _kind]] call CBA_fnc_execNextFrame;

true
