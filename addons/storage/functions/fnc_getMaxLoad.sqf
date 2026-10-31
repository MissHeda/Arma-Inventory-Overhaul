#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How much a container's config says it can hold, in config mass. This is a sizing heuristic only, never a
 * limit: it is what a container's default grid is worked out from when nobody defined one ("auto",
 * "percent" and "pattern" in the rules - fnc_getBlocks, fnc_blocksFor). Once the grid is there, free cells
 * are the only thing that decides what fits; nothing is refused because of weight.
 *
 * A uniform's or vest's container object is its Supply class, which carries the uniform's or vest's
 * load; a backpack's container is the backpack itself. Either way the number sits on the object's own
 * config.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * Maximum load from the config, -1 for the ground, which has no config load <NUMBER>
 *
 * Example:
 * [uniformContainer player] call einv_storage_fnc_getMaxLoad;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {[_container] call FUNC(isGroundHolder)}) exitWith {-1};

getNumber (configOf _container >> "maximumLoad")
