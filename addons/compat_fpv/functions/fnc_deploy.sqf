#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * On the machine of the unit that dropped an item of Ukraine FPV Drone: the drone is deployed by the mod's own function,
 * UA_fnc_fpv_createUavOnItemCheck, which takes a plain GroundWeaponHolder with the item in it. A holder of that kind is made
 * here for the moment (local, at the spot where the item lay), so the drone is created as the mod does it - class by item
 * and side, its payload and spool, created and crewed on this machine.
 *
 * Arguments:
 * 0: Unit that dropped it <OBJECT>
 * 1: Position the item lay at (ATL) <ARRAY>
 * 2: Item class <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, getPosATL player, "UA_Item_EMPTY"] call aio_compat_fpv_fnc_deploy;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_pos", [0, 0, 0], [[]]], ["_class", "", [""]]];

if (isNull _unit || {isNil "UA_fnc_fpv_createUavOnItemCheck"} || {_class isEqualTo ""}) exitWith {};

private _holder = createVehicleLocal ["GroundWeaponHolder", [0, 0, 0], [], 0, "CAN_COLLIDE"];

_holder setPosATL _pos;
_holder addMagazineCargo [_class, 1];

INFO_2("Deploying %1 for %2",_class,name _unit);

[_unit, _holder, _class] call UA_fnc_fpv_createUavOnItemCheck;

deleteVehicle _holder;
