#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * On the machine of the unit that dropped a Mavic 3 (Improved) item: the drone is deployed by the mod's own
 * function, Mavic_fnc_createMavicOnItemCheck, which takes a plain GroundWeaponHolder with the item in it. A
 * holder of that kind is made here for the moment (local, at the spot where the item lay), so the drone is
 * created as the mod does it - class by item and side, the charge from the magazine's rounds, created and
 * crewed on this machine.
 *
 * Arguments:
 * 0: Unit that dropped it <OBJECT>
 * 1: Position the item lay at (ATL) <ARRAY>
 * 2: Item class <STRING>
 * 3: Rounds (charge in percent) <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, getPosATL player, "Item_Mavic3", 100] call aio_compat_mavic_fnc_deploy;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_pos", [0, 0, 0], [[]]], ["_class", "", [""]], ["_rounds", 100, [0]]];

if (isNull _unit || {isNil "Mavic_fnc_createMavicOnItemCheck"} || {_class isEqualTo ""}) exitWith {};

private _holder = createVehicleLocal ["GroundWeaponHolder", [0, 0, 0], [], 0, "CAN_COLLIDE"];

_holder setPosATL _pos;

if (isClass (configFile >> "CfgMagazines" >> _class)) then {
    _holder addMagazineAmmoCargo [_class, 1, _rounds];
} else {
    _holder addItemCargo [_class, 1];
};

INFO_2("Deploying %1 for %2",_class,name _unit);

[_unit, _holder, _class] call Mavic_fnc_createMavicOnItemCheck;

deleteVehicle _holder;
