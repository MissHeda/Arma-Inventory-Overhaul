#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How much a unit carries, in config mass, counted the way ACE counts it: what the engine weighs
 * (loadAbs) plus ACE movement's virtual load on the unit and on its uniform, vest and backpack. That is
 * the number ACE's fatigue tires the unit by, and it holds the weight overrides of the rules
 * (fnc_updateVirtualLoad) and what Enhanced First Aid Kits' kits hold, which no cargo command sees.
 *
 * The tiers are measured against this (fnc_getTier), and the window's weight card shows it.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Load, in tenths of a pound like config mass - 0 for no unit <NUMBER>
 *
 * Example:
 * [player] call einv_weight_fnc_getLoad;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {0};

private _load = loadAbs _unit;

{
    _load = _load + (_x getVariable [QACEGVAR(movement,vLoad), 0]);
} forEach [_unit, uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

_load
