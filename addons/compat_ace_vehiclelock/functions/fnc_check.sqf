#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * ACE's vehicle lock as one of our locks (aio_locks_fnc_addProvider): exactly the rule ACE applies to the
 * vanilla inventory (ace_vehiclelock_fnc_onOpenInventory) - only while ACE locks vehicle inventories at all
 * (ace_vehiclelock_lockVehicleInventory), for someone on foot, a locked car, tank or helicopter (locked 2
 * or 3), and no key. The key test is ACE's own (master key, side key, custom keys).
 *
 * Every input is global, so the window, the engine's inventory gate and the guard on every op get the same
 * answer on whichever machine they ask. A container opened from inside such a vehicle is caught as well:
 * the locks asks about the container at the top of the chain.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container at the top of the chain <OBJECT>
 *
 * Return Value:
 * Why not, "" when the unit may <STRING>
 *
 * Example:
 * [player, _vehicle] call aio_compat_ace_vehiclelock_fnc_check;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_container", objNull, [objNull]]];

if (
    isNull _unit
    || {isNull _container}
    || {!(missionNamespace getVariable [QACEGVAR(vehiclelock,LockVehicleInventory), false])}
    || {!isNull objectParent _unit}
    || {!(_container isKindOf "Car" || {_container isKindOf "Tank"} || {_container isKindOf "Helicopter"})}
    || {!((locked _container) in [2, 3])}
    || {[_unit, _container] call ACEFUNC(vehiclelock,hasKeyForVehicle)}
) exitWith {""};

LLSTRING(NoKey)
