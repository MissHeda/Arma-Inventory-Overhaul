#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts what a tier does onto a unit, through ACE: no sprinting from Overloaded on (ACE's status effect
 * "blockSprint") and walking only at Critical ("forceWalk"), each under the reason aio_weight. ACE's
 * status effects add up with every other reason and ACE sends them to the other machines itself; setting a
 * reason again that is set already changes nothing. Nothing is done with the animation speed - ACE's fatigue
 * takes that over once a second and would fight us.
 *
 * With aio_weight_effects or the tiers as a whole (aio_weight_enabled) off none of it is set and what was
 * is taken off again.
 *
 * Arguments:
 * 0: Unit - local <OBJECT>
 * 1: Tier, TIER_* <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, TIER_OVERLOADED] call aio_weight_fnc_applyEffects;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_tier", TIER_LIGHT, [0]]];

if (isNull _unit || {isNil QACEFUNC(common,statusEffect_set)}) exitWith {};

private _on = (missionNamespace getVariable [QGVAR(enabled), true]) && {missionNamespace getVariable [QGVAR(effects), true]};

[_unit, "blockSprint", QUOTE(ADDON), _on && {_tier >= TIER_OVERLOADED}] call ACEFUNC(common,statusEffect_set);
[_unit, "forceWalk", QUOTE(ADDON), _on && {_tier >= TIER_CRITICAL}] call ACEFUNC(common,statusEffect_set);
