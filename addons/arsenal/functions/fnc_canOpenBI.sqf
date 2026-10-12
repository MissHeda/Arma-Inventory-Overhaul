#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit may open the vanilla box from the inventory: the checks of the vanilla scroll action - the
 * box lives, the unit is near it and on foot - and the condition the mission put on it (the one
 * BIS_fnc_arsenal "AmmoboxInit" stored on the box). Without that last one a role-locked arsenal would open
 * for everyone from the inventory's menu.
 *
 * The condition is called the way the action calls it: the box is _target, the unit is _this.
 *
 * Arguments:
 * 0: Box <OBJECT>
 * 1: Unit <OBJECT>
 *
 * Return Value:
 * May open it <BOOL>
 *
 * Example:
 * [_box, player] call einv_arsenal_fnc_canOpenBI;
 *
 * Public: No
 */

params [["_box", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _box || {isNull _unit} || {!alive _box} || {_unit distance _box >= 5} || {(vehicle _unit) isNotEqualTo _unit}) exitWith {false};

private _condition = _box getVariable ["bis_fnc_arsenal_condition", {true}];

if !(_condition isEqualType {}) exitWith {true};

private _target = _box;
private _allowed = _unit call _condition;

_allowed isEqualTo true
