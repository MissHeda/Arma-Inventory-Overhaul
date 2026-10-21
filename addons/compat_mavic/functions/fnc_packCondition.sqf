#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Condition of ACE interaction > Pack up drone on a Mavic 3 (Improved) drone: the mod's own check
 * (Mavic_fnc_canDisassembly) without the engine's canAdd, which asks the config load - instead one of the
 * containers the unit wears has a free spot for the item (einv_storage_fnc_hasSpace).
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * Offered <BOOL>
 *
 * Example:
 * [_drone, player] call einv_compat_mavic_fnc_packCondition;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _uav || {!alive _uav} || {!alive _player} || {cameraOn != _player}) exitWith {false};
if (isEngineOn _uav || {abs (speed _uav) > 3}) exitWith {false};

private _entry = createHashMapFromArray [
    ["class", [_uav] call FUNC(itemFor)], ["count", 1], ["ammo", round ((fuel _uav) * 100)],
    ["capacity", 100], ["attachments", []], ["container", objNull]
];

[uniformContainer _player, vestContainer _player, backpackContainer _player] findIf {
    !isNull _x && {[_x, _entry] call EFUNC(storage,hasSpace)}
} >= 0
