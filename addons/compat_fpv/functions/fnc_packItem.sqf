#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a deployed drone of Ukraine FPV Drone packs into, as the mod's own functions pick it, and the first container the
 * unit wears with a free spot for it in the grid (aio_storage_fnc_hasSpace).
 *
 * Arguments:
 * 0: Drone <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * Item class <STRING>, its rounds <NUMBER>, the container or objNull <OBJECT> <ARRAY>
 *
 * Example:
 * [_drone, player] call aio_compat_fpv_fnc_packItem;
 *
 * Public: No
 */

params [["_uav", objNull, [objNull]], ["_player", objNull, [objNull]]];

private _class = [[_uav] call UA_fnc_fpv_getPayloadType, _uav] call UA_fnc_fpv_getPayloadItem;
private _rounds = getNumber (configFile >> "CfgMagazines" >> _class >> "count");
private _entry = createHashMapFromArray [
    ["class", _class], ["count", 1], ["ammo", _rounds], ["capacity", _rounds], ["attachments", []], ["container", objNull]
];
private _room = [uniformContainer _player, vestContainer _player, backpackContainer _player] select {
    !isNull _x && {[_x, _entry] call EFUNC(storage,hasSpace)}
};

[_class, _rounds, _room param [0, objNull]]
