#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the soldier's three containers and the staging space hold now, in the terms of the stock the panel lies on
 * (GVAR(pool), fnc_registerPool). Taken before the panel adds or takes something; fnc_poolSettle takes it again
 * afterwards and has the stock follow the difference. Moves between the containers and the staging space change
 * nothing, as both are counted.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The census, or nil without a stock <ANY>
 *
 * Example:
 * private _census = call aio_arsenal_fnc_poolCensus;
 *
 * Public: No
 */

if (count GVAR(pool) == 0) exitWith {nil};

private _center = call FUNC(center);

if (isNull _center) exitWith {nil};

private _containers = [uniformContainer _center, vestContainer _center, backpackContainer _center, GVAR(staging)] select {!isNull _x};

[_containers] call (GVAR(pool) get "census")
