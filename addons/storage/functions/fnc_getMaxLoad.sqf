#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How much a container can hold, in config mass. Its compartments are sized from this (fnc_getBlocks).
 *
 * A uniform's or vest's container object is its Supply class, which carries the uniform's or vest's
 * load; a backpack's container is the backpack itself. Either way the number sits on the object's own
 * config.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Maximum load, -1 for no limit (the ground) <NUMBER>
 *
 * Example:
 * [uniformContainer player] call einv_storage_fnc_getMaxLoad;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {[_container] call FUNC(isGroundHolder)}) exitWith {-1};

getNumber (configOf _container >> "maximumLoad")
