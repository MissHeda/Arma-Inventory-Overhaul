#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Works out the load tier of a local unit and makes it count: the duty factor ACE's fatigue multiplies the
 * cost of every movement by - 1 up to Overloaded, then climbing to OVERLOAD_DUTY_MAX at Critical - and, when
 * the tier (or aio_weight_effects) changed since last time, the status effects (fnc_applyEffects), the
 * local CBA event aio_weight_tierChanged [unit, tier, old tier] and a one-line message while the
 * inventory is closed (fnc_notifyTier). The first look after a unit changed raises the event but says
 * nothing.
 *
 * With the tiers switched off (aio_weight_enabled) the tier is always Light (fnc_getTier): the duty factor
 * goes back to 1, the status effects come off on the next look and nothing is said - the switch is not a
 * change of load the player would want to hear about.
 *
 * Also keeps ACE's own number honest: ACE refreshes its total load (which its fatigue uses) on loadout
 * events and its own virtual loads only, so what is packed into a container lying in the backpack was
 * missing from it. When it differs from the load counted here, ACE is told to count again.
 *
 * Only runs where the unit is local: the duty factor is read from the unit by ACE's loop on the player's
 * machine, and ACE's status effects are set by the owner.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [ACE_player] call aio_weight_fnc_updateTier;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!local _unit} || {!hasInterface}) exitWith {};

private _load = [_unit] call FUNC(getLoad);

// ACE's total load for its fatigue.
if (!isNil QACEFUNC(movement,handleVirtualMass) && {abs (_load - (_unit getVariable [QACEGVAR(movement,totalLoad), _load])) > 1}) then {
    [_unit] call ACEFUNC(movement,handleVirtualMass);
};

private _limits = [_unit] call FUNC(getLimits);
private _tier = [_unit, _load] call FUNC(getTier);
private _enabled = _limits get "enabled";
private _effects = _enabled && {missionNamespace getVariable [QGVAR(effects), true]};

// The duty factor: ACE's loop asks for it every second (XEH_postInit).
private _duty = 1;

if (_effects && {_tier >= TIER_OVERLOADED}) then {
    _duty = linearConversion [_limits get "overloaded", _limits get "critical", _load, 1, OVERLOAD_DUTY_MAX, true];
};

_unit setVariable [QGVAR(duty), _duty];

private _old = _unit getVariable [QGVAR(tier), -1];
private _appliedWith = _unit getVariable [QGVAR(effectsOn), -1];
private _effectsNow = [0, 1] select _effects;

if (_old == _tier && {_appliedWith == _effectsNow}) exitWith {};

[_unit, _tier] call FUNC(applyEffects);

_unit setVariable [QGVAR(tier), _tier];
_unit setVariable [QGVAR(effectsOn), _effectsNow];

if (_old != _tier) then {
    [QGVAR(tierChanged), [_unit, _tier, _old]] call CBA_fnc_localEvent;

    if (_old >= 0 && {_enabled}) then {
        [_tier, _old, _limits] call FUNC(notifyTier);
    };
};
