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

if (isNull _unit) exitWith {};

private _on = (missionNamespace getVariable [QGVAR(enabled), true]) && {missionNamespace getVariable [QGVAR(effects), true]};
private _noSprint = _on && {_tier >= TIER_OVERLOADED};
private _walk = _on && {_tier >= TIER_CRITICAL};

// Without ACE, the engine's own switches - set only when this changes them, so a mission's or another mod's stay alone.
if (isNil QACEFUNC(common,statusEffect_set)) exitWith {
    (_unit getVariable [QGVAR(effectsSet), [false, false]]) params ["_hadNoSprint", "_hadWalk"];

    if (_noSprint isNotEqualTo _hadNoSprint) then {
        _unit allowSprint !_noSprint;
    };

    if (_walk isNotEqualTo _hadWalk) then {
        _unit forceWalk _walk;
    };

    _unit setVariable [QGVAR(effectsSet), [_noSprint, _walk]];
};

[_unit, "blockSprint", QUOTE(ADDON), _noSprint] call ACEFUNC(common,statusEffect_set);
[_unit, "forceWalk", QUOTE(ADDON), _walk] call ACEFUNC(common,statusEffect_set);
