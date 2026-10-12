#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the inventory handler onto a unit the player now controls.
 *
 * A plain event handler rather than a CBA class event handler: only the unit's own handler can
 * answer the engine with true and so keep the vanilla inventory from opening. Once per unit - it
 * stays on a unit the player leaves, where fnc_onInventoryOpened lets everything through.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call einv_gui_fnc_initUnit;
 *
 * Public: No
 */

params ["_unit"];

if (isNull _unit || {(_unit getVariable [QGVAR(inventoryHandler), -1]) >= 0}) exitWith {};

private _id = _unit addEventHandler ["InventoryOpened", {_this call FUNC(onInventoryOpened)}];
_unit setVariable [QGVAR(inventoryHandler), _id];
