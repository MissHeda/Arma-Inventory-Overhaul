#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the inventory handler onto a unit the player now controls.
 *
 * A plain event handler rather than a CBA class event handler: only the unit's own handler can
 * answer the engine with true and so keep the vanilla inventory from opening. Once per unit - it
 * stays on a unit the player leaves, where fnc_onInventoryOpened lets everything through.
 *
 * Every answer of true starts a short grace time (BLOCK_GRACE) in which a vanilla inventory that
 * loads anyway is closed again (fnc_guardVanilla); an answer of false ends it, the vanilla inventory
 * was asked for.
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

// How long after an answer of true a vanilla inventory that still loads is closed again, in seconds
// (fnc_guardVanilla). The window opens a frame later; once it is open the guard needs no time.
#define BLOCK_GRACE 1.5

params ["_unit"];

if (isNull _unit || {(_unit getVariable [QGVAR(inventoryHandler), -1]) >= 0}) exitWith {};

private _id = _unit addEventHandler ["InventoryOpened", {
    private _blocked = _this call FUNC(onInventoryOpened);

    GVAR(blockedUntil) = [-1, diag_tickTime + BLOCK_GRACE] select (_blocked isEqualTo true);

    _blocked
}];
_unit setVariable [QGVAR(inventoryHandler), _id];
