#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes what a unit carries weigh what the rules say, through ACE's virtual load - so a weight
 * override ("weight=" in einv_items_rules) counts in ACE's weight and in its fatigue, not only in the
 * numbers the inventory window shows. The engine itself keeps weighing every item by its config.
 *
 * The load goes on the unit itself, never on the uniform, vest or backpack. ACE only ever uses the
 * sum of the four, and a container that is dropped, handed over or put in a crate would otherwise
 * walk off with our share still on it. Enhanced First Aid Kits does the same for its kits, with a
 * variable of its own - ACE adds both up.
 *
 * Works on the difference: remembers what it has applied (einv_weight_appliedLoad on the unit), works
 * out the new total (fnc_getExtraLoad) and hands ACE only the change, so a new setup or a dropped item
 * takes off exactly what was added for it.
 *
 * Only runs where the unit is local - ACE turns the load into a unit trait, and those can only be set
 * by the machine that owns the unit.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call einv_weight_fnc_updateVirtualLoad;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!local _unit} || {!hasInterface}) exitWith {};

// ACE movement is where virtual load lives. Without it there is nothing to add to.
if (isNil QACEFUNC(movement,addLoadToUnitContainer)) exitWith {};

private _target = [_unit] call FUNC(getExtraLoad);

// Overrides that make things lighter take load off - but ACE's whole virtual load, not only our share,
// must stay above two limits. Its total load (what the unit carries plus the virtual load, which ACE
// shows and its fatigue uses) must not drop below zero, and neither must its load coefficient, which
// is scaled by 1 + virtual load / maxSoldierLoad. Whatever else is on the unit and its uniform, vest
// and backpack counts too, EFAK's share among it - so only our own share is taken out of the sum.
private _others = -(_unit getVariable [QGVAR(appliedLoad), 0]);

{
    _others = _others + (_x getVariable [QACEGVAR(movement,vLoad), 0]);
} forEach [_unit, uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

private _maxSoldierLoad = getNumber (configFile >> "CfgInventoryGlobalVariable" >> "maxSoldierLoad");

_target = _target max ((-((loadAbs _unit) min _maxSoldierLoad)) - _others);

private _applied = _unit getVariable [QGVAR(appliedLoad), 0];
private _delta = _target - _applied;

if (abs _delta < MIN_CHANGE) exitWith {};

if ([_unit, _unit, _delta] call ACEFUNC(movement,addLoadToUnitContainer)) then {
    // Public, so it travels with the unit to whoever takes it over next and gets cleaned up there.
    _unit setVariable [QGVAR(appliedLoad), _target, true];
};
