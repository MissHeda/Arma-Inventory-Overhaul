#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which tier a load is in for a unit: Light, Heavy, Overloaded or Critical (TIER_*), by the limits of
 * fnc_getLimits. Nothing is ever refused because of the tier; it only decides what the bar shows and what
 * ACE does to the soldier (fnc_updateTier).
 *
 * With the tiers switched off (aio_weight_enabled) every load is Light: the window's bar keeps one colour
 * and the soldier gets nothing of ours, with no caller having to ask about the switch itself.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Load to test, config mass - -1 for the unit's own (fnc_getLoad), to ask what a pick-up would make of it
 *    <NUMBER> (default: -1)
 *
 * Return Value:
 * TIER_LIGHT, TIER_HEAVY, TIER_OVERLOADED or TIER_CRITICAL <NUMBER>
 *
 * Example:
 * [player] call aio_weight_fnc_getTier;
 * [player, 600] call aio_weight_fnc_getTier;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]], ["_load", -1, [0]]];

private _limits = [_unit] call FUNC(getLimits);

if !(_limits get "enabled") exitWith {TIER_LIGHT};

if (_load < 0) then {
    _load = [_unit] call FUNC(getLoad);
};

if (_load >= _limits get "critical") exitWith {TIER_CRITICAL};
if (_load >= _limits get "overloaded") exitWith {TIER_OVERLOADED};
if (_load >= _limits get "heavy") exitWith {TIER_HEAVY};

TIER_LIGHT
