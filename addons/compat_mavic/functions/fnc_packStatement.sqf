#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Statement of ACE interaction > Pack up drone: the mod's own function packs the drone up
 * (Mavic_fnc_addUavToInventory: grenades, terminal, crew, and the item by the engine's addMagazine - which
 * fails quietly when the engine thinks the containers are full - before it deletes the drone either way). The
 * item is counted before and after, over the containers the unit wears: when it did not arrive it is put into
 * the first container with a free spot, with the charge the drone had, else on the ground beside the unit, so
 * the item is never lost. Runs on the machine of the unit that interacts; the deletion is global.
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_drone, player] call aio_compat_mavic_fnc_packStatement;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _uav || {isNull _player} || {isNil "Mavic_fnc_addUavToInventory"}) exitWith {};

private _class = [_uav] call FUNC(itemFor);
private _rounds = round ((fuel _uav) * 100);
private _count = {
    private _held = 0;

    {_held = _held + ([_x, _class] call EFUNC(storage,countClass))} forEach ([uniformContainer _player, vestContainer _player, backpackContainer _player] select {!isNull _x});

    _held
};
private _before = call _count;

[_uav, _player] call Mavic_fnc_addUavToInventory;

if ((call _count) > _before) exitWith {};

private _entry = createHashMapFromArray [
    ["class", _class], ["count", 1], ["ammo", _rounds], ["capacity", 100], ["attachments", []], ["container", objNull]
];
private _to = [uniformContainer _player, vestContainer _player, backpackContainer _player] select {
    !isNull _x && {[_x, _entry] call EFUNC(storage,hasSpace)}
};

if (_to isNotEqualTo []) then {
    (_to select 0) addMagazineAmmoCargo [_class, 1, _rounds];
} else {
    private _holder = createVehicle ["GroundWeaponHolder", _player modelToWorld [0, 1, 0.025], [], 0, "CAN_COLLIDE"];

    _holder addMagazineAmmoCargo [_class, 1, _rounds];
};

INFO_2("Packed %1 for %2 by hand, the engine did not take it",_class,name _player);
