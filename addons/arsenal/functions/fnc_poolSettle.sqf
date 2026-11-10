#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * After the panel added or took something on an arsenal with a stock (GVAR(pool)): the census again, and the stock
 * follows the difference to the one taken before (fnc_poolCensus) - what came in is taken from it, what went out is
 * given back.
 *
 * Arguments:
 * 0: The census before <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_census] call aio_arsenal_fnc_poolSettle;
 *
 * Public: No
 */

params [["_before", nil]];

if (count GVAR(pool) == 0 || {isNil "_before"}) exitWith {};

private _after = call FUNC(poolCensus);

if (isNil "_after") exitWith {};

[_before, _after] call (GVAR(pool) get "settle");
